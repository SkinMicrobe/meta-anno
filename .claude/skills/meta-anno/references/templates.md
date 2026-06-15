# Meta-Anno Templates

Use these snippets as starting points. Adapt paths, conda envs, database ranges, and CPU counts to the user's current machine.

## Count Completed eggNOG Samples

```bash
find "$input_dir" -type f -name "eggNOG.emapper.annotations" \
  | xargs -r -n1 dirname \
  | sort -u \
  | wc -l
```

For sample/MAG-directory layouts, give the user a single copy-paste command that reports completed and expected units:

```bash
input_dir="/path/to/sample_or_mag_dirs"
expected=$(find "$input_dir" -mindepth 1 -maxdepth 1 -type d ! -name tmp | wc -l)
complete=$(find "$input_dir" -mindepth 2 -maxdepth 2 -type f -name "eggNOG.emapper.annotations" -size +0c | xargs -r -n1 dirname | sort -u | wc -l)
printf 'completed_samples=%s/%s\n' "$complete" "$expected"
```

For chunked FASTA batch layouts, do not call the chunks samples:

```bash
output_root="/path/to/output_root"
expected=$(find "$output_root/merged_faa/batches" -maxdepth 1 -type f -name "*.faa" 2>/dev/null | wc -l)
complete=$(find "$output_root/results" -maxdepth 1 -type f -name "*.emapper.annotations" -size +0c 2>/dev/null | wc -l)
running=$(ps -eo cmd | grep -F "$output_root" | grep -E 'emapper.py|mmseqs|diamond|rgi' | grep -v grep | wc -l)
printf 'completed_batches=%s/%s running_process_lines=%s\n' "$complete" "$expected" "$running"
```

## Find Locked Samples

```bash
find "$input_dir" -mindepth 2 -maxdepth 2 -name ".lock" -type f -print \
  | sort
```

## Inspect Newest Logs

```bash
ls -lt "$log_dir"/*.log 2>/dev/null | head
tail -n 80 "$sample_dir/eggnog_run.log"
grep -RInE "error|traceback|killed|no space|cannot|failed|exception|permission" "$sample_dir" "$log_dir" 2>/dev/null | head -n 50
```

## Start A Long Run In Screen

```bash
output_root="/path/to/user-confirmed/output_root"
run_name="eggnog_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$output_root"/{scripts,logs,pids,exit_codes,tmp,results}

# Start an attached session with full terminal capture.
screen -L -Logfile "$output_root/logs/screen_${run_name}.log" -S "$run_name"

# Inside screen:
source /home/compute2/miniconda3/etc/profile.d/conda.sh 2>/dev/null || true
conda activate smag
cd /path/to/workdir
bash "$output_root/scripts/run_eggnog.sh" 2>&1 | tee -a "$output_root/logs/run_${run_name}.log"
```

For an already launched `nohup` run, do not restart only to add `screen`. Attach a monitor session instead:

```bash
screen -L -Logfile "$output_root/logs/monitor_$(date +%Y%m%d_%H%M%S).log" -S monitor_eggnog
watch -n 30 '
date
ps -eo pid,ppid,stat,pcpu,pmem,rss,etime,cmd | grep -E "emapper|mmseqs|diamond|rgi" | grep -v grep
echo
ls -lh "'"$output_root"'/logs/"
echo
find "'"$output_root"'/results" -maxdepth 2 -type f | wc -l
'
```

For split-host contig scripts:

```bash
export HOST_INDEX=0   # even-index work in the user's C2/C4 split notes
bash ./smart_annotation_C2.sh

export HOST_INDEX=1   # odd-index work in the user's C2/C4 split notes
bash ./smart_annotation_C4.sh
```

## Generic Multi-Server Shared-Path Split

Use this pattern only when the user explicitly requests multi-server execution or confirms a participating server list. If the user does not ask for multiple servers, use the current server only.

When C2/C4 or any other set of servers share the same Ceph path and should split the same input set, set the same user-confirmed `HOST_COUNT` on every server and a different zero-based `HOST_INDEX` on each server.

Examples: for 3 servers use `HOST_COUNT=3` with `HOST_INDEX=0`, `1`, and `2`; for 4 servers use `HOST_COUNT=4` with `HOST_INDEX=0`, `1`, `2`, and `3`.

```bash
output_root="/path/to/user-confirmed/output_root"
input_dir="/path/to/input_units"
HOST_COUNT="${HOST_COUNT:?set total number of servers, for example 2, 3, or 4}"
HOST_INDEX="${HOST_INDEX:?set this server index from 0 to HOST_COUNT-1}"

mkdir -p "$output_root"/{manifests,logs,pids,exit_codes,tmp}

find "$input_dir" -mindepth 1 -maxdepth 1 -type d ! -name tmp | sort \
  | awk -v host_index="$HOST_INDEX" -v host_count="$HOST_COUNT" '
      ((NR - 1) % host_count) == host_index { print }
    ' > "$output_root/manifests/units_host_${HOST_INDEX}_of_${HOST_COUNT}.txt"

printf 'host=%s host_index=%s host_count=%s assigned_units=%s\n' \
  "$(hostname)" "$HOST_INDEX" "$HOST_COUNT" \
  "$(wc -l < "$output_root/manifests/units_host_${HOST_INDEX}_of_${HOST_COUNT}.txt")" \
  | tee "$output_root/logs/host_${HOST_INDEX}_assignment.log"
```

For FASTA chunk files instead of sample directories, change the `find` command:

```bash
find "$batch_dir" -maxdepth 1 -type f \( -name "*.faa" -o -name "*.fa" -o -name "*.fna" -o -name "*.fasta" \) | sort \
  | awk -v host_index="$HOST_INDEX" -v host_count="$HOST_COUNT" '
      ((NR - 1) % host_count) == host_index { print }
    ' > "$output_root/manifests/batches_host_${HOST_INDEX}_of_${HOST_COUNT}.txt"
```

Each server should launch from its own `screen`/`tmux` session and write a separate monitor log:

```bash
screen -L -Logfile "$output_root/logs/screen_host_${HOST_INDEX}_$(date +%Y%m%d_%H%M%S).log" \
  -S "anno_h${HOST_INDEX}"
```

## Start A Detached Monitor

```bash
cd /mnt/cephfs/s2z5/skin/00-data
nohup bash monitor_emapper.sh > monitor_emapper.nohup.log 2>&1 &
```

## Monitor Processes And I/O

```bash
ps -eo pid,ppid,stat,pcpu,pmem,rss,etime,cmd | grep -Ei 'emapper|mmseqs|diamond|rgi|prodigal|genomad|metaeuk' | grep -v grep
iostat -xz 5
free -h
df -h
```

Use `watch` only interactively:

```bash
watch "ps aux | grep -Ei 'emapper|mmseqs|diamond|rgi|prodigal|genomad|metaeuk' | grep -v grep"
```

## Estimate Batches From Input Files

Use this before deciding `max_jobs` or writing a production runner. For contigs/nucleotide FASTA, split oversized files before prediction.

```bash
input_dir="/path/to/input_fastas"
target_batch_gb=1
target_batch_bytes=$((target_batch_gb * 1024 * 1024 * 1024))
mkdir -p "$output_root"/{logs,manifests}

find "$input_dir" -maxdepth 1 -type f \
  \( -name "*.fa" -o -name "*.fna" -o -name "*.fasta" -o -name "*.faa" \) \
  -printf '%s\t%p\n' \
  | sort -nr > "$output_root/manifests/input_sizes.tsv"

awk -v target="$target_batch_bytes" '
  { n++; sum += $1; if ($1 > max) max = $1 }
  END {
    batches = int((sum + target - 1) / target)
    printf "input_count=%d\n", n
    printf "total_GB=%.3f\n", sum/1024/1024/1024
    printf "largest_GB=%.3f\n", max/1024/1024/1024
    printf "target_batch_GB=%.3f\n", target/1024/1024/1024
    printf "expected_batches=%d\n", batches
  }
' "$output_root/manifests/input_sizes.tsv" | tee "$output_root/logs/input_batch_estimate.txt"
```

If one file is larger than the target batch size, split that file first and rerun the estimate on the split pieces.

## Mixed Contig Bucket Labels

For mixed contigs, keep branch labels explicit. `unclassified` uses Prodigal as a handling rule, but must not be renamed as bacteria.

```bash
bucket="unclassified"
prediction_tool="prodigal"
output_bucket="unclassified_prodigal"
```

If a required tool is missing, install or fix the environment for that tool. Do not substitute another prediction tool automatically.

## Continuous Resource Monitor

Run this in a separate `screen`/`tmux` session or as a lightweight detached helper during production jobs. It records CPU, memory, disk space, and read/write I/O repeatedly.

```bash
output_root="/path/to/user-confirmed/output_root"
mkdir -p "$output_root/logs"

while true; do
  echo "===== $(date -Is) ====="
  hostname
  free -h
  df -h /tmp "$PWD" 2>/dev/null
  ps -eo pid,ppid,stat,pcpu,pmem,rss,etime,cmd \
    | grep -Ei 'emapper|mmseqs|diamond|rgi|prodigal|genomad|metaeuk' \
    | grep -v grep || true
  iostat -xz 5 2
  sleep 60
done >> "$output_root/logs/resource_monitor.log" 2>&1
```

## Build DIAMOND Databases

```bash
diamond makedb \
  --in /mnt/cephfs/s2z1/db/CAZy/CAZy-V14.fa \
  -d /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/localDB/CAZyme_db
```

```bash
diamond makedb \
  --in /mnt/cephfs/s2z1/db/VFDB2025/VFDB_setB_pro.fas \
  -d /path/to/VFDB_setB
```

For the fungi virulence-factor branch, use FungAMR rather than bacterial VFDB. Preserve the original database FASTA and create any cleaned/indexed database under the user-confirmed output root:

```bash
fungamr_source="/path/to/FungAMR/FungAMR.fasta"
input_faa="/path/to/metaeuk/fungi_proteins.faa"
output_root="/path/to/confirmed/output_root"
db_work="$output_root/databases/fungamr"
results_dir="$output_root/results"

mkdir -p "$db_work" "$results_dir"

awk '
  /^##/ {next}
  /^>/ {
    gsub(/ \| /, "|", $0)
    gsub(/ /, "_", $0)
  }
  {print}
' "$fungamr_source" > "$db_work/FungAMR.clean.fasta"

diamond makedb \
  --in "$db_work/FungAMR.clean.fasta" \
  --db "$db_work/FungAMR"

input_name=$(basename "$input_faa")
input_stem="${input_name%.*}"

diamond blastp \
  --db "$db_work/FungAMR.dmnd" \
  --query "$input_faa" \
  --out "$results_dir/${input_stem}.fungamr.tsv" \
  --outfmt 6 \
  --evalue 1e-5 \
  --max-target-seqs 1 \
  --threads 24
```

## Count Outputs Across Confirmed Function Folders

Do not assume the user's functional annotation folders are named `02_function` or `02_function2`. Set these variables from the current project layout or user-provided paths first.

```bash
function_dir_a="/path/to/confirmed/function_dir_a"
function_dir_b="/path/to/confirmed/function_dir_b"

find "$function_dir_a" \
  -type f -name "eggNOG.emapper.annotations" \
  | xargs -r -n1 dirname | sort -u | wc -l

find "$function_dir_b" \
  -type f -name "eggNOG.emapper.annotations" \
  | xargs -r -n1 dirname | sort -u | wc -l
```

## Build A Prefixed Multi-MAG Protein FASTA

Use this pattern when a target genome/MAG list identifies the analysis set and existing Prodigal `.faa` files provide proteins. dRep representatives are one common case, but the rule applies to any multi-MAG or multi-sample merge. It keeps all derived files under `$output_root` and rewrites protein IDs to globally unique first tokens.

```bash
workdir="/mnt/cephfs/.../SMGC"
target_genome_dir="$workdir/6_dRep2_step2/dereplicated_genomes"
faa_dir="$workdir/8_prodigal/faa"
output_root="$workdir/test"
target_name="target_mags"

mkdir -p "$output_root"/{merged_faa,logs}

comm -12 \
  <(find "$target_genome_dir" -maxdepth 1 -type f -name "*.fa" -printf "%f\n" | sed 's/\.fa$//' | sort) \
  <(find "$faa_dir" -maxdepth 1 -type f -name "*.faa" -printf "%f\n" | sed 's/\.faa$//' | sort) \
  > "$output_root/merged_faa/${target_name}_faa_basenames.txt"

expected=$(wc -l < "$output_root/merged_faa/${target_name}_faa_basenames.txt")
echo "matched_target_faa=$expected"

: > "$output_root/merged_faa/protein_to_mag.tsv"
awk '
  FNR==1 {
    mag=FILENAME
    sub(/^.*\//, "", mag)
    sub(/\.faa$/, "", mag)
    rec=0
  }
  /^>/ {
    old=$1
    sub(/^>/, "", old)
    rec++
    new=mag "|p" sprintf("%06d", rec) "|" old
    print new "\t" mag "\t" old "\t" rec >> map
    sub(/^>[^ ]+/, ">" new)
  }
  { print }
' map="$output_root/merged_faa/protein_to_mag.tsv" \
  $(sed "s#^#$faa_dir/#; s#$#.faa#" "$output_root/merged_faa/${target_name}_faa_basenames.txt") \
  > "$output_root/merged_faa/${target_name}.prefixed.faa"

grep -c '^>' "$output_root/merged_faa/${target_name}.prefixed.faa"
awk '/^>/{id=substr($1,2); c[id]++} END{dup=0; for (i in c) if(c[i]>1) dup++; print "duplicate_first_tokens=" dup, "unique_ids=" length(c); exit (dup>0)}' \
  "$output_root/merged_faa/${target_name}.prefixed.faa"
```

The per-record component is required because some Prodigal `.faa` files can already contain duplicate first-token IDs within one MAG; a `MAG|old_id` prefix alone does not fix those internal duplicates.

Before running annotation on an already merged FASTA, reject ambiguous IDs:

```bash
input_faa="$output_root/merged_faa/${target_name}.prefixed.faa"
seqs=$(grep -c '^>' "$input_faa")
unique=$(awk '/^>/{id=substr($1,2); print id}' "$input_faa" | sort -u | wc -l)
dups=$(awk '/^>/{id=substr($1,2); print id}' "$input_faa" | sort | uniq -d | wc -l)
printf 'seqs=%s unique_first_tokens=%s duplicate_first_tokens=%s\n' "$seqs" "$unique" "$dups"
test "$dups" -eq 0
```

## Merge eggNOG Annotation Batches Safely

Do not merge batch annotations by removing only `##` comment lines. That leaves repeated `#query` headers and makes row counts wrong. Keep one header from the first file and append only data rows:

```bash
results_dir="$output_root/results_v2"
merged="$results_dir/all_derep.emapper.annotations"

first=$(find "$results_dir" -maxdepth 1 -type f -name "batch_*.emapper.annotations" | sort | head -n 1)
grep '^#query' "$first" | head -n 1 > "$merged"
awk '!/^#/' "$results_dir"/batch_*.emapper.annotations >> "$merged"

printf 'total_lines='; wc -l < "$merged"
printf 'data_rows='; grep -cv '^#' "$merged"
printf 'query_header_lines='; grep -c '^#query' "$merged"
printf 'duplicate_query_ids='; awk '!/^#/ {print $1}' "$merged" | sort | uniq -d | wc -l
```

If `query_header_lines` is not `1`, or `duplicate_query_ids` is nonzero in a multi-MAG merge, report the problem before treating the table as final.

## Convert Annotation Tables To CSV

Preserve original annotation files and write CSV copies as derived outputs. Use a parser, not blind tab-to-comma replacement.

For a validated eggNOG `*.emapper.annotations` file produced from one source FASTA, derive the output name from that FASTA. Do not call it `all_annotations.csv` or `all.emapper.annotations.csv`:

```bash
input_faa="/path/to/sample_001.faa"
input_name=$(basename "$input_faa")
input_stem="${input_name%.*}"
annotation_tsv="$output_root/results/${input_stem}.emapper.annotations"
annotation_csv="$output_root/results/${input_stem}.eggnog.annotations.csv"

python - "$annotation_tsv" "$annotation_csv" <<'PY'
import csv
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

header = None
rows = 0

with src.open("r", encoding="utf-8", errors="replace", newline="") as fin, \
     dst.open("w", encoding="utf-8", newline="") as fout:
    writer = csv.writer(fout)
    for line in fin:
        line = line.rstrip("\n")
        if not line:
            continue
        if line.startswith("#query"):
            if header is None:
                header = line.lstrip("#").split("\t")
                writer.writerow(header)
            continue
        if line.startswith("#"):
            continue
        writer.writerow(line.split("\t"))
        rows += 1

if header is None:
    raise SystemExit(f"missing #query header in {src}")
if rows == 0:
    raise SystemExit(f"no annotation data rows in {src}")
print(f"csv_rows={rows} csv={dst}")
PY
```

For DIAMOND outfmt 6 TSV, write the known columns before converting:

```bash
input_faa="/path/to/sample_001.faa"
input_name=$(basename "$input_faa")
input_stem="${input_name%.*}"
diamond_tsv="$output_root/results/${input_stem}.vfdb.tsv"
diamond_csv="$output_root/results/${input_stem}.vfdb.csv"

python - "$diamond_tsv" "$diamond_csv" <<'PY'
import csv
import sys
from pathlib import Path

cols = ["qseqid","sseqid","pident","length","mismatch","gapopen","qstart","qend","sstart","send","evalue","bitscore"]
src = Path(sys.argv[1])
dst = Path(sys.argv[2])

with src.open("r", encoding="utf-8", errors="replace", newline="") as fin, \
     dst.open("w", encoding="utf-8", newline="") as fout:
    writer = csv.writer(fout)
    writer.writerow(cols)
    for line in fin:
        line = line.rstrip("\n")
        if line:
            writer.writerow(line.split("\t"))
PY
```

## Recover A Suspect Ceph Mount

Only use this when the user intentionally wants to remount Ceph:

```bash
sudo umount -l /mnt/cephfs
sudo mount -a
```

## Safer eggNOG Batch Skeleton

For chunked FASTA inputs such as `batch_001.faa`, prefer a saved runner with main log, per-batch log, PID files, and exit codes:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

workdir="/mnt/cephfs/.../SMGC"
output_root="$workdir/test"
batch_dir="$output_root/merged_faa/batches"
db_base="/mnt/cephfs/s2z5/skin/00-data/8_eggNOG/eggnog_db_copy_"
db_start=1
cpu_per_job=24
max_jobs=4

mkdir -p "$output_root"/{logs,pids,exit_codes,results,tmp,scripts}
run_log="$output_root/logs/run_eggnog_$(date +%Y%m%d_%H%M%S).log"

log() {
  printf '[%s] %s\n' "$(date -Is)" "$*" | tee -a "$run_log"
}

run_batch() {
  local batch_file="$1"
  local index="$2"
  local batch db_index db_dir temp_dir log_file pid_file exit_file output_prefix

  batch="$(basename "$batch_file" .faa)"
  db_index=$((db_start + index - 1))
  db_dir="${db_base}${db_index}"
  temp_dir="$output_root/tmp/${batch}"
  log_file="$output_root/logs/${batch}.log"
  pid_file="$output_root/pids/${batch}.pid"
  exit_file="$output_root/exit_codes/${batch}.exit"
  output_prefix="$output_root/results/${batch}"

  mkdir -p "$temp_dir"
  rm -f "$exit_file"

  (
    set +e
    echo "START $(date -Is)"
    echo "host=$(hostname)"
    echo "batch_file=$batch_file"
    echo "db_dir=$db_dir"
    echo "temp_dir=$temp_dir"
    echo "output_prefix=$output_prefix"
    emapper.py -i "$batch_file" \
      -o "$output_prefix" \
      --data_dir "$db_dir" \
      --temp_dir "$temp_dir" \
      -m mmseqs \
      --dbmem \
      --cpu "$cpu_per_job" \
      --override
    rc=$?
    echo "$rc" > "$exit_file"
    echo "EXIT_CODE=$rc"
    echo "END $(date -Is)"
    exit "$rc"
  ) > "$log_file" 2>&1 &

  LAST_PID=$!
  echo "$LAST_PID" > "$pid_file"
  log "STARTED batch=$batch pid=$LAST_PID db=$db_dir log=$log_file"
}

active=()
index=0

while IFS= read -r batch_file; do
  index=$((index + 1))
  run_batch "$batch_file" "$index"
  active+=("$LAST_PID")

  if (( ${#active[@]} >= max_jobs )); then
    for pid in "${active[@]}"; do
      wait "$pid" || true
    done
    active=()
  fi
done < <(find "$batch_dir" -maxdepth 1 -type f -name "*.faa" | sort)

for pid in "${active[@]}"; do
  wait "$pid" || true
done

log "All submitted batches exited; validating."
find "$output_root/exit_codes" -type f -name "*.exit" -print -exec cat {} \; | tee -a "$run_log"
find "$output_root/results" -maxdepth 1 -type f -name "*.emapper.annotations" -size +0c -printf '%s %p\n' | tee -a "$run_log"
grep -RInE "error|traceback|killed|no space|cannot|failed|exception|permission" "$output_root/logs" 2>/dev/null | tee -a "$run_log" || true
```

Launch it from `screen`, not as a bare `nohup` production run.

## Recover eggNOG Annotation From Existing Seed Orthologs

Use this when MMseqs/DIAMOND search completed but annotation failed or is partial, especially with SQLite errors such as `disk I/O error` or `database disk image is malformed`. This reuses `*.emapper.seed_orthologs` and avoids rerunning the expensive search stage.

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

output_root="/mnt/cephfs/.../SMGC/test"
old_results="$output_root/results"
new_results="$output_root/results_reannot_dbmem"
db_base="/mnt/cephfs/s2z5/skin/00-data/8_eggNOG/eggnog_db_copy_"
db_start=1
db_count=4
cpu_per_job=8
max_jobs=2

mkdir -p "$output_root"/{logs,pids,exit_codes,tmp_annot,scripts} "$new_results"
run_log="$output_root/logs/reannot_$(date +%Y%m%d_%H%M%S).log"

log() {
  printf '[%s] %s\n' "$(date -Is)" "$*" | tee -a "$run_log"
}

run_annot() {
  local seed_file="$1"
  local index="$2"
  local batch db_index db_dir temp_dir log_file pid_file exit_file output_prefix

  batch="$(basename "$seed_file" .emapper.seed_orthologs)"
  db_index=$((db_start + ((index - 1) % db_count) ))
  db_dir="${db_base}${db_index}"
  temp_dir="$output_root/tmp_annot/${batch}"
  log_file="$output_root/logs/${batch}.reannot.log"
  pid_file="$output_root/pids/${batch}.reannot.pid"
  exit_file="$output_root/exit_codes/${batch}.reannot.exit"
  output_prefix="$new_results/${batch}"

  mkdir -p "$temp_dir"
  rm -f "$exit_file"

  (
    set +e
    echo "START $(date -Is)"
    echo "host=$(hostname)"
    echo "seed_file=$seed_file"
    echo "db_dir=$db_dir"
    echo "temp_dir=$temp_dir"
    echo "output_prefix=$output_prefix"
    emapper.py \
      --annotate_hits_table "$seed_file" \
      --data_dir "$db_dir" \
      --temp_dir "$temp_dir" \
      --dbmem \
      --cpu "$cpu_per_job" \
      --no_file_comments \
      --override \
      -o "$output_prefix"
    rc=$?
    echo "$rc" > "$exit_file"
    echo "EXIT_CODE=$rc"
    echo "END $(date -Is)"
    exit "$rc"
  ) > "$log_file" 2>&1 &

  LAST_PID=$!
  echo "$LAST_PID" > "$pid_file"
  log "STARTED reannot batch=$batch pid=$LAST_PID db=$db_dir log=$log_file"
}

active=()
index=0

while IFS= read -r seed_file; do
  index=$((index + 1))
  run_annot "$seed_file" "$index"
  active+=("$LAST_PID")

  if (( ${#active[@]} >= max_jobs )); then
    for pid in "${active[@]}"; do
      wait "$pid" || true
    done
    active=()
  fi
done < <(find "$old_results" -maxdepth 1 -type f -name "*.emapper.seed_orthologs" -size +0c | sort)

for pid in "${active[@]}"; do
  wait "$pid" || true
done

log "Annotation-only recovery exited; validating."
for f in "$new_results"/*.emapper.annotations; do
  [ -e "$f" ] || continue
  printf '%s\t%s\n' "$(grep -vc '^#' "$f" 2>/dev/null || echo 0)" "$f" | tee -a "$run_log"
done
grep -HnE "sqlite3|disk I/O error|database disk image is malformed|traceback|exception|failed" "$output_root"/logs/*.reannot.log 2>/dev/null | tee -a "$run_log" || true
```

Launch it from `screen` and keep failed original outputs until the recovered annotations are validated:

```bash
screen -L -Logfile "$output_root/logs/screen_reannot_$(date +%Y%m%d_%H%M%S).log" -S reannot_eggnog
bash "$output_root/scripts/reannot_from_seed.sh" 2>&1 | tee -a "$output_root/logs/reannot_screen_driver.log"
```

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

input_dir="/path/to/confirmed/function_input_dir"
db_base="/mnt/cephfs/.../eggnog_db_copy_"
db_start=1
db_count=4
temp_root="${input_dir}/tmp"
log_dir="/mnt/cephfs/.../logs"
max_jobs=4
cpu_per_job=16
output_name="eggNOG.emapper.annotations"

mkdir -p "$temp_root" "$log_dir"
ulimit -n 500000 || true

is_complete() {
  local sample_dir="$1"
  local output_file="${sample_dir}/${output_name}"
  [[ -s "$output_file" ]] && head -n 1 "$output_file" | grep -q '^#'
}

run_one() {
  local sample_dir="$1"
  local db_dir="$2"
  local sample
  sample="$(basename "$sample_dir")"

  local faa_file="${sample_dir}/${sample}.clean.faa"
  local lock_file="${sample_dir}/.lock"
  local temp_dir="${temp_root}/${sample}"
  local log_file="${sample_dir}/eggnog_run.log"

  if [[ ! -s "$faa_file" ]]; then
    echo "MISSING_INPUT	${sample_dir}	${faa_file}"
    return 0
  fi

  if is_complete "$sample_dir"; then
    echo "DONE	${sample_dir}"
    return 0
  fi

  if [[ -f "$lock_file" ]]; then
    echo "LOCKED	${sample_dir}	$(cat "$lock_file" 2>/dev/null)"
    return 0
  fi

  (
    set -o noclobber
    printf 'host=%s\npid=%s\ntime=%s\nsample=%s\n' \
      "${HOSTNAME:-unknown}" "$$" "$(date -Is)" "$sample_dir" > "$lock_file"
  ) 2>/dev/null || {
    echo "LOCK_RACE	${sample_dir}"
    return 0
  }

  mkdir -p "$temp_dir"

  (
    trap 'rm -f "$lock_file"' EXIT
    echo "START	$(date -Is)	${sample}	${db_dir}"
    emapper.py -i "$faa_file" \
      --data_dir "$db_dir" \
      --output_dir "$sample_dir" \
      --temp_dir "$temp_dir" \
      -m mmseqs --dbmem --cpu "$cpu_per_job" \
      -o "eggNOG" --override
    is_complete "$sample_dir"
    echo "DONE	$(date -Is)	${sample}"
  ) > "$log_file" 2>&1
}

job_index=0
active=0

while IFS= read -r sample_dir; do
  db_index=$(( db_start + (job_index % db_count) ))
  db_dir="${db_base}${db_index}"

  run_one "$sample_dir" "$db_dir" &

  job_index=$((job_index + 1))
  active=$((active + 1))
  if (( active >= max_jobs )); then
    wait
    active=0
  fi
done < <(find "$input_dir" -mindepth 1 -maxdepth 1 -type d ! -name "tmp" | sort)

wait
echo "ALL_DONE	$(date -Is)"
```

## One-Sample Reproduction

```bash
sample_dir="/path/to/sample"
sample="$(basename "$sample_dir")"
faa_file="${sample_dir}/${sample}.clean.faa"
db_dir="/path/to/eggnog_db_copy_1"
temp_dir="${sample_dir}/tmp_single"

mkdir -p "$temp_dir"
emapper.py -i "$faa_file" \
  --data_dir "$db_dir" \
  --output_dir "$sample_dir" \
  --temp_dir "$temp_dir" \
  -m mmseqs --dbmem --cpu 16 \
  -o "eggNOG" --override \
  > "${sample_dir}/eggnog_single_repro.log" 2>&1

tail -n 80 "${sample_dir}/eggnog_single_repro.log"
```
