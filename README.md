# meta-anno

`meta-anno` is a Claude Code skill for analyzing and maintaining metagenome functional annotation workflows.

It is designed for Linux servers running Claude Code, especially workflows involving:

- eggNOG / `emapper.py`
- DIAMOND `blastp`
- RGI / CARD
- VFDB
- CAZyme
- Ceph or other shared storage
- multi-host batch scripts
- `.lock` files, database copies, stale jobs, and failed sample recovery

## Install On Linux Server

Upload this whole project directory to the Linux server, then run:

```bash
cd /path/to/meta-anno && bash install.sh
```

The installer copies the skill from:

```text
.claude/skills/meta-anno
```

to:

```text
~/.claude/skills/meta-anno
```

If an old `meta-anno` skill already exists, `install.sh` removes it and installs the current project copy.

## Use In Claude Code

After installation, start or restart Claude Code on the server, then call:

```text
/meta-anno
```

Example prompts:

```text
/meta-anno 解释这个 eggNOG 批量脚本做了什么
```

```text
/meta-anno 帮我判断这些 .lock 文件是不是可以删除
```

```text
/meta-anno 根据这个目录检查 eggNOG 哪些样本完成、哪些失败
```

```text
/meta-anno 帮我写一个更稳的 emapper 并行运行脚本
```

## Project Layout

```text
meta-anno/
├── .claude/
│   └── skills/
│       └── meta-anno/
│           ├── SKILL.md
│           ├── references/
│           │   ├── database-guide.md
│           │   ├── output-examples.md
│           │   ├── templates.md
│           │   ├── tool-guide.md
│           │   ├── tool-help.md
│           │   └── workflow-notes.md
│           └── scripts/
│               └── check-meta-anno.sh
├── install.sh
└── README.md
```

Important files:

- `SKILL.md`: main Claude Code skill entry.
- `references/workflow-notes.md`: distilled notes from the current annotation workflow.
- `references/templates.md`: reusable Linux command templates and safer batch skeletons.
- `references/database-guide.md`: explains what CAZy, eggNOG, CARD/RGI, and VFDB contain and how to interpret/choose databases.
- `references/tool-guide.md`: explains what each command-line tool does in the workflow, including inputs, outputs, and common failure modes.
- `references/tool-help.md`: captured long help text and install/version checks for DIAMOND, RGI, eggNOG, and database download commands.
- `references/output-examples.md`: captured example outputs for DIAMOND, eggNOG, RGI, VFDB, stale-lock logs, and runtime notes.
- `references/smgc-2021-natmicrobiol.md`: distilled workflow understanding from the SMGC 2021 Nature Microbiology paper.
- `scripts/check-meta-anno.sh`: helper script for scanning eggNOG sample folders.
- `install.sh`: Linux installer for Claude Code.

## Helper Script

After installation, the helper scanner is available at:

```bash
~/.claude/skills/meta-anno/scripts/check-meta-anno.sh
```

Usage:

```bash
bash ~/.claude/skills/meta-anno/scripts/check-meta-anno.sh /path/to/confirmed_function_dir
```

It expects a sample layout like:

```text
confirmed_function_dir/
├── sampleA/
│   ├── sampleA.clean.faa
│   ├── eggNOG.emapper.annotations
│   ├── eggnog_run.log
│   └── .lock
└── sampleB/
    └── sampleB.clean.faa
```

The output is a tab-separated status table:

```text
sample_dir    status    input    output_bytes    lock    log_issue
```

Common statuses:

- `complete`: output exists, is non-empty, and starts with a header line.
- `missing_input`: expected `.clean.faa` is missing or empty.
- `locked`: `.lock` exists and output is not complete.
- `partial_output`: output file exists but does not pass the simple integrity check.
- `pending`: no complete output, no lock, and input exists.

## Update

After editing this project locally or uploading a newer version to the server, reinstall with:

```bash
cd /path/to/meta-anno && bash install.sh
```

## Uninstall

Remove the installed skill:

```bash
rm -rf ~/.claude/skills/meta-anno
```

Restart Claude Code if `/meta-anno` is still shown from an older session.

## Notes

- This project is Linux-first. Use `install.sh` on the server.
- Keep the skill directory name as `meta-anno`; Claude Code uses that name for `/meta-anno`.
- Do not move `SKILL.md` out of `.claude/skills/meta-anno/`.
