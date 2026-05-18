#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage:
  check-meta-anno.sh <sample-root> [output-name]

Scans one eggNOG sample root. Expected layout:
  <sample-root>/<sample>/<sample>.clean.faa
  <sample-root>/<sample>/eggNOG.emapper.annotations
  <sample-root>/<sample>/.lock
  <sample-root>/<sample>/eggnog_run.log

Output columns:
  sample_dir status input output_bytes lock log_issue
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

root="$1"
output_name="${2:-eggNOG.emapper.annotations}"

if [[ ! -d "$root" ]]; then
  echo "ERROR: not a directory: $root" >&2
  exit 2
fi

printf 'sample_dir\tstatus\tinput\toutput_bytes\tlock\tlog_issue\n'

find "$root" -mindepth 1 -maxdepth 1 -type d ! -name "tmp" | sort | while IFS= read -r sample_dir; do
  sample="$(basename "$sample_dir")"
  faa_file="${sample_dir}/${sample}.clean.faa"
  output_file="${sample_dir}/${output_name}"
  lock_file="${sample_dir}/.lock"
  log_file="${sample_dir}/eggnog_run.log"

  input_state="missing"
  [[ -s "$faa_file" ]] && input_state="ok"

  output_bytes=0
  if [[ -f "$output_file" ]]; then
    output_bytes="$(wc -c < "$output_file" | tr -d ' ')"
  fi

  lock_state="none"
  if [[ -f "$lock_file" ]]; then
    lock_state="$(tr '\n' ';' < "$lock_file" | sed 's/[[:space:]]\+/ /g')"
    [[ -z "$lock_state" ]] && lock_state="present"
  fi

  log_issue="none"
  if [[ -f "$log_file" ]]; then
    if grep -qiE 'traceback|error|killed|no space|cannot|failed|exception|permission denied' "$log_file"; then
      log_issue="error_pattern"
    fi
  else
    log_issue="no_log"
  fi

  status="pending"
  if [[ "$input_state" != "ok" ]]; then
    status="missing_input"
  elif [[ -s "$output_file" ]] && head -n 1 "$output_file" | grep -q '^#'; then
    status="complete"
  elif [[ "$lock_state" != "none" ]]; then
    status="locked"
  elif [[ -f "$output_file" ]]; then
    status="partial_output"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$sample_dir" "$status" "$input_state" "$output_bytes" "$lock_state" "$log_issue"
done
