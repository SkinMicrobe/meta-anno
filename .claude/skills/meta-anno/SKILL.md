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
| Input | `input_dir`, `faa_file`, expected `*.clean.faa`, raw `.faa`, or sample directory layout |
| Database | `db`, `db_path`, `db_base`, database copy range, CARD path, eggNOG data dir |
| Output | expected result file, output directory, log path, temp path |
| Tool | `diamond blastp`, `emapper.py`, `rgi main`, or wrapper script |
| Parallelism | `max_jobs`, per-job `--cpu`, total threads, host count |
| Coordination | `.lock` behavior, host split rule, database copy assignment |
| Failure signal | missing output, small output, stale lock, traceback, killed process, I/O wait, no space |

Then answer in this order when it fits:
1. Outcome.
2. Key evidence.
3. Verification commands.
4. Next safe action.

## Workflow Patterns

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

### Estimate Parallelism

Compute:

```text
total_threads = host_count * max_jobs * cpu_per_job
```

Use CPU thread count, RAM, database size, temp storage, and I/O wait together. If `wa` exceeds about 10 percent for sustained periods, reduce concurrent jobs or move database/temp files to faster local storage. If RAM is comfortable but processes stall, suspect I/O first.

For a 256-thread, 515-GB host, 8 jobs with `--cpu 24` is 192 nominal threads. CPU may be fine, but Ceph I/O can still be the limiting factor. Start with 4 jobs, observe `iostat`, then scale.

Monitoring commands:

```bash
top
htop
iostat -xz 5
free -h
df -h
ps -eo pid,ppid,stat,pcpu,pmem,etime,cmd | grep -E 'emapper|mmseqs|diamond|rgi' | grep -v grep
```

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

Do not hardcode a test sample, project accession, or host-specific path unless the user explicitly asks.

## Tool-Specific Notes

Load `references/workflow-notes.md` when you need details from the user's current meta-annotation workflow.

Load `references/templates.md` when you need reusable command blocks or a safer batch-script skeleton.

Load `references/database-guide.md` when the user asks what CAZy, eggNOG, CARD/RGI, or VFDB databases contain, what biological question each answers, or how to choose among annotations from multiple databases.

Load `references/tool-guide.md` when the user asks what DIAMOND, eggNOG/emapper, MMseqs, RGI, screen, conda, nohup, watch, or monitoring commands do in the workflow, or when explaining tool-specific inputs, outputs, and failure modes.

Load `references/tool-help.md` when you need exact CLI option names, long help text, install/version checks, or version-specific DIAMOND/RGI/eggNOG behavior.

Load `references/output-examples.md` when you need real output schemas, example rows, stale-lock logs, or runtime examples for comparison.

Use `scripts/check-meta-anno.sh` when asked to scan a sample directory for eggNOG completion, stale locks, or missing inputs:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/check-meta-anno.sh" /path/to/02_function
```

## Output Style

Be concise and technical. For script review, lead with defects and operational risks. For run guidance, give exact commands first. For failure diagnosis, name the most likely root cause and the single next command that would confirm or reject it.

If the user asks what the code does, explain the execution flow, resources consumed, generated outputs, and failure modes.

If the user asks how to run it, produce a minimal command sequence with environment activation, working directory, logging, monitoring, and post-run validation.

If the user asks why it failed, do not suggest broad retries first. Locate the earliest decisive error from logs, runtime state, and output integrity.
