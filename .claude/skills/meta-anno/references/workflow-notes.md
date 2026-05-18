# Meta-Annotation Workflow Notes

This reference distills the user's current metagenome annotation notes.

## Main Tools

| Tool | Purpose | Typical output |
| --- | --- | --- |
| DIAMOND `blastp` | Protein-to-protein search against CAZyme or VFDB databases | BLAST outfmt 6 TSV |
| DIAMOND `makedb` | Build local `.dmnd` search databases from FASTA references | `*.dmnd` |
| eggNOG `emapper.py` | Orthology search and functional annotation | `eggNOG.emapper.annotations`, `*.seed_orthologs` |
| RGI/CARD | Antibiotic resistance gene detection | `RGI.txt` and RGI auxiliary outputs |
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

CAZyme and VFDB are DIAMOND searches:

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

## Main Operational Risks

- Existence-only completion check can skip corrupted or partial outputs.
- Stale `.lock` files remain after crashes and block reruns.
- Shared Ceph temp directories increase I/O pressure.
- Multiple workers reading one database copy can overload network storage.
- Increasing CPU threads does not help if `iostat` shows sustained I/O wait.
- Host-specific DIAMOND/MMseqs/RGI versions can make a script valid on one machine but invalid on another.
- Variable values with trailing spaces, especially input FASTA paths, can cause file-not-found behavior.
- `watch` is interactive and should not sit inside a non-interactive batch script before `conda activate`; use it in a separate terminal/session.
- Remount commands such as `sudo umount -l /mnt/cephfs && sudo mount -a` are operationally disruptive. Use them only when the user intentionally wants to recover a broken mount.
- Original notes mention keeping eggNOG input files under about 5 GB; check input size before blaming tool failure.

## Practical Scaling Heuristic

For eggNOG/mmseqs on Ceph:

1. Start with fewer concurrent samples than CPU allows.
2. Keep per-sample CPU explicit.
3. Use separate database copies for concurrent workers when storage allows.
4. Watch `iostat -xz 5`; if `%iowait` or device utilization is high, reduce `max_jobs`.
5. Prefer per-sample temp dirs; use local scratch if available and large enough.
6. Validate completion before deleting locks or marking runs done.

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
