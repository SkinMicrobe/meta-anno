# Meta-Annotation Workflow Notes

This reference distills the user's current metagenome annotation notes.

## Main Tools

| Tool | Purpose | Typical output |
| --- | --- | --- |
| DIAMOND `blastp` | Protein-to-protein search against CAZyme, bacterial VFDB, or fungal FungAMR databases | BLAST outfmt 6 TSV |
| DIAMOND `makedb` | Build local `.dmnd` search databases from FASTA references | `*.dmnd` |
| eggNOG `emapper.py` | Orthology search and functional annotation | `eggNOG.emapper.annotations`, `*.seed_orthologs` |
| Prodigal | Bacterial/prokaryotic gene/ORF prediction from nucleotide MAGs/contigs to protein `.faa` | Protein FASTA `.faa`, nucleotide CDS if requested |
| MetaEuk | Fungal gene prediction branch from nucleotide input to protein predictions | Fungal/eukaryotic protein predictions |
| geNomad | Viral branch for viral sequence identification/annotation | geNomad outputs, to be specified when that branch is implemented |
| Barrnap | Current rRNA prediction replacement for the original SMGC `INFERNAL`/`cmsearch` step | rRNA feature calls and downstream rRNA summaries |
| RGI/CARD | Antibiotic resistance gene detection | `RGI.txt` and RGI auxiliary outputs |
| FungAMR | Fungi-branch virulence-factor annotation in the user's workflow | FungAMR DIAMOND TSV, followed by validated CSV conversion |
| `screen` | Long-running detached terminal sessions with log capture | screen log files |
| `nohup` | Detached monitoring or helper scripts outside screen | `nohup.out` unless redirected |

## Observed Environments

- `smag`: used for DIAMOND, RGI, and earlier annotation commands.
- `smag_eggNOG`: used for eggNOG mapper with newer DIAMOND/MMseqs.
- C2/C4 split was controlled with `HOST_INDEX=0` and `HOST_INDEX=1`.
- Example conda initialization paths in notes:
  - `/home/compute2/miniconda3/etc/profile.d/conda.sh`
  - `/home/com4/miniconda3/etc/profile.d/conda.sh`
- Some notes indicate DIAMOND version constraints:
  - RGI 6.x depended on older DIAMOND in one environment.
  - eggNOG required newer DIAMOND/MMseqs in a separate environment.
- Observed eggNOG install check:
  - `emapper-2.1.12`
  - expected eggNOG DB version `5.0.2`
  - DIAMOND `2.1.14`
  - MMseqs2 `18.8cc5c`
- An eggNOG warning about missing site-package `data/eggnog.db` can be ignored when `--data_dir` points to the user's own database location.

## Input Entry Contract

Before suggesting functional annotation, classify the input and route it explicitly.

Required parameters or inferred fields:

```text
input_sequence_type = protein | nucleotide | auto
organism_type = bacteria | fungi | virus | unclassified | prokaryote | eukaryote | mixed
taxonomy_classifier = existing | kraken2 | deepmicroclass | auto
prediction_tool = existing_faa | prodigal | metaeuk | genomad | auto
```

Current implementation stance:

- First make the bacterial/prokaryotic branch work reliably when that is the confirmed target.
- If the input is contigs and the biological source is unclear, default the organism branch to `mixed contigs`. Do not infer `bacteria` or `prokaryote` from the path/name alone.
- Mixed-contig taxonomic classification may use `Kraken2` or `DeepMicroClass` (`DMC`). `Kraken2` is the faster preliminary option but can produce unreliable or overconfident assignments; `DMC` is slower but should be preferred when classification accuracy is more important than speed.
- Treat Kraken2 branch assignments as provisional evidence requiring cautious interpretation. Do not turn a Kraken2 label into a certain biological conclusion without supporting evidence.
- Reuse existing valid Kraken2/DMC outputs when available. If the user specifies a classifier, keep that classifier; if it is missing, try to activate or install it in the user-confirmed environment rather than silently switching tools.
- For `input_sequence_type=protein`, require existing `.faa` files and validate non-empty protein counts before the branch-appropriate eggNOG/CARD/VFDB/FungAMR/CAZy workflow.
- For `input_sequence_type=nucleotide` with `organism_type=bacteria` or `organism_type=prokaryote`, run or require a Prodigal-style ORF prediction step first, then use the resulting `.faa` for functional annotation.
- For `organism_type=unclassified`, run or require a Prodigal-style ORF prediction step first, then use the resulting `.faa` for functional annotation. This is a handling rule, not a taxonomic claim.
- For `organism_type=fungi`, route nucleotide input through MetaEuk before functional annotation.
- For `organism_type=virus`, route viral analysis through geNomad.
- For branch-specific virulence annotation, use VFDB for bacterial/prokaryotic proteins and FungAMR for fungi proteins. Do not treat VFDB as the fungi virulence database.
- The FungAMR query input is the validated fungi `.faa` produced by MetaEuk. If FungAMR is missing, attempt to locate or prepare that database; do not silently replace it with VFDB.
- Do not send nucleotide MAGs/contigs directly into the functional annotation plan. In this skill's workflow, functional annotation requires validated protein `.faa` input produced by the appropriate upstream prediction/translation branch.
- Keep extension points explicit: broad `organism_type=eukaryote` needs a confirmed sub-branch before assuming MetaEuk; `organism_type=mixed` should remain the default for unclear contigs and should be split/classified into available branches when evidence exists. Use `prodigal` for unclassified contigs but keep outputs labeled as unclassified, for example `unclassified_prodigal`.
- If the user has already run Prodigal and a valid `8_prodigal/faa/` or equivalent protein directory exists, do not rerun prediction by default. Validate and use the existing `.faa`.
- If only nucleotide FASTA is present, make the next safe action "predict/translate to protein `.faa` first" rather than "start annotation".

Missing-tool rule:

- Do not change biological routing because a tool is missing. If `genomad` is missing for viral contigs, do not substitute Prodigal; if `metaeuk` is missing for fungal contigs, do not substitute Prodigal; if `prodigal` is missing for bacterial/prokaryotic/unclassified contigs, do not substitute another tool.
- Do not replace a requested `Kraken2` classification with `DeepMicroClass`, or vice versa, solely because one tool is missing.
- First try the correct conda environment or install the missing tool in the user-confirmed environment. If installation is not possible, report that branch as blocked and keep the intended route unchanged.

## Batch Sizing From Input Files

Compute batches from the actual input files whenever the directory can be inspected or the user provides counts/sizes.

Required input-size fields:

```text
input_count
total_input_bytes
largest_input_bytes
target_batch_bytes
expected_batches = ceil(total_input_bytes / target_batch_bytes)
```

Rules:

- For contigs or other nucleotide FASTA input, split into smaller files before gene prediction or annotation planning.
- Use file-size grouping when many files already exist; avoid making a giant intermediate FASTA on Ceph only to split it again.
- If a single input file is larger than the target batch size, split that file first, then include the pieces in the batch plan.
- Keep the default target below about `1G` per FASTA chunk unless live resource measurements justify a different size.
- Label units accurately: chunks/batches are not samples, MAGs, or contigs unless that is the real unit.

## Continuous Resource And I/O Monitoring

Resource checks are not one-time preflight checks. For production runs, keep monitoring CPU, memory, and read/write I/O throughout the run.

Minimum signals:

```bash
date -Is
free -h
df -h /tmp "$PWD" 2>/dev/null
iostat -xz 5 2
ps -eo pid,ppid,stat,pcpu,pmem,rss,etime,cmd | grep -Ei 'emapper|mmseqs|diamond|rgi|prodigal|genomad|metaeuk|barrnap' | grep -v grep
```

Interpretation:

- Use `MemAvailable` and active process RSS to decide whether another batch can start.
- Use CPU `%idle` and process `%CPU` to decide whether CPU is really saturated.
- Use `%iowait`, device `%util`, and read/write throughput from `iostat` to estimate how much the run is I/O-bound.
- If I/O wait or device utilization stays high, lower `max_jobs` even when CPU threads and memory look sufficient.
- Save monitor output under `$output_root/logs/` so later advice can be based on evidence rather than memory.

## Multi-Server Shared-Path Execution

The user's tutorial includes C2/C4 runs where both servers see the same Ceph path and split work with `HOST_INDEX=0` / `HOST_INDEX=1`. This is an example of the general `HOST_INDEX` / `HOST_COUNT` pattern, not a two-server limit.

Default rule:

- If the user does not explicitly request multiple servers, plan for the current server only and use `HOST_COUNT=1` conceptually.
- Do not infer that C2, C4, or any other server should be used just because the path is on shared Ceph.
- From Claude Code running on one server, other servers' runtime state is not visible by default. Shared paths may show files, logs and timestamps, but not remote processes, `screen` sessions, CPU/RAM usage or I/O wait.

Use the multi-server model only when the user wants to avoid overloading one server and confirms the participating servers:

- Split the manifest explicitly with user-confirmed `HOST_COUNT=N` and one `HOST_INDEX` per server, so each server owns a deterministic subset. This may be 2, 3, 4 or more servers depending on the user's current resource plan.
- Keep `.lock` files atomic and include `hostname`, PID, timestamp and sample/batch path in the lock content.
- Use a separate `screen`/`tmux` session on each launching server.
- Keep per-host monitor logs, PID files and exit-code files under the confirmed output root.
- Assign database copies deliberately. Do not let every host read the same database copy when separate copies exist.
- Use host-specific temp directories such as `$output_root/tmp/$HOSTNAME/...` when possible to avoid temp collisions.
- Count completion from the shared output path, but inspect running processes on the launching host.
- Estimate both per-host and total concurrency. For example, four servers with `max_jobs=4` each is a 16-job shared-storage run, not four isolated 4-job runs.
- If I/O wait is high on either host, reduce total jobs even if each individual server still has CPU/RAM headroom.

## Annotation CSV Outputs

Functional annotation outputs should remain in their original tool formats and also be converted to CSV after validation.

Rules:

- Convert only validated annotation outputs; do not turn an error-contaminated partial file into a final CSV.
- Preserve original files such as `*.emapper.annotations`, DIAMOND TSVs, and `RGI.txt`.
- Write derived CSV files under the user-confirmed output root.
- For one source FASTA, derive the CSV name from the input basename and tool/database, for example `sample_001.eggnog.annotations.csv`, `sample_001.vfdb.csv`, or `sample_001.card.csv`.
- Do not name a single-FASTA result `all_annotations.csv`, `all.emapper.annotations.csv`, `combined_annotations.csv`, `merged_annotations.csv`, or `final_annotations.csv`. These names are reserved for a genuine validated aggregation across an explicitly defined full scope.
- For a true aggregate, preserve its input manifest and use a scope-bearing filename such as `${project_name}.all_inputs.eggnog.annotations.csv`.
- Use a parser (`python csv`, `pandas`, `mlr`, or another structured parser) rather than blind delimiter replacement.
- For eggNOG annotation merging, keep exactly one `#query` header before CSV conversion and append only non-comment data rows.

## Core Paths Seen In Notes

Examples only; do not hardcode unless the user confirms:

```text
/mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs
/mnt/cephfs/s2z2/SProject/02-meta/10-anno-mags/02_function
/mnt/cephfs/s2z2/SProject/02-meta/10-anno-mags/02_function2
/mnt/cephfs/s2z5/skin/00-data/8_eggNOG/eggnog_db_copy_
/mnt/cephfs/s2z1/db/eggnog_db_new
/mnt/cephfs/s2z1/db/CARD
/mnt/cephfs/s2z1/db/CAZy/CAZy-V14.fa
/mnt/cephfs/s2z1/db/VFDB2025/VFDB_setB_pro.fas
```

## SMGC-Derived MAG Workflow Notes

The user's current MAG workflow should be interpreted as SMGC-derived, with one important local replacement:

- The original SMGC paper used `INFERNAL`/`cmsearch` with Rfam covariance models for 5S/16S/23S rRNA detection.
- In the user's current workflow, rRNA detection uses `Barrnap` instead of `INFERNAL`/`cmsearch`.
- Apart from this rRNA replacement, treat the rest of the MAG workflow as intended to follow SMGC unless live scripts, directories, logs or outputs prove a local deviation.
- Do not call a current rRNA output directory an `INFERNAL` result only because the SMGC paper used `INFERNAL` or because file names resemble old `cmsearch` outputs.
- If a directory contains both `Barrnap` and legacy `INFERNAL`-like names, resolve the truth from active scripts, logs, command lines and timestamps before explaining the step.

Common correction for `allporkmags` / `allprokmags` analysis:

- Interpret the directory first as the collected prokaryotic MAG nucleotide FASTA set, not as an `INFERNAL` output folder.
- A `.fa` file in this area is a MAG nucleotide sequence, not a protein FASTA for functional annotation.
- Do not infer the whole directory's purpose from leftover `.cmsearch`, `.tblout`, or `cmsearch.log` names.
- Do not use tRNA counts to validate `cmsearch`; tRNA should be tied to the `tRNAscan-SE` branch unless active evidence says otherwise.
- If a previous AI response suggests rerunning or repairing `cmsearch`, treat that as suspect because the current workflow abandoned `INFERNAL` for rRNA. Only continue that branch if the user explicitly asks for legacy-output recovery.
- Do not call legacy INFERNAL-like artifacts "failed" based only on zero rRNA counts. Distinguish "legacy/abandoned/not current" from "failed", and require logs or command status for the latter.
- If the user wants functional annotation, redirect to Prodigal protein output such as `8_prodigal/faa/` and verify that directory's current state before writing batch scripts.
- If the user wants MAG quality filtering, combine CheckM2, Barrnap rRNA, tRNAscan-SE, GUNC, dRep and GTDB-Tk outputs; do not collapse these into one `INFERNAL` step.

Directory naming guardrail:

- `02_function` and `02_function2` are historical examples from some notes, not fixed directory names.
- Do not infer that functional annotation has not started just because a directory with that exact name is absent.
- Locate functional annotation by actual marker files, script variables and logs: `eggNOG.emapper.annotations`, `*.seed_orthologs`, RGI output names, CAZy/VFDB DIAMOND TSVs, `eggnog_run.log`, batch scripts, or user-confirmed roots.
- When generating commands, use placeholders such as `$function_dir`, `$faa_dir`, `$output_root`, and ask/verify the real path instead of hardcoding `02_function`.
- Do not state "functional annotation has not started" unless the marker search covered the user-confirmed analysis root. Prefer "not found in the checked locations" when scope is incomplete.
- Do not invent new fixed output roots such as `9_functional_annotation`. If a new output area is needed, present it as `$output_root` and ask the user to confirm the actual path before any `mkdir`, `ln -s`, `cp`, or job submission.

Prodigal/protein FASTA completion guardrail:

- If Prodigal reports a failed list but `.faa` file counts appear complete, do not immediately claim both "failed samples exist" and "all `.faa` are usable".
- Check non-empty files, sequence counts, timestamps and failed-list overlap with actual `.faa` basenames.
- A complete-looking `.faa` count can mean the failure log is stale, failures were later rerun, output files are empty/partial, or names do not match one-to-one.
- Do not start eggNOG/CARD/VFDB/FungAMR/CAZy batch scripts until the protein FASTA set has passed a simple integrity check.
- If only dRep representative MAGs were checked against `.faa` files, report that limited result only. It does not prove all 7,535 Prodigal outputs are complete or suitable for downstream annotation.

## Single-Sample Functional Annotation Pattern

Build CAZyme database:

```bash
diamond makedb \
  --in /mnt/cephfs/s2z1/db/CAZy/CAZy-V14.fa \
  -d /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/localDB/CAZyme_db
```

Build VFDB database:

```bash
diamond makedb \
  --in /mnt/cephfs/s2z1/db/VFDB2025/VFDB_setB_pro.fas \
  -d /path/to/VFDB_setB
```

VFDB note:

- Set A/Core: experimentally confirmed representative virulence factors; more conservative and precise.
- Set B/Full: expanded full set including homologs and alleles; higher recall and more false-positive risk.
- In this workflow, VFDB is for the bacterial/prokaryotic virulence branch. Fungi virulence-factor annotation uses FungAMR instead.

FungAMR note:

- Use validated MetaEuk fungi proteins as the DIAMOND `blastp` query.
- Preserve the original FungAMR FASTA. If headers require cleaning before `diamond makedb`, write a separate derived cleaned FASTA rather than overwriting the source database.
- The observed tutorial removes `##` metadata lines, removes spaces from FASTA headers, builds a FungAMR DIAMOND database, and searches with `--evalue 1e-5 --max-target-seqs 1`.
- Convert the validated TSV to a source-specific CSV such as `${input_stem}.fungamr.csv`; never call a single fungi FASTA result `all_annotations.csv`.

CAZyme, bacterial VFDB, and fungal FungAMR are DIAMOND searches:

```bash
diamond blastp \
  --db "$db" \
  --query "$input_faa" \
  --out "$output_tsv" \
  --outfmt 6 \
  --evalue 1e-5 \
  --max-target-seqs 1 \
  --threads 24
```

eggNOG can be run as two phases:

```bash
emapper.py --no_annot --no_file_comments --override --cpu 16 \
  --data_dir "$db_path" -i "$input_faa" -m diamond \
  -o "$output_dir/eggnog_process" --temp_dir "$temp_dir"

emapper.py \
  --annotate_hits_table "$output_dir/eggnog_process.emapper.seed_orthologs" \
  --data_dir "$db_path" \
  --cpu 8 --no_file_comments --override \
  -o "$output_dir/eggnog" --temp_dir "$temp_dir"
```

Use this two-phase pattern as the preferred recovery path when search already succeeded but annotation failed. If `*.emapper.seed_orthologs` exists and is non-empty, do not rerun the expensive MMseqs/DIAMOND search just to repair SQLite annotation errors. Run the `--annotate_hits_table` phase again with `--dbmem` and write to a new output prefix first.

RGI/CARD first removes protein stop symbols:

```bash
sed 's/\*//g' "$input_faa" > "$output_dir/input.clean.faa"

rgi main \
  --input_sequence "$output_dir/input.clean.faa" \
  --input_type protein \
  --output "$output_dir/macrel_rgi" \
  --alignment_tool DIAMOND \
  --local --clean --num_threads 24 --include_nudge
```

Important RGI flags from the notes:

- `--input_type protein`: input is protein FASTA, not contigs.
- `--alignment_tool DIAMOND`: use DIAMOND for alignment.
- `--local`: use local CARD database.
- `--clean`: remove temporary files.
- `--include_nudge`: include hits nudged from loose to strict.
- `--include_loose`: available when loose hits are intentionally needed, but not part of the usual strict workflow.

## Batch eggNOG Pattern

The user's scripts scan sample directories, expect:

```text
sample_dir/$(basename sample_dir).clean.faa
sample_dir/eggNOG.emapper.annotations
sample_dir/.lock
sample_dir/eggnog_run.log
```

This is an observed layout, not a required global convention. Confirm the actual input/output layout before writing scripts.

Common loop:

1. Build `samples` with `find "$input_dir" -mindepth 1 -maxdepth 1 -type d | sort`.
2. Skip samples with existing `eggNOG.emapper.annotations`.
3. Skip samples with existing `.lock`.
4. Create `.lock` atomically using `set -o noclobber`.
5. Rotate database copy with `db_index=$(( (job_index % max_jobs) + db_start ))`.
6. Start `emapper.py` in background.
7. `wait` every `max_jobs` submissions.

Observed host/script variants:

| Variant | Input root | Sort | `max_jobs` | Database copies |
| --- | --- | --- | --- | --- |
| C1 function2 | `02_function2` | ascending | 4 | `eggnog_db_copy_1` to `_4` |
| C1 function | `02_function` | reverse | 2 | `eggnog_db_copy_15` to `_16` |
| C2 function | `02_function` | ascending | 4 | `eggnog_db_copy_6` to `_9` |
| C2 function2 | `02_function2` | reverse | 2 | `eggnog_db_copy_11` to `_12` |

C2/C4 contig annotation split:

- C2 used `HOST_INDEX=0`, described as even-index work.
- C4 used `HOST_INDEX=1`, described as odd-index work.
- Both were launched under `screen` with log files under the annotation directory.

## SMGC dRep361 eggNOG Test Lessons

Recent SMGC dRep representative MAG testing exposed run-management pitfalls that should be treated as guardrails for future advice:

- The output root was restricted to `/mnt/cephfs/s2z5/skin/00-data/1_DB_MAGs/SMGC/test`; generated files belonged under that root only.
- C2 and C4 shared the same Ceph path, so file state was visible from both hosts, but running `emapper.py`/`mmseqs` processes were visible only on the launching host, C2.
- A `nohup emapper.py ... > test/logs/batch_N.log 2>&1 &` launch can keep work running, but it is not an adequate production manager for long runs when used without `screen`, a saved runner script, main log, PID files, and exit-code files.
- Zero-byte batch logs do not prove failure while a child `mmseqs` process is still running, but they are poor observability. Require a wrapper log that records start, host, PID, command, input, database copy, temp directory, output prefix, and final exit code.
- If a run is already alive without `screen`, do not restart only to fix logging. Verify the launching host, monitor the live process tree, and wait for completion unless there is a decisive failure.
- Avoid broad cleanup commands such as `pkill -9 -f emapper.py` or `pkill -9 -f mmseqs` in shared servers. Record and use per-batch PID files instead.
- DIAMOND `0.8.36` is too old for eggNOG-mapper `2.1.12` behavior that passes newer DIAMOND options. Switching to `-m mmseqs` is a valid workaround when MMseqs is available and the database copy includes `mmseqs/mmseqs.db`.
- Directly concatenating MAG/sample `.faa` files can leave ambiguous protein IDs such as `NODE_..._1`. For any merged multi-MAG or multi-sample protein FASTA, rewrite protein IDs to globally unique first tokens and write `protein_to_mag.tsv` before splitting/running eggNOG. dRep representatives are only one example of this general rule.
- If a merged multi-MAG FASTA was already produced by plain `cat`, check `seqs`, `unique_first_tokens`, and `duplicate_first_tokens` before trusting downstream outputs. Duplicate first-token IDs mean MAG/sample provenance is ambiguous; rebuild a uniquely rewritten FASTA and rerun annotation from search because query IDs have changed.
- A MAG/sample prefix alone can still fail when an individual source `.faa` contains duplicate first-token IDs. Prefer IDs shaped like `MAG|p000001|old_id`, with the per-record component stored in `protein_to_mag.tsv`, and require `duplicate_first_tokens=0` before annotation.
- MMseqs may run repeated sensitivity rounds that alternate `prefilter` and `align`; memory dropping after one prefilter does not prove the whole prefilter/search phase is finished.
- Progress reports should include a user-copyable completion count command. For chunked FASTA runs, report completed batches such as `completed_batches=0/4`; for sample/MAG directory runs, report completed samples or MAGs. Do not call a chunk count a sample count.
- Reference batch scripts used `-m mmseqs --dbmem` for eggNOG. On Ceph/shared storage, omission of `--dbmem` can make the SQLite annotation stage fail even when MMseqs search succeeds.
- If failed logs show `sqlite3.OperationalError: disk I/O error` or `database disk image is malformed` after `*.emapper.seed_orthologs` was produced, treat it as annotation-stage failure. Prefer `emapper.py --annotate_hits_table existing.seed_orthologs --dbmem` into a new results directory over full rerun.
- Do not claim the seed-ortholog search stage is bad only because `seed_orthologs` is a small fraction of all input proteins. Require search-stage errors, empty/missing seed files, wrong parameters, or a comparable successful control before recommending a full MMseqs rerun.
- When merging recovered `*.emapper.annotations`, remove all header/comment rows from later batches. A valid combined table should have one `#query` header, data rows counted with `grep -cv '^#'`, and no duplicate query IDs unless the duplicate-ID risk has been explicitly explained.

## Main Operational Risks

- Existence-only completion check can skip corrupted or partial outputs.
- Stale `.lock` files remain after crashes and block reruns.
- Shared Ceph temp directories increase I/O pressure.
- Multiple workers reading one database copy can overload network storage.
- Increasing CPU threads does not help if `iostat` shows sustained I/O wait.
- Host-specific DIAMOND/MMseqs/RGI versions can make a script valid on one machine but invalid on another.
- Variable values with trailing spaces, especially input FASTA paths, can cause file-not-found behavior.
- `watch` is interactive and should not sit inside a non-interactive batch script before `conda activate`; use it in a separate terminal/session.
- Launching long annotation jobs with only `nohup ... &` makes recovery and auditing weak. Prefer `screen` or `tmux` plus a saved runner script, main log, per-batch logs, PID files and exit-code files.
- On shared Ceph paths, file evidence and process evidence may disagree when inspected from different hosts. Check live processes on the actual launching host.
- Zero-byte logs are not a completion signal and not a reliable progress signal. Combine process-tree checks, temp-file timestamp/size checks, result-file checks and exit-code files.
- Broad `pkill -f` cleanup can kill unrelated user jobs. Use recorded PIDs or command lines constrained to the confirmed output root.
- Merged protein FASTA files can destroy MAG/sample provenance if IDs are not globally unique. Rewrite IDs to unique first tokens and keep a mapping table.
- Repeated `#query` headers in a combined eggNOG annotations file are a merge defect. They inflate line counts and can break downstream parsers; merge one header plus non-`#` data rows only.
- Every long-run handoff should include one command the user can run later to answer "how many units have completed?" Use expected input count plus non-empty validated output count, and label the unit type accurately.
- Avoid unsupported explanations such as "Ceph delay caused log creation failure" unless command output proves filesystem latency or write failure.
- For eggNOG on Ceph, use `--dbmem` when memory allows. The annotation stage performs many SQLite reads from `eggnog.db`; repeated SQLite I/O errors can leave small, misleading `.emapper.annotations` files.
- When `*.emapper.hits` and `*.emapper.seed_orthologs` are present but annotations are tiny or error-contaminated, salvage with annotation-only rerun from seed orthologs before considering a full search rerun.
- If annotation-only recovery produces clean logs and recovered annotation rows close to seed rows, treat the annotation repair as successful. Do not automatically escalate to full rerun just because the seed yield is lower than expected.
- Remount commands such as `sudo umount -l /mnt/cephfs && sudo mount -a` are operationally disruptive. Use them only when the user intentionally wants to recover a broken mount.
- Original notes mention keeping eggNOG input files under about 5 GB; check input size before blaming tool failure.

## Practical Scaling Heuristic

For eggNOG/mmseqs on Ceph:

1. Split large FASTA at the start, typically to about `1G` per chunk, before memory-heavy eggNOG/database annotation.
2. Derive the number of chunks/batches from input file sizes instead of assuming a fixed count.
3. For a 24-thread annotation job against an approximately `40G` database, estimate about `60G` memory per job as a working value.
4. Budget the same job as about `70G` when deciding parallelism, leaving margin for OS cache, temp files and runtime variation.
5. On an approximately `300G` RAM server, start around 4 concurrent jobs because `4 * 70G = 280G`, which is already close to the memory ceiling.
6. Keep per-sample CPU explicit and do not increase `max_jobs` just because CPU threads are available.
7. Use separate database copies for concurrent workers when storage allows.
8. Watch `iostat -xz 5`; if `%iowait` or device utilization is high, reduce `max_jobs`.
9. Prefer per-sample temp dirs; use local scratch if available and large enough.
10. Validate completion before deleting locks or marking runs done.

FASTA splitting caution:

- Confirm the installed `seqkit` option semantics with `seqkit split --help` and `seqkit split2 --help` before writing a command.
- Do not assume `seqkit split -s 1G` means "split into 1GB files"; in many versions `-s` is not byte-size chunking.
- On Ceph/shared storage, avoid unnecessary `cat many/*.faa > all.faa` when a file-list batching strategy can avoid extra large sequential writes.
- Do not claim that merging all `.faa` into one file is necessarily more efficient. It can simplify one run, but it can also create large intermediate I/O, worse restart granularity and harder partial recovery.

Shared-storage caution:

- On the user's shared cloud/Ceph storage, jobs can stall even when memory and CPU are sufficient.
- Multiple workers reading large database copies and writing temp/output files can make I/O the real bottleneck.
- If CPU utilization is low while jobs appear stuck, check I/O before blaming tool failure or increasing threads.
- Treat the 1G chunk, 24-thread, about 4-jobs-per-server setting as a starting point, then tune from live RAM, CPU and I/O observations.

## Server Resource Inference

When asked how many jobs a server can run, infer available runtime resources from the current server state instead of using total hardware alone.

Minimum live checks:

```bash
nproc
lscpu | egrep 'CPU\(s\)|Thread|Core|Socket|Model name'
free -h
df -h /tmp "$PWD" 2>/dev/null
iostat -xz 5 3
ps -eo pid,ppid,stat,pcpu,pmem,rss,etime,cmd | grep -Ei 'emapper|mmseqs|diamond|rgi|prodigal|genomad|metaeuk|barrnap' | grep -v grep
```

Interpretation rules:

- Use `MemAvailable` from `free`, not total RAM, to estimate new jobs.
- Keep a safety reserve for the OS, filesystem cache, shells, monitoring and other users. If there is no better measurement, reserve at least 10-20 percent of memory or 20-30G.
- Treat current annotation processes as already consuming memory, CPU and I/O. Do not recommend new jobs as if the server were idle.
- Compute separate limits: memory, CPU threads, database-copy count, free temp/output storage and I/O wait.
- Use the most restrictive limit as the recommended starting `max_jobs`.
- If `max_jobs_by_mem` is `1` or lower, recommend one pilot job first. Only scale above one after measured RSS and I/O show headroom.
- If `iostat` shows sustained high `%iowait` or device utilization, reduce concurrency even when `free` and `nproc` look comfortable.
- If no live checks are available, state that the answer is a heuristic estimate and give the commands needed to verify it.

Suggested calculation shape:

```text
usable_ram = MemAvailable - reserved_ram
max_jobs_by_mem = floor(usable_ram / estimated_ram_per_job)
max_jobs_by_cpu = floor(usable_threads / cpu_per_job)
max_jobs_by_db = available_database_copies
safe_max_jobs = min(max_jobs_by_mem, max_jobs_by_cpu, max_jobs_by_db, io_limit)
```

For the user's current eggNOG setting, `estimated_ram_per_job` can start at about `70G` for a `1G` FASTA chunk with `24` threads against an approximately `40G` database. Replace this with observed RSS if `ps` or prior logs show a better local value.

Observed rough runtime notes from the user's record:

- One sample took about `7136 secs` in one run.
- A 100-sample estimate was about `10800 secs` in another context.
- A single MMseqs job was noted around `65G`.
- Treat these as environment-specific measurements, not universal constants.

## eggNOG Installation Notes

Observed installation pattern:

```bash
mamba env remove -n smag_eggNOG
mamba create -n smag_eggNOG python=3.12 -c bioconda -c conda-forge eggnog-mapper
mamba activate smag_eggNOG
pip install biopython
pip install --no-build-isolation --no-deps eggnog-mapper
conda install -c conda-forge biopython pandas tqdm psutil requests numpy scipy -y
which emapper.py
emapper.py --version
```

Database download notes:

- Full eggNOG data can require about 500 GB.
- `download_eggnog_data.py -M` installs MMseqs2 database data.
- `download_eggnog_data.py -H -d 2` is for Bacteria HMMER data.
- If the user already has database copies and uses `--data_dir`, do not tell them to redownload first.
