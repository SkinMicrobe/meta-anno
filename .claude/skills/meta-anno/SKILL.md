---
name: meta-anno
description: Analyze, repair, and generate metagenome functional annotation workflows using eggNOG/emapper, DIAMOND, RGI/CARD, VFDB, CAZyme, multi-host batch scripts, lock files, database copies, and Ceph/HPC I/O. Use when asked to explain meta-annotation scripts, estimate safe parallelism, triage failed samples, validate outputs, resume interrupted runs, or write reproducible Linux commands for annotation jobs.
---

# Meta-Anno

Use this skill for metagenome functional annotation analysis and batch-run engineering around eggNOG/emapper, DIAMOND, RGI/CARD, VFDB, CAZyme, Ceph paths, and multi-server execution.

Reply in Simplified Chinese unless the user asks for English. Keep commands, paths, tool names, logs, and option names unchanged.

## Operating Mode

Start from evidence, not assumptions.

Evidence priority:
1. Live runtime behavior: running processes, active logs, output timestamps, filesystem state.
2. Captured logs and command output.
3. Actively used scripts and current environment variables.
4. Output files and completion markers.
5. Checked-in or pasted source.
6. Comments, notes, and old examples.

When analyzing or modifying scripts:
- Prefer `rg`, `find`, `awk`, `sed`, `sort`, `wc`, `tail`, `head`, `ps`, `free`, `df`, `iostat`, `lsof`, and `stat`.
- Use Linux commands when the target paths are `/mnt/...`, `/home/...`, or the user says they will run on a Linux server.
- Do not enumerate unrelated home directories, credentials, SSH keys, or unrelated secrets.
- Preserve original artifacts. Make backups or write derived files separately before replacing important scripts.
- State the exact assumption you are using when path, host, conda env, database copy range, or sample layout is unclear.

## First Pass

For any requested analysis, extract this table first:

| Field | What to identify |
| --- | --- |
| Scope | contigs, MAGs, one sample, one folder, one host, or multi-host run |
| Input | `input_dir`, `faa_file`, expected `*.clean.faa`, raw `.faa`, nucleotide FASTA, or sample directory layout |
| Sequence type | protein `.faa` already available, nucleotide `.fa/.fna/.fasta`, or mixed/unclear |
| Organism type | current target branch such as `prokaryote`, `eukaryote`, `bacteria`, or `mixed`; default current implementation is `prokaryote` unless evidence says otherwise |
| Prediction route | existing protein FASTA, `prodigal`, `metaeuk`, `genomad`, or deferred/parameter placeholder |
| Database | `db`, `db_path`, `db_base`, database copy range, CARD path, eggNOG data dir |
| Output | expected result file, discovered output directory, log path, temp path |
| Tool | `diamond blastp`, `emapper.py`, `rgi main`, or wrapper script |
| Parallelism | `max_jobs`, per-job `--cpu`, total threads, host count |
| Server resources | CPU threads, `MemAvailable`, current annotation jobs, database copies, temp/output storage, I/O wait |
| Coordination | `.lock` behavior, host split rule, database copy assignment |
| Failure signal | missing output, small output, stale lock, traceback, killed process, I/O wait, no space |

For multi-host Ceph/shared-storage runs, distinguish file evidence from process evidence:
- File outputs, logs, temp directories, and timestamps can usually be inspected from any host that mounts the shared path.
- Running processes, CPU/RAM usage, `screen` sessions, and child process trees must be checked on the host that actually launched the job.
- Do not conclude a run has stopped only because another shared-storage host has no matching process.

Then answer in this order when it fits:
1. Outcome.
2. Key evidence.
3. Verification commands.
4. Next safe action.

## Input Prediction And FASTA Splitting

When the user asks about the upstream prediction stage for this workflow, preserve the speaker's meaning. You may normalize wording, fix obvious typos such as `prodiagl` to `prodigal`, and explain tool names, but do not silently replace the intended route with a different biological recommendation unless the user explicitly asks for critique.

Use this workflow understanding:
- At the beginning, classify both the sequence type and the organism/type branch. Do not assume the input is already protein.
- If protein FASTA (`.faa`) already exists and passes integrity checks, use it as the direct input for eggNOG/CARD/VFDB/CAZy.
- If the input is nucleotide FASTA (`.fa`, `.fna`, `.fasta`, contigs, MAGs, or assemblies), add an upstream gene prediction / ORF prediction step to produce protein FASTA (`.faa`) before functional annotation.
- Treat "nucleotide to protein" as gene/ORF prediction, not blind six-frame translation.
- eggNOG can accept nucleotide input in some modes, but for this skill prefer an explicit protein FASTA input because it is usually faster, easier to validate, and easier to control for memory/I/O.
- Current first supported implementation branch can be `organism_type=prokaryote` with `prediction_tool=prodigal`.
- Keep a parameter opening for later branches: `organism_type=prokaryote|eukaryote|bacteria|mixed`, `input_sequence_type=protein|nucleotide|auto`, and `prediction_tool=existing_faa|prodigal|metaeuk|genomad|auto`.
- Speaker-intended route to preserve unless asked to critique: mixed FASTA input uses `prodigal`; separated prokaryotic input uses `prodigal`; eukaryotic input uses `metaeuk`; bacterial input uses `genomad`.
- Because `prodigal` is effectively single-threaded and `eggnog` is memory-heavy, split FASTA at the start with `seqkit`.
- Keep each FASTA chunk under about `1G` before prediction and eggNOG annotation.
- Before giving an exact `seqkit` split command, verify the installed `seqkit split` / `seqkit split2` help text. Do not assume an option such as `-s 1G` means byte-size splitting unless the current version explicitly says so.
- Avoid recommending a large merge-then-split operation on Ceph/shared storage when file-list batching or direct per-file grouping can achieve the same goal with less I/O.
- For the user's current SMGC-derived workflow, rRNA detection is understood as `Barrnap` replacing the original SMGC `INFERNAL`/`cmsearch` step. Do not label current rRNA outputs as `INFERNAL` solely because the SMGC paper used `INFERNAL`, unless live files or scripts prove that legacy step is actually being used.

## Workflow Patterns

### SMGC Directory Interpretation Guardrails

When explaining the user's SMGC-derived MAG directories, avoid tool-name drift from the original paper into the user's current implementation.

- Treat `allporkmags` / `allprokmags`-like directories as aggregated prokaryotic MAG FASTA directories unless current scripts or logs prove a narrower role.
- Do not define such a directory as an `INFERNAL` result directory just because `.tblout`, `.cmsearch`, `rRNA_summary.csv`, or old step names are present.
- For the user's current implementation, rRNA detection should be interpreted as `Barrnap` replacing the original SMGC `INFERNAL`/`cmsearch` step.
- Treat tRNA evidence as belonging to `tRNAscan-SE` unless live evidence shows otherwise. Do not say abundant tRNA calls prove `cmsearch` succeeded.
- Do not recommend "fixing" or rerunning unfinished `cmsearch` work unless the user explicitly asks to revive the abandoned legacy INFERNAL branch.
- If legacy INFERNAL-like artifacts and current Barrnap outputs coexist, explain the ambiguity and resolve it from active scripts, logs, timestamps, and downstream consumers before advising.
- Do not label legacy INFERNAL-like outputs as "failed" solely because rRNA counts are zero. Say they are abandoned/legacy or not current unless logs prove actual failure.
- For functional annotation, point to protein FASTA from the gene-prediction step, usually `8_prodigal/faa/`, not raw MAG nucleotide `.fa`.
- Do not assume functional annotation output/input directories are named `02_function` or `02_function2`. Those names are examples from older notes, not a fixed convention.
- Absence of a directory named `02_function` is not evidence that functional annotation has not started. Search for marker outputs such as `eggNOG.emapper.annotations`, `*.seed_orthologs`, RGI outputs, VFDB/CAZy TSVs, logs, or current script variables.
- Do not state "functional annotation has not started" unless marker searches cover the user-confirmed project scope. If only selected locations were checked, say "not found in the checked locations" and name the uncertainty.
- Do not invent fixed new output roots such as `9_functional_annotation`. Use placeholders such as `$output_root`, `$function_dir`, and `$input_faa_dir` until the user confirms the layout.
- For advisory answers, give read-only validation commands first. Do not propose server-writing setup commands such as `mkdir`, `ln -s`, `cp`, or large `cat >` operations unless the user asked for implementation or confirmed the destination.

### Explain a Script

Identify:
- What environment it activates.
- Which samples it scans.
- Which input file it expects per sample.
- Which output proves completion.
- How it skips finished samples.
- How `.lock` avoids duplicate work.
- How database copies are assigned.
- How many jobs and threads it can consume.
- Where logs and temp files go.
- What happens on failure or interruption.

Name likely bugs directly, especially:
- Output existence is treated as completion without checking file integrity.
- Stale `.lock` files can block reruns after crash.
- Shared `temp_dir` can cause I/O pressure or collisions.
- `max_jobs * --cpu * host_count` may exceed practical CPU or I/O capacity.
- Ceph/network storage can bottleneck before CPU or RAM.
- Database version mismatches can make the same command fail on different hosts.
- Paths with trailing spaces in variable values can break query inputs.

### Triage Failed Samples

Use a narrow reproducible flow:
1. Count complete outputs.
2. Count locks.
3. Inspect newest logs.
4. Pick one failed sample.
5. Verify input file exists and is non-empty.
6. Verify no active process owns the sample or lock.
7. Inspect sample log tail for the decisive error.
8. Rerun one sample with controlled temp and log paths before expanding.

Safe stale-lock check:

```bash
lock="/path/to/sample/.lock"
sample="/path/to/sample"
cat "$lock"
ps -ef | grep -F "$sample" | grep -v grep
lsof +D "$sample" 2>/dev/null | head
stat "$lock"
```

Only propose `rm -f "$lock"` after process ownership is checked.

### Validate Completion

Do not treat existence alone as success. Prefer:

```bash
test -s "$sample/eggNOG.emapper.annotations"
head -n 1 "$sample/eggNOG.emapper.annotations"
tail -n 20 "$sample/eggnog_run.log"
grep -Ei "error|traceback|killed|no space|cannot|failed|exception" "$sample/eggnog_run.log"
```

For DIAMOND tabular output:

```bash
test -s result.tsv
awk 'NF < 12 {bad++} END {print "bad_rows=" bad+0}' result.tsv
head result.tsv
```

For RGI:

```bash
test -s RGI.txt
head -n 1 RGI.txt
grep -Ei "error|traceback|failed|exception" *.log 2>/dev/null
```

For Prodigal/protein FASTA completion, resolve contradictions before advising downstream annotation. If a report says some samples failed but the `.faa` count looks complete, verify:

```bash
find "$faa_dir" -type f -name "*.faa" -size +0c | wc -l
find "$faa_dir" -type f -name "*.faa" -size 0c | head
awk 'BEGIN{n=0} /^>/{n++} END{print FILENAME, n}' "$faa_dir"/*.faa 2>/dev/null | awk '$2==0'
comm -12 <(sed 's#.*/##; s/\.fa$//; s/\.fna$//' failed_from_log.lst | sort) <(find "$faa_dir" -type f -name "*.faa" -printf "%f\n" | sed 's/\.faa$//' | sort)
```

Then explain whether the failure list is stale, files are empty/partial, naming differs, or reruns completed after the log was written.

If only a subset such as dRep representative genomes was checked, phrase the conclusion narrowly: the representative set has corresponding `.faa` files. Still verify non-empty files and protein counts before treating them as ready for eggNOG/CARD/VFDB/CAZy.

For eggNOG completion, separate search completion from annotation completion:
- `*.emapper.hits` and `*.emapper.seed_orthologs` indicate the search/orthology stage produced intermediate evidence.
- `*.emapper.annotations` is the functional annotation output and can fail or be partial even when hits/seed files look good.
- If logs show `sqlite3.OperationalError: disk I/O error` or `database disk image is malformed` during annotation, treat existing annotations as suspect. Do not call the run successful based on non-empty annotation files.
- Before recommending a full rerun, check whether `*.emapper.seed_orthologs` is non-empty and has a reasonable row count. If so, prefer an annotation-only recovery using `emapper.py --annotate_hits_table ... --dbmem`.
- Write recovered annotations to a new output prefix or directory under the user-confirmed output root first; do not overwrite the failed annotations until the recovered outputs pass integrity checks.
- Do not infer search-stage failure only from a low `seed_orthologs / input proteins` percentage. `--dbmem` mainly protects the annotation SQLite reads, not MMseqs search. Recommend full search rerun only when search logs show errors, seed files are missing/empty, command parameters were wrong, or a comparable successful control proves the yield is abnormally low.
- When merging batch `*.emapper.annotations`, keep exactly one header and append only data rows matching `!/^#/`. Count annotation data with `grep -cv '^#'`, not `grep -cv '^##'`. Repeated `#query` headers in a merged file mean the merge is not clean.

### Infer Available Run Resources

Before recommending `max_jobs`, infer usable resources from the live server state, not only nominal hardware size.

Collect:

```bash
nproc
lscpu | egrep 'CPU\\(s\\)|Thread|Core|Socket|Model name'
free -h
df -h /tmp "$PWD" 2>/dev/null
iostat -xz 5 3
ps -eo pid,ppid,stat,pcpu,pmem,rss,etime,cmd | grep -E 'emapper|mmseqs|diamond|rgi|prodigal|genomad|barrnap' | grep -v grep
```

Reason from available capacity:
- Use `MemAvailable`, not total memory, as the memory starting point.
- Reserve memory for the OS, filesystem cache, shells, monitoring, and other users. If no better local value is known, keep at least 10-20 percent or 20-30G unallocated.
- Subtract active annotation jobs from the resource budget before suggesting new jobs.
- Compute memory-limited jobs, CPU-limited jobs, database-copy-limited jobs, and I/O-limited jobs separately; use the smallest result as the first safe parallelism.
- If CPU and memory look available but `%iowait` or device utilization is high, treat shared storage as the bottleneck and reduce `max_jobs`.
- If memory-limited parallelism is 1 or less, recommend one pilot job first. Do not suggest 2-3 concurrent jobs until observed RSS, `free`, and `iostat` show enough headroom.

Use this shape when explaining the inference:

```text
usable_ram = MemAvailable - reserved_ram
max_jobs_by_mem = floor(usable_ram / estimated_ram_per_job)
max_jobs_by_cpu = floor(usable_threads / cpu_per_job)
safe_max_jobs = min(max_jobs_by_mem, max_jobs_by_cpu, db_copy_count, io_limit)
```

State which value is the limiting factor. If live measurements are missing, say the estimate is based on the user's current heuristic and should be checked with `free`, `ps`, and `iostat`.

### Estimate Parallelism

Compute:

```text
total_threads = host_count * max_jobs * cpu_per_job
```

Use CPU thread count, RAM, database size, temp storage, and I/O wait together. If `wa` exceeds about 10 percent for sustained periods, reduce concurrent jobs or move database/temp files to faster local storage. If RAM is comfortable but processes stall, suspect I/O first.

For a 256-thread, 515-GB host, 8 jobs with `--cpu 24` is 192 nominal threads. CPU may be fine, but Ceph I/O can still be the limiting factor. Start with 4 jobs, observe `iostat`, then scale.

For the user's current eggNOG/database-heavy jobs, use this rough first-pass estimate unless live measurements contradict it: split FASTA to about `1G`; one 24-thread job against an approximately `40G` database can consume about `60G` memory, and should be budgeted as about `70G`; on an approximately `300G` server, start around 4 concurrent jobs because 4 * 70G is already close to the memory ceiling. If CPU and RAM look sufficient but jobs stall, suspect shared Ceph/cloud-disk I/O first.

Monitoring commands:

```bash
top
htop
iostat -xz 5
free -h
df -h
ps -eo pid,ppid,stat,pcpu,pmem,etime,cmd | grep -E 'emapper|mmseqs|diamond|rgi' | grep -v grep
```

### Long-Running Run Contract

When asked to start or repair a long eggNOG/MMseqs/DIAMOND/RGI run on a server, do not rely on ad hoc interactive commands. Build a resumable run plan first.

Required defaults:
- Write all generated scripts, inputs, temp files, PID files, logs, and results under the user-confirmed output root. If the user restricts writes to one directory, treat that as a hard boundary.
- Create or propose a saved runner script such as `$output_root/scripts/run_*.sh` before launching more than a pilot command.
- Launch long production runs in `screen` or `tmux` with session logging. `nohup ... &` is acceptable only for short pilots or monitor helpers, not as the only production run manager.
- Record a main run log, per-batch logs, PID files, and exit-code files. A zero-byte batch log is not evidence of progress.
- Give the user one copy-paste completion-count command for the current layout. If the run unit is chunked FASTA batches, label the count as completed batches; if the run unit is sample/MAG directories, label it as completed samples or MAGs.
- Print and store the exact command, host, PID, start time, input file, database copy, temp directory, and output prefix for each batch.
- Validate existing active processes before starting duplicate batches, especially on multi-host shared storage.
- Use targeted PID files for cleanup. Avoid broad `pkill -f emapper.py`, `pkill -f mmseqs`, or similar commands unless the user explicitly requests emergency cleanup and the scope has been verified.
- After launch, verify from the launching host that parent and child processes exist, and verify from the shared path that logs or temp files are changing.
- At completion, require result-file integrity checks and recorded exit code `0` before reporting success.

If a task is already running without `screen`, do not kill and restart only to improve bookkeeping. First check whether it is alive on the launching host, then monitor until completion unless there is a clear failure.

For MMseqs/eggNOG progress reports:
- Do not infer that a phase is permanently complete from memory dropping or a single process snapshot. MMseqs can run multiple sensitivity rounds with repeated `prefilter` and `align` child processes.
- State progress from current process command lines, temp-file changes, result files, and exit codes. If only intermediate processes are visible, say which stage appears active now rather than declaring the whole phase complete.
- Do not blame "Ceph delay" for missing logs or missing launches without filesystem or command evidence.
- For eggNOG runs on Ceph/shared storage, prefer `--dbmem` whenever memory allows because the annotation stage performs many SQLite reads from `eggnog.db`.
- If search outputs already exist, use `--annotate_hits_table` to recover annotation-stage failures rather than repeating MMseqs/DIAMOND search.
- After annotation-only recovery, compare recovered annotation rows to non-comment seed rows. A recovery rate around the seed rows with clean logs means the annotation failure was fixed; it does not by itself prove the original search should be rerun.

### Generate or Repair Batch Scripts

Prefer robust scripts with:
- `set -Eeuo pipefail` unless it conflicts with the user's shell behavior.
- Config block at the top.
- `find ... -mindepth 1 -maxdepth 1 -type d ! -name tmp | sort`.
- Per-sample input check.
- Output integrity check, not only existence check.
- Atomic lock creation with hostname, PID, timestamp, and command context.
- Per-sample temp directory when possible.
- Per-sample log.
- Cleanup trap that removes the lock for controlled exits.
- Database copy rotation derived from `db_start` and `db_count`.
- One-sample dry-run mode when risk is high.
- Main run log plus per-sample or per-batch logs.
- PID and exit-code files for every background job.
- Final validation summary that counts expected inputs, completed outputs, failed jobs, and nonzero exit codes.

For merged MAG/protein FASTA workflows:
- Do not blindly concatenate many `.faa` files if protein IDs are not globally unique.
- Before merging, inspect headers and test for duplicate first-token IDs.
- If IDs lack MAG/sample context, rewrite each protein ID to a globally unique derived ID and write a `protein_to_mag.tsv` mapping under the output root.
- Preserve the original `.faa` files; write rewritten or merged derived FASTA only under the user-confirmed output root.
- Treat duplicate first-token IDs in a merged multi-MAG/multi-sample FASTA as a stop condition, not a cosmetic warning. Do not launch eggNOG, CARD, VFDB, or CAZy on that ambiguous FASTA.
- If an ambiguous merged FASTA has already been annotated, do not call the result final for MAG/sample-level analysis. Report the affected duplicate count, rebuild a prefixed FASTA with a mapping table, split it, and rerun from search because query IDs changed.
- A MAG/sample prefix alone is insufficient when a single source `.faa` already has duplicate first-token IDs. Use a per-record or per-old-ID occurrence component such as `MAG|p000001|old_id`, then validate `duplicate_first_tokens=0` on the rewritten FASTA before launching annotation.

Do not hardcode a test sample, project accession, or host-specific path unless the user explicitly asks.

When the user asks for advice rather than direct implementation, separate read-only checks from write actions. Mark any directory creation, symlink farm, copy, concatenation, or job submission as a proposed next step requiring the user's confirmed output path and approval.

## Tool-Specific Notes

Load `references/workflow-notes.md` when you need details from the user's current meta-annotation workflow.

Load `references/templates.md` when you need reusable command blocks or a safer batch-script skeleton.

Load `references/database-guide.md` when the user asks what CAZy, eggNOG, CARD/RGI, or VFDB databases contain, what biological question each answers, or how to choose among annotations from multiple databases.

Load `references/tool-guide.md` when the user asks what DIAMOND, eggNOG/emapper, MMseqs, RGI, screen, conda, nohup, watch, or monitoring commands do in the workflow, or when explaining tool-specific inputs, outputs, and failure modes.

Load `references/tool-help.md` when you need exact CLI option names, long help text, install/version checks, or version-specific DIAMOND/RGI/eggNOG behavior.

Load `references/output-examples.md` when you need real output schemas, example rows, stale-lock logs, or runtime examples for comparison.

Load `references/smgc-2021-natmicrobiol.md` when the user asks about SMGC, skin metagenome catalogues, multi-kingdom skin microbiome workflows, MAG recovery/quality control, eukaryotic or viral branches in skin metagenomics, or how the SMGC 2021 Nature Microbiology paper should inform annotation design.

Use `scripts/check-meta-anno.sh` when asked to scan a sample directory for eggNOG completion, stale locks, or missing inputs:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/check-meta-anno.sh" /path/to/confirmed_function_dir
```

## Output Style

Be concise and technical. For script review, lead with defects and operational risks. For run guidance, give exact commands first. For failure diagnosis, name the most likely root cause and the single next command that would confirm or reject it.

If the user asks what the code does, explain the execution flow, resources consumed, generated outputs, and failure modes.

If the user asks how to run it, produce a minimal command sequence with environment activation, working directory, logging, monitoring, and post-run validation.

If the user asks why it failed, do not suggest broad retries first. Locate the earliest decisive error from logs, runtime state, and output integrity.
