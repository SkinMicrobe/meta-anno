# Tool Guide

Use this file when explaining what each tool does in the meta-annotation workflow, how the tools connect, what inputs/outputs they expect, and which failure modes are tool-specific.

## Tool Roles In The Workflow

| Tool | Role | Typical input | Typical output | Main risk |
| --- | --- | --- | --- | --- |
| `screen` | Keep long jobs alive after SSH disconnect and capture logs | Shell commands | Detached session and screen log | Losing track of sessions or logs |
| `conda` / `mamba` | Activate reproducible software environments | Environment name | Tool binaries on `PATH` | Wrong env gives wrong DIAMOND/RGI/eggNOG version |
| `diamond makedb` | Convert FASTA references into DIAMOND `.dmnd` databases | Reference protein FASTA | `.dmnd` database | Built with wrong FASTA or wrong output path |
| `diamond blastp` | Fast protein-vs-protein homology search | Query protein `.faa` and `.dmnd` database | BLAST outfmt 6 TSV | I/O bottleneck, low-specificity hits, only top hit retained |
| `emapper.py` | eggNOG mapper for orthology-based functional annotation | Query protein `.faa` | `*.emapper.annotations`, seed orthologs, logs | Database path/version mismatch, MMseqs memory/I/O pressure |
| `mmseqs` | Search backend used by eggNOG in large batch runs | Called by `emapper.py -m mmseqs` | Intermediate search results | High memory and database I/O |
| `prodigal` | Bacterial/prokaryotic ORF prediction from nucleotide FASTA | Contigs/MAG nucleotide `.fa/.fna/.fasta` | Protein `.faa`, CDS outputs if requested | Effectively single-threaded; many contigs require batching |
| `metaeuk` | Fungal gene prediction branch | Fungal/eukaryotic nucleotide FASTA | Predicted proteins and gene calls | Resource use and output layout depend on database/settings |
| `genomad` | Viral branch for viral sequence identification/annotation | Viral or virus-suspect nucleotide FASTA | geNomad result directories/tables | Database and temp I/O can be heavy |
| `rgi` | CARD Resistance Gene Identifier | Clean protein `.faa` or contig FASTA | `RGI.txt` and auxiliary files | DIAMOND version/env mismatch, interpreting nudged/loose hits incorrectly |
| `FungAMR` via DIAMOND | Fungi-branch virulence-factor annotation in this workflow | MetaEuk fungi protein `.faa` | FungAMR outfmt 6 TSV and derived CSV | Do not substitute bacterial VFDB; preserve/clean database headers before indexing when required |
| `sed` | Lightweight stream editing | FASTA text | Cleaned FASTA | Overbroad edits if pattern is wrong |
| `find` / `sort` / `wc` | Discover sample folders and count outputs | Directory tree | File/sample lists and counts | Counting partial outputs as completed |
| `ps` / `lsof` / `stat` | Runtime and lock ownership inspection | PID/path/lock file | Process and file metadata | Removing active locks by mistake |
| `top` / `htop` / `iostat` / `free` / `df` | Resource monitoring | Host runtime state | CPU/RAM/I/O/disk usage | Looking only at CPU while I/O is bottleneck |
| `nohup` | Keep simple monitor/helper jobs running after shell exits | Shell command | Background process and `nohup.out` | Logs go to default `nohup.out` unless redirected |
| `watch` | Interactive repeated command display | Shell command | Refreshing terminal output | Blocks scripts if placed inside batch code |

## Prediction Tool Routing

Use the user's corrected routing when nucleotide input needs an upstream prediction/classification branch:

```text
virus  -> genomad
bacteria/prokaryote -> prodigal
unclassified -> prodigal
fungi -> metaeuk
```

Do not route bacterial input to `genomad`. If the input is mixed or the biological target is unclear, keep `organism_type` and `prediction_tool` explicit and ask/verify rather than silently picking one tool.

If the input is contigs and the source is unclear, default to `organism_type=mixed` / mixed contigs. Do not infer bacterial/prokaryotic routing from the file name or path alone.

For mixed contigs with classification evidence, route unclassified contigs to `prodigal` but keep the bucket labeled as unclassified, such as `unclassified_prodigal`. This is not evidence that they are bacteria.

Do not substitute tools because one is missing. Missing `genomad`, `metaeuk`, or `prodigal` should trigger environment activation or installation in the user-confirmed environment; if that fails, report the branch as blocked rather than changing the route.

For contigs or other nucleotide FASTA input, split into smaller FASTA files before planning production runs. Size batches from actual input file sizes and monitor CPU, memory, and I/O during the run.

For virulence-factor routing:

```text
bacteria/prokaryote proteins -> VFDB
fungi proteins -> FungAMR
```

Do not send MetaEuk fungi proteins to the bacterial VFDB virulence branch. If FungAMR is unavailable, activate/prepare the requested FungAMR resource or report that branch as blocked rather than silently changing databases.

## Taxonomic Classifier Selection

For mixed or unclear contigs, expose the classifier as an explicit choice:

```text
taxonomy_classifier = existing | kraken2 | deepmicroclass | auto
```

- `Kraken2`: fast and useful for preliminary screening or when turnaround time is the priority, but it can make unreliable or overconfident taxonomic assignments. Treat its output as provisional and retain uncertainty/unclassified records.
- `DeepMicroClass` (`DMC`): slower, but preferred when higher classification accuracy is required and the runtime/resource cost is acceptable.
- Do not silently switch between `Kraken2` and `DeepMicroClass`. Use the user's selected classifier, reuse an existing valid result when present, and attempt installation in the confirmed conda environment if the selected tool is missing.
- Classification chooses the biological routing evidence; it does not replace the downstream branch tools: bacteria/archaea and unclassified use `prodigal`, fungi use `metaeuk`, and viruses use `genomad`.

## screen

Purpose:

- Run long annotation jobs safely over SSH.
- Keep jobs alive after terminal disconnect.
- Capture terminal output with `-L -Logfile`.

Pattern from this workflow:

```bash
screen -L -Logfile /mnt/cephfs/.../logs/eggnog_$(date +%F_%H%M).log -S eggnog
conda activate smag_eggNOG
cd /mnt/cephfs/.../workdir
bash ./run_eggnog_batch.sh
```

Use `screen` for main long-running annotation jobs. Use separate sessions for separate hosts or major batches. Record session name and logfile path.

Common checks:

```bash
screen -ls
tail -n 80 /path/to/screen.log
```

Common mistakes:

- Starting multiple sessions with similar names and losing which one owns which samples.
- Assuming screen log alone proves completion; still validate output files.

## conda / mamba

Purpose:

- Provide the correct versions of DIAMOND, eggNOG, RGI, MMseqs, Python libraries.

Environments observed in the notes:

- `smag`: DIAMOND/RGI and earlier annotation commands.
- `smag_eggNOG`: eggNOG mapper with newer DIAMOND/MMseqs.

Critical point:

- RGI and eggNOG may require different DIAMOND versions. Do not collapse them into one environment without testing.

Validation:

```bash
conda activate smag_eggNOG
which emapper.py
emapper.py --version
which diamond
diamond version 2>/dev/null || diamond help | head
which mmseqs
mmseqs version 2>/dev/null || true
```

For RGI:

```bash
conda activate smag
which rgi
rgi main --help | head
which diamond
diamond help | head
```

## DIAMOND

Purpose:

- Fast sequence similarity search, used here for CAZyme/VFDB annotation and as a possible eggNOG search backend.

Main commands:

```bash
diamond makedb --in reference.fa -d database_prefix
diamond blastp --db database.dmnd --query input.faa --out result.tsv --outfmt 6 --evalue 1e-5 --max-target-seqs 1 --threads 24
```

Inputs:

- Query: protein FASTA (`.faa`) for `blastp`.
- Database: `.dmnd` built from reference protein FASTA.

Outputs:

- Default outfmt 6 columns:

```text
qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore
```

Interpretation:

- `evalue` lower is stronger.
- `bitscore` higher is stronger.
- `pident` must be interpreted with `length`/coverage.
- With `--max-target-seqs 1`, only the top target is reported for each query.

Common failure modes:

- Database path points to the wrong `.dmnd`.
- Query path has a trailing space.
- Output is empty because no hits pass `--evalue`.
- Many jobs reading the same database overload Ceph/shared storage.

## eggNOG mapper / emapper.py

Purpose:

- Assign broad functional annotations by finding orthologs and transferring annotations from eggNOG.

Modes used:

```bash
emapper.py -i input.faa --data_dir db_dir -m diamond --no_annot ...
emapper.py --annotate_hits_table seed_orthologs --data_dir db_dir ...
emapper.py -i input.faa --data_dir db_copy --output_dir sample_dir --temp_dir temp_dir -m mmseqs --dbmem --cpu 16 -o eggNOG --override
```

Inputs:

- Protein FASTA (`.faa`, usually `sample.clean.faa`).
- eggNOG database directory.

Input-type rule:

- In this workflow, eggNOG/CARD/VFDB/FungAMR/CAZy/RGI annotation inputs must be protein FASTA (`.faa`).
- If the user provides nucleotide contigs/MAGs/assemblies, add the appropriate prediction/translation stage first and feed the resulting validated `.faa` into annotation.
- Do not plan production annotation directly from raw nucleotide FASTA.

Outputs:

- `eggNOG.emapper.annotations`: final functional annotation table.
- `*.emapper.seed_orthologs`: seed ortholog hits.
- `eggnog_run.log`: per-sample log in the user's batch scripts.
- Temporary MMseqs/DIAMOND files under `--temp_dir`.
- Derived CSV copies should be written after validation, while preserving the original annotation files.

Interpretation:

- Use `seed_ortholog`, `evalue`, and `score` as evidence.
- Use `Description`, `Preferred_name`, `COG_category`, `KEGG_*`, `GOs`, `EC`, `PFAMs` for biological summaries.
- Missing optional annotations are normal.

Common failure modes:

- `--data_dir` points to the wrong eggNOG database copy.
- eggNOG reports missing site-package `data/eggnog.db`, but the run may still be fine if `--data_dir` is correct.
- `--dbmem` and MMseqs can consume large RAM and heavy I/O.
- Shared `temp_dir` can collide or overload storage.
- Partial output can be mistaken for completion if scripts only check file existence.

## MMseqs2

Purpose:

- High-speed sequence search backend for eggNOG mapper.

In this workflow, MMseqs is usually not called directly. It is invoked through:

```bash
emapper.py ... -m mmseqs --dbmem ...
```

Operational notes:

- `--dbmem` loads database components into memory, trading RAM for speed.
- One MMseqs job was noted around `65G` in the user's records.
- Multiple MMseqs jobs can bottleneck on memory bandwidth or Ceph I/O.

Monitor:

```bash
ps -eo pid,ppid,stat,pcpu,pmem,etime,cmd | grep -Ei 'emapper|mmseqs' | grep -v grep
free -h
iostat -xz 5
```

## Annotation To CSV

Annotation CSVs are derived outputs for downstream analysis; they should not replace original tool outputs.

Preferred rules:

- Validate the annotation file first.
- Preserve original `*.emapper.annotations`, DIAMOND TSVs, and `RGI.txt`.
- For a result derived from one FASTA, include the source basename and annotation source in the CSV filename, such as `sample_001.eggnog.annotations.csv` or `sample_001.vfdb.csv`.
- Never label a single-input result as `all_annotations`, `combined_annotations`, `merged_annotations`, or another global result. Reserve aggregate naming for a validated merge across the explicitly declared full input scope.
- Use a structured parser such as Python `csv` or `pandas`.
- For eggNOG, keep one `#query` header and exclude comment rows before CSV conversion.
- Do not use blind `tr '\t' ','` conversion because descriptions and metadata can contain characters that need CSV quoting.

## RGI

Purpose:

- Detect antibiotic resistance genes using CARD models.

Pattern from this workflow:

```bash
sed 's/\*//g' input.faa > clean.faa
rgi main \
  --input_sequence clean.faa \
  --input_type protein \
  --output output_prefix \
  --alignment_tool DIAMOND \
  --local --clean --num_threads 24 --include_nudge
```

Inputs:

- Protein FASTA without `*` stop symbols.
- Local CARD database loaded with `rgi load --card_json ... --local`.

Outputs:

- `RGI.txt`: main tabular result.
- Additional RGI auxiliary outputs depending on version/options.

Interpretation:

- `Cut_Off` indicates Perfect/Strict/Loose confidence.
- `Best_Hit_ARO`, `Drug Class`, `Resistance Mechanism`, `AMR Gene Family` are the main biological fields.
- `Nudged=True` means RGI promoted a loose hit; report that nuance.

Common failure modes:

- CARD database not loaded in the environment used to run RGI.
- Wrong DIAMOND version for the RGI version.
- Protein FASTA contains `*`, causing parsing/alignment issues.

## sed

Purpose in this workflow:

- Remove stop symbols from protein FASTA before RGI:

```bash
sed 's/\*//g' input.faa > clean.faa
```

Risk:

- This removes all literal `*` characters. It is appropriate for protein stop symbols in this workflow, but do not apply blindly to unrelated files.

## find / sort / wc

Purpose:

- Discover sample directories.
- Count completed outputs.
- Build deterministic sample order.

Examples:

```bash
samples=($(find "$input_dir" -mindepth 1 -maxdepth 1 -type d ! -name "tmp" | sort))

find "$input_dir" -type f -name "eggNOG.emapper.annotations" \
  | xargs -r -n1 dirname | sort -u | wc -l
```

Risk:

- Counting files by name alone can count partial or corrupt outputs. Pair counts with integrity checks.

## Lock-file tools: ps / lsof / stat

Purpose:

- Decide whether `.lock` belongs to a live job or is stale.

Checks:

```bash
cat "$sample_dir/.lock"
ps -ef | grep -F "$sample_dir" | grep -v grep
lsof +D "$sample_dir" 2>/dev/null | head
stat "$sample_dir/.lock"
```

Only remove a lock after checking no active process owns the sample.

## Resource monitors

Use these before raising parallelism:

```bash
top
htop
iostat -xz 5
free -h
df -h
```

How to interpret:

- High CPU usage with low I/O wait: CPU-bound, more jobs may still be possible if RAM allows.
- High I/O wait (`wa`) or disk utilization: storage-bound, reduce `max_jobs` or move database/temp to faster storage.
- High memory usage/swap: reduce `max_jobs`, reduce `--cpu`, or avoid `--dbmem`.
- Full temp/output filesystem: jobs may fail or produce partial outputs.

For production monitoring, include the upstream prediction tools as well as annotation tools:

```bash
ps -eo pid,ppid,stat,pcpu,pmem,rss,etime,cmd | grep -Ei 'emapper|mmseqs|diamond|rgi|prodigal|genomad|metaeuk' | grep -v grep
iostat -xz 5
free -h
```

## nohup

Purpose:

- Run lightweight monitoring/helper scripts detached from terminal.

Example:

```bash
nohup bash monitor_emapper.sh > monitor_emapper.nohup.log 2>&1 &
```

If output is not redirected, it goes to `nohup.out`.

## watch

Purpose:

- Interactive repeated monitoring.

Example:

```bash
watch "ps aux | grep -E 'emapper|mmseqs|diamond|rgi' | grep -v grep"
```

Important:

- Do not put `watch` before real work in a batch script. It blocks until interrupted.

## Tool Chain By Task

CAZyme:

```text
reference FASTA -> diamond makedb -> DIAMOND .dmnd -> diamond blastp -> CAZyme TSV
```

VFDB:

```text
VFDB FASTA -> diamond makedb -> DIAMOND .dmnd -> diamond blastp -> VFDB TSV
```

eggNOG:

```text
protein FASTA -> emapper.py search backend DIAMOND/MMseqs -> seed orthologs -> final annotations
```

CARD/RGI:

```text
protein FASTA -> sed remove stop symbols -> rgi main with local CARD -> RGI.txt
```

Batch orchestration:

```text
screen + conda + find sample dirs + lock files + database copy rotation + emapper.py background jobs + wait + validation
```
