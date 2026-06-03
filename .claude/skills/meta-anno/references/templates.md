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

## Start A Detached Monitor

```bash
cd /mnt/cephfs/s2z5/skin/00-data
nohup bash monitor_emapper.sh > monitor_emapper.nohup.log 2>&1 &
```

## Monitor Processes And I/O

```bash
ps -eo pid,ppid,stat,pcpu,pmem,etime,cmd | grep -E 'emapper|mmseqs|diamond|rgi' | grep -v grep
iostat -xz 5
free -h
df -h
```

Use `watch` only interactively:

```bash
watch "ps aux | grep -E 'emapper|mmseqs|diamond|rgi' | grep -v grep"
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
