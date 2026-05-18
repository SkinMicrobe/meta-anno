# Tool Help Reference

Use this file when exact command syntax, option names, output modes, or version-specific behavior matters. These snippets come from the user's current annotation notes and should be treated as historical environment evidence, not universal latest documentation.

## DIAMOND v0.8.36 Help

Context:

```bash
conda activate smag
diamond makedb --in /mnt/cephfs/s2z1/db/CAZy/CAZy-V14.fa -d /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/localDB/CAZyme_db
```

Captured help:

```text
diamond v0.8.36.98 | by Benjamin Buchfink <buchfink@gmail.com>
Check http://github.com/bbuchfink/diamond for updates.

Syntax: diamond COMMAND [OPTIONS]

Commands:
makedb  Build DIAMOND database from a FASTA file
blastp  Align amino acid query sequences against a protein reference database
blastx  Align DNA query sequences against a protein reference database
view    View DIAMOND alignment archive (DAA) formatted file
help    Produce help message
version Display version information
getseq  Retrieve sequences from a DIAMOND database file

General options:
--threads (-p)         number of CPU threads
--db (-d)              database file
--out (-o)             output file
--outfmt (-f)          output format
        0   = BLAST pairwise
        5   = BLAST XML
        6   = BLAST tabular
        100 = DIAMOND alignment archive (DAA)
        101 = SAM

        Value 6 may be followed by a space-separated list of these keywords:

        qseqid means Query Seq - id
        qlen means Query sequence length
        sseqid means Subject Seq - id
        sallseqid means All subject Seq - id(s), separated by a ';'
        slen means Subject sequence length
        qstart means Start of alignment in query
        qend means End of alignment in query
        sstart means Start of alignment in subject
        send means End of alignment in subject
        qseq means Aligned part of query sequence
        sseq means Aligned part of subject sequence
        evalue means Expect value
        bitscore means Bit score
        score means Raw score
        length means Alignment length
        pident means Percentage of identical matches
        nident means Number of identical matches
        mismatch means Number of mismatches
        positive means Number of positive - scoring matches
        gapopen means Number of gap openings
        gaps means Total number of gaps
        ppos means Percentage of positive - scoring matches
        qframe means Query frame
        btop means Blast traceback operations(BTOP)
        stitle means Subject Title
        salltitles means All Subject Title(s), separated by a '<>'
        qcovhsp means Query Coverage Per HSP
        qtitle means Query title

        Default: qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore
--verbose (-v)         verbose console output
--log                  enable debug log
--quiet                disable console output

Makedb options:
--in                   input reference file in FASTA format

Aligner options:
--query (-q)           input query file
--un                   file for unaligned queries
--unal                 report unaligned queries (0=no, 1=yes)
--max-target-seqs (-k) maximum number of target sequences to report alignments for
--top                  report alignments within this percentage range of top alignment score (overrides --max-target-seqs)
--compress             compression for output files (0=none, 1=gzip)
--evalue (-e)          maximum e-value to report alignments
--min-score            minimum bit score to report alignments (overrides e-value setting)
--id                   minimum identity% to report an alignment
--query-cover          minimum query cover% to report an alignment
--subject-cover        minimum subject cover% to report an alignment
--sensitive            enable sensitive mode (default: fast)
--more-sensitive       enable more sensitive mode (default: fast)
--block-size (-b)      sequence block size in billions of letters (default=2.0)
--index-chunks (-c)    number of chunks for index processing
--tmpdir (-t)          directory for temporary files
--gapopen              gap open penalty (default=11 for protein)
--gapextend            gap extension penalty (default=1 for protein)
--matrix               score matrix for protein alignment (default=BLOSUM62)
--custom-matrix        file containing custom scoring matrix
--lambda               lambda parameter for custom matrix
--K                    K parameter for custom matrix
--comp-based-stats     enable composition based statistics (0/1=default)
--seg                  enable SEG masking of queries (yes/no)
--query-gencode        genetic code to use to translate query (see user manual)
--salltitles           print full subject titles in output files
--no-self-hits         suppress reporting of identical self hits

Advanced options:
--bin                  number of query bins for seed search
--min-orf (-l)         ignore translated sequences without an open reading frame of at least this length
--freq-sd              number of standard deviations for ignoring frequent seeds
--id2                  minimum number of identities for stage 1 hit
--window (-w)          window size for local hit search
--xdrop (-x)           xdrop for ungapped alignment
--ungapped-score       minimum alignment score to continue local extension
--hit-band             band for hit verification
--hit-score            minimum score to keep a tentative alignment
--gapped-xdrop (-X)    xdrop for gapped alignment in bits
--band                 band for dynamic programming computation
--shapes (-s)          number of seed shapes (0 = all available)
--shape-mask           seed shapes
--index-mode           index mode (0=4x12, 1=16x9)
--fetch-size           trace point fetch size
--rank-factor          include subjects within this range of max-target-seqs
--rank-ratio           include subjects within this ratio of last hit
--max-hsps             maximum number of HSPs per subject sequence to save for each query
--dbsize               effective database size (in letters)
--no-auto-append       disable auto appending of DAA and DMND file extensions
--target-fetch-size    number of target sequences to fetch for seed extension

View options:
--daa (-a)             DIAMOND alignment archive (DAA) file
--forwardonly          only show alignments of forward strand

Getseq options:
--seq                  Sequence numbers to display.
```

## VFDB Database Build Notes

```bash
# Set A (Core): experimentally confirmed representative VFs; conservative and precise.
# Set B (Full): expanded full set including homologs/alleles; higher recall and more false positives.
gunzip -k /mnt/cephfs/s2z1/db/VFDB2025/VFDB_setB_pro.fas.gz
diamond makedb --in /mnt/cephfs/s2z1/db/VFDB2025/VFDB_setB_pro.fas \
  -d /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/localDB/VFDB_setB
```

## RGI 6.0.2 Help

Install and load local CARD database:

```bash
conda activate smag
mamba install --channel conda-forge --channel bioconda --channel defaults rgi
cd /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/localDB/
rgi load --card_json /mnt/cephfs/s2z1/db/CARD/card.json --local
```

Captured `rgi main` help:

```text
usage: rgi main [-h] -i INPUT_SEQUENCE -o OUTPUT_FILE [-t {contig,protein}]
                [-a {DIAMOND,BLAST}] [-n THREADS] [--include_loose]
                [--include_nudge] [--local] [--clean] [--keep] [--debug]
                [--low_quality] [-d {wgs,plasmid,chromosome,NA}] [-v]
                [-g {PRODIGAL,PYRODIGAL}] [--split_prodigal_jobs]

Resistance Gene Identifier - 6.0.2 - Main

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT_SEQUENCE, --input_sequence INPUT_SEQUENCE
                        input file must be in either FASTA (contig and
                        protein) or gzip format! e.g myFile.fasta,
                        myFasta.fasta.gz
  -o OUTPUT_FILE, --output_file OUTPUT_FILE
                        output folder and base filename
  -t {contig,protein}, --input_type {contig,protein}
                        specify data input type (default = contig)
  -a {DIAMOND,BLAST}, --alignment_tool {DIAMOND,BLAST}
                        specify alignment tool (default = BLAST)
  -n THREADS, --num_threads THREADS
                        number of threads (CPUs) to use in the BLAST search
                        (default=16)
  --include_loose       include loose hits in addition to strict and perfect
                        hits (default: False)
  --include_nudge       include hits nudged from loose to strict hits
                        (default: False)
  --local               use local database (default: uses database in
                        executable directory)
  --clean               removes temporary files (default: False)
  --keep                keeps Prodigal CDS when used with --clean (default:
                        False)
  --debug               debug mode (default: False)
  --low_quality         use for short contigs to predict partial genes
                        (default: False)
  -d {wgs,plasmid,chromosome,NA}, --data {wgs,plasmid,chromosome,NA}
                        specify a data-type (default = NA)
  -v, --version         prints software version number
  -g {PRODIGAL,PYRODIGAL}, --orf_finder {PRODIGAL,PYRODIGAL}
                        specify ORF finding tool (default = PRODIGAL)
  --split_prodigal_jobs
                        run multiple prodigal jobs simultaneously for contigs
                        in a fasta file (default: False)
```

## eggNOG Install And Version Check

Captured install pattern:

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

Captured version/warning output:

```text
There was an error retrieving eggnog-mapper DB data: not a valid file "/home/com4/miniconda3/envs/smag_eggNOG/lib/python3.12/site-packages/data/eggnog.db"
Maybe you need to run download_eggnog_data.py (ignore this when --data_dir points to the user's own database location)
emapper-2.1.12 / Expected eggNOG DB version: 5.0.2 / Installed eggNOG DB version: unknown / Diamond version found: diamond version 2.1.14 / MMseqs2 version found: 18.8cc5c / Compatible novel families DB version: 1.0.1
```

## emapper.py Usage Snapshot

Note from user: full database download can require about 500G; taxid `2` is Bacteria.

```text
usage: emapper.py [-h] [-v] [--list_taxa] [--cpu NUM_CPU]
                  [--mp_start_method {fork,spawn,forkserver}] [--resume]
                  [--override] [-i FASTA_FILE]
                  [--itype {CDS,proteins,genome,metagenome}] [--translate]
                  [--annotate_hits_table SEED_ORTHOLOGS_FILE] [-c FILE]
                  [--data_dir DIR] [--genepred {search,prodigal}]
                  [--trans_table TRANS_TABLE_CODE] [--training_genome FILE]
                  [--training_file FILE]
                  [--allow_overlaps {none,strand,diff_frame,all}]
                  [--overlap_tol FLOAT]
                  [-m {diamond,mmseqs,hmmer,no_search,cache,novel_fams}]
                  [--pident PIDENT] [--query_cover QUERY_COVER]
                  [--subject_cover SUBJECT_COVER] [--evalue EVALUE]
                  [--score SCORE] [--dmnd_algo {auto,0,1,ctg}]
                  [--dmnd_db DMND_DB_FILE]
                  [--sensmode {default,fast,mid-sensitive,sensitive,more-sensitive,very-sensitive,ultra-sensitive}]
                  [--dmnd_iterate {yes,no}]
                  [--matrix {BLOSUM62,BLOSUM90,BLOSUM80,BLOSUM50,BLOSUM45,PAM250,PAM70,PAM30}]
                  [--dmnd_frameshift DMND_FRAMESHIFT] [--gapopen GAPOPEN]
                  [--gapextend GAPEXTEND] [--block_size BLOCK_SIZE]
                  [--index_chunks CHUNKS] [--outfmt_short]
                  [--dmnd_ignore_warnings] [--mmseqs_db MMSEQS_DB_FILE]
                  [--start_sens START_SENS] [--sens_steps SENS_STEPS]
                  [--final_sens FINAL_SENS] [--mmseqs_sub_mat SUBS_MATRIX]
                  [-d HMMER_DB_PREFIX] [--servers_list FILE]
                  [--qtype {hmm,seq}] [--dbtype {hmmdb,seqdb}] [--usemem]
                  [-p PORT] [--end_port PORT] [--num_servers NUM_SERVERS]
                  [--num_workers NUM_WORKERS]
                  [--timeout_load_server TIMEOUT_LOAD_SERVER]
                  [--hmm_maxhits MAXHITS] [--report_no_hits]
                  [--hmm_maxseqlen MAXSEQLEN] [--Z DB_SIZE] [--cut_ga]
                  [--clean_overlaps none|all|clans|hmmsearch_all|hmmsearch_clans]
                  [--no_annot] [--dbmem]
                  [--seed_ortholog_evalue MIN_E-VALUE]
                  [--seed_ortholog_score MIN_SCORE] [--tax_scope TAX_SCOPE]
                  [--tax_scope_mode TAX_SCOPE_MODE]
                  [--target_orthologs {one2one,many2one,one2many,many2many,all}]
                  [--target_taxa LIST_OF_TAX_IDS]
                  [--excluded_taxa LIST_OF_TAX_IDS] [--report_orthologs]
                  [--go_evidence {experimental,non-electronic,all}]
                  [--pfam_realign {none,realign,denovo}] [--md5]
                  [--output FILE_PREFIX] [--output_dir DIR]
                  [--scratch_dir DIR] [--temp_dir DIR] [--no_file_comments]
                  [--decorate_gff DECORATE_GFF]
                  [--decorate_gff_ID_field DECORATE_GFF_ID_FIELD] [--excel]
```

## download_eggnog_data.py Help

Captured command:

```bash
download_eggnog_data.py --help
```

Captured output:

```text
/home/compute1/miniconda3/envs/smag/bin/download_eggnog_data.py:189: SyntaxWarning: invalid escape sequence '\.'
  'outf=$(echo "$file" | sed "s/\.raw_alg\.faa\.gz/\.fa/"); '
usage: download_eggnog_data.py [-h] [-D] [-F] [-P] [-M] [-H] [-d HMMER_DBS]
                               [--dbname DBNAME] [-y] [-f] [-s] [-q]
                               [--data_dir]

options:
  -h, --help       show this help message and exit
  -D               Do not install the diamond database (default: False)
  -F               Install the novel families diamond and annotation
                   databases, required for "emapper.py -m novel_fams"
                   (default: False)
  -P               Install the Pfam database, required for de novo
                   annotation or realignment (default: False)
  -M               Install the MMseqs2 database, required for "emapper.py -m
                   mmseqs" (default: False)
  -H               Install the HMMER database specified with "-d TAXID".
                   Required for "emapper.py -m hmmer -d TAXID" (default:
                   False)
  -d HMMER_DBS     Tax ID of eggNOG HMM database to download. e.g. "-H -d 2"
                   for Bacteria. Required if "-H". Available tax IDs can be
                   found at http://eggnog5.embl.de/#/app/downloads.
                   (default: None)
  --dbname DBNAME  Tax ID of eggNOG HMM database to download. e.g. "-H -d 2
                   --dbname 'Bacteria'" to download Bacteria (taxid 2) to a
                   directory named Bacteria (default: None)
  -y               assume "yes" to all questions (default: False)
  -f               forces download even if the files exist (default: False)
  -s               simulate and print commands. Nothing is downloaded
                   (default: False)
  -q               quiet_mode (default: False)
  --data_dir       Directory to use for DATA_PATH. (default: None)
```
