#!/usr/bin/env bash
set -Eeuo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_dir="${project_root}/.claude/skills/meta-anno"

if [[ ! -f "${source_dir}/SKILL.md" ]]; then
  echo "Skill source not found: ${source_dir}" >&2
  exit 2
fi

skills_root="${HOME}/.claude/skills"
target="${skills_root}/meta-anno"

mkdir -p "$skills_root"

if [[ -e "$target" ]]; then
  backup="${skills_root}/meta-anno.backup.$(date +%Y%m%d-%H%M%S)"
  mv "$target" "$backup"
  echo "Existing skill backed up to: $backup"
fi

cp -R "$source_dir" "$target"
chmod +x "${target}/scripts/check-meta-anno.sh" 2>/dev/null || true

echo "Installed Claude Code skill: $target"
echo "Invoke in Claude Code with: /meta-anno"
echo "Optional scanner script: ${target}/scripts/check-meta-anno.sh"
