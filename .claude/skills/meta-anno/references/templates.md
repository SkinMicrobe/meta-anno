# Meta-Anno Templates

Use these snippets as starting points. Adapt paths, conda envs, database ranges, and CPU counts to the user's current machine.

## Count Completed eggNOG Samples

```bash
find "$input_dir" -type f -name "eggNOG.emapper.annotations" \
  | xargs -r -n1 dirname \
  | sort -u \
  | wc -l
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
mkdir -p "$log_dir"
screen -L -Logfile "${log_dir}/eggnog_$(date +%F_%H%M).log" -S eggnog
conda activate smag_eggNOG
cd /path/to/workdir
bash ./run_eggnog_batch.sh
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

## Count Outputs Across Function Folders

```bash
find /mnt/cephfs/s2z2/SProject/02-meta/10-anno-mags/02_function \
  -type f -name "eggNOG.emapper.annotations" \
  | xargs -r -n1 dirname | sort -u | wc -l

find /mnt/cephfs/s2z2/SProject/02-meta/10-anno-mags/02_function2 \
  -type f -name "eggNOG.emapper.annotations" \
  | xargs -r -n1 dirname | sort -u | wc -l
```

## Recover A Suspect Ceph Mount

Only use this when the user intentionally wants to remount Ceph:

```bash
sudo umount -l /mnt/cephfs
sudo mount -a
```

## Safer eggNOG Batch Skeleton

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

input_dir="/mnt/cephfs/.../02_function"
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
