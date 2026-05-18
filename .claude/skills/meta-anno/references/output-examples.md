# Output Examples Reference

Use this file when interpreting result schemas, validating output shape, or comparing user logs to known examples from the meta-annotation workflow. These examples are historical snapshots from the user's notes and should not be treated as required biological results.

## DIAMOND CAZyme outfmt 6 Example

Command context:

```bash
head /mnt/cephfs/s2z5/skin/00-data/8_Four2one/Diamond/result/macrel.out.all_orfs.f6
```

Output:

```text
k127_1188_1     SPD34221.1|GT4  32.9    222     146     1       20      241  1219     8.8e-26 117.1
k127_530_2      QCB42417.1|GT4  33.8    74      49      0       165     238  586      659     5.7e-07 54.7
k127_4224_4     QZD93238.1|GT35 34.7    196     111     4       2       195  84       264     1.5e-15 82.8
k127_4096_3     UVO20229.1|GT121        33.5    182     118     2       21   199      774     955     8.8e-24 110.2
k127_5412_2     CBM48|GH13_8|GH13_8|611743|Bombom1_GeneCatalog_proteins_20170616.aa.fasta     61.4    471     172     3       15      480     746     1211 1.2e-154 546.2
k127_2784_1     CBM48|GH13_8|GH13_8|302973|Clasam1_GeneCatalog_proteins_20220224.aa.fasta     67.9    81      26      0       1       81      1091    1171 1.4e-23  108.2
k127_2644_2     AVT27117.1|GH2_10       98.1    258     5       0       1    258      728     985     6.0e-150        529.6
k127_1067_1     ALQ29162.1|GH65 32.6    227     120     8       2       198  8231     4.3e-13 74.7
k127_1474_1     WCC79228.1|GH38 90.9    187     17      0       1       187  841      1027    6.0e-99 359.8
k127_662_1      AYW79725.1|GH136        94.8    344     18      0       1    344      275     618     5.5e-191        666.4
```

Default DIAMOND outfmt 6 columns:

```text
qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore
```

Column meanings:

| Column | Meaning | Use in this workflow |
| --- | --- | --- |
| `qseqid` | Query sequence ID, usually ORF/protein ID from the input `.faa` | Join back to ORF or contig-derived protein |
| `sseqid` | Subject/reference sequence ID from CAZyme or VFDB database | Parse family/accession such as `GT4`, `GH13_8`, or `VFG...` |
| `pident` | Percent identity across the aligned region | Higher is more similar; use with coverage/length, not alone |
| `length` | Alignment length in amino acids | Helps reject very short high-identity hits |
| `mismatch` | Number of mismatched aligned residues | Quality check |
| `gapopen` | Number of gap openings | Quality check |
| `qstart` | Start coordinate on query | Helps judge query coverage |
| `qend` | End coordinate on query | Helps judge query coverage |
| `sstart` | Start coordinate on subject/reference | Helps judge subject coverage |
| `send` | End coordinate on subject/reference | Helps judge subject coverage |
| `evalue` | Expected random-hit significance | Lower is stronger; common cutoff in notes is `1e-5` |
| `bitscore` | Alignment bit score | Higher is stronger; useful for ranking |

Important: the user's DIAMOND commands use `--max-target-seqs 1`, so each query keeps only one top reported target. This simplifies output but can hide secondary plausible annotations.

## eggNOG Two-Phase Command And Annotation Output

Command context:

```bash
emapper.py --no_annot --no_file_comments --override --cpu 16 \
  --data_dir ${db_path}  -i ${input_dir} -m diamond  \
  -o ${output_dir}/eggnog_process --temp_dir ${temp_dir}

emapper.py \
  --annotate_hits_table ${output_dir}/eggnog_process.emapper.seed_orthologs \
  --data_dir ${db_path} \
  --cpu 8 --no_file_comments --override \
  -o ${output_dir}/eggnog --temp_dir ${temp_dir}
```

Annotation output:

```text
#query  seed_ortholog   evalue  score   eggNOG_OGs      max_annot_lvl   COG_category  Description     Preferred_name  GOs     EC      KEGG_ko KEGG_Pathway KEGG_Module      KEGG_Reaction   KEGG_rclass     BRITE   KEGG_TC CAZy    BiGG_Reaction PFAMs
k127_4791_1     267747.PPA1997  3.935e-122      392.0   COG3010@1|root,COG3010@2|Bacteria,2GTWV@201174|Actinobacteria,4DR9M@85009|Propionibacteriales 201174|Actinobacteria G       Converts N-acetylmannosamine-6-phosphate (ManNAc-6-P) to N-acetylglucosamine-6-phosphate (GlcNAc-6-P) nanE    -       5.1.3.9 ko:K01788     ko00520,map00520        -       R02087  RC00290 ko00000,ko00001,ko01000       -       -       -       NanE
k127_717_1      267747.PPA0155  4.735e-155      490.0   COG1643@1|root,COG1643@2|Bacteria,2GMAW@201174|Actinobacteria,4DPC5@85009|Propionibacteriales 201174|Actinobacteria L       ATP-dependent helicase HrpB     hrpB    -       3.6.4.13      ko:K03579       -       -       -       -       ko00000,ko01000 -    --       DEAD,HA2,Helicase_C,HrpB_C
k127_3209_1     267747.PPA2279  7.343e-83       275.0   2DMJP@1|root,32S0N@2|Bacteria,2H65K@201174|Actinobacteria     201174|Actinobacteria   S       D-ornithine 4,5-aminomutase alpha-subunit     -       -       5.4.3.5 ko:K17899    ko00472,map00472 -       R02461  RC00719 ko00000,ko00001,ko01000 -       -    -OAM_alpha
k127_1798_1     553217.ENHAE0001_0458   2.883e-35       136.0   COG0772@1|root,COG0772@2|Bacteria,1MVDB@1224|Proteobacteria,1RMIV@1236|Gammaproteobacteria,3NIQ8@468|Moraxellaceae  1236|Gammaproteobacteria        D       Peptidoglycan polymerase that is essential for cell division  ftsW    GO:0003674,GO:0005215,GO:0005575,GO:0005623,GO:0005886,GO:0005887,GO:0006810,GO:0008150,GO:0008360,GO:0009987,GO:0015647,GO:0015648,GO:0015835,GO:0015836,GO:0016020,GO:0016021,GO:0022603,GO:0022604,GO:0022857,GO:0022884,GO:0031224,GO:0031226,GO:0032153,GO:0044425,GO:0044459,GO:0044464,GO:0050789,GO:0050793,GO:0050794,GO:0051128,GO:0051179,GO:0051234,GO:0051301,GO:0055085,GO:0065007,GO:0065008,GO:0071702,GO:0071705,GO:0071944,GO:1901264,GO:1901505  -       ko:K03588       ko04112,map04112      -       -       -       ko00000,ko00001,ko02000,ko03036 2.A.103.1    --       FTSW_RODA_SPOVE
k127_3212_1     553217.ENHAE0001_1944   4.65e-59        205.0   2DYXP@1|root,34BMW@2|Bacteria,1NZU5@1224|Proteobacteria,1SRGG@1236|Gammaproteobacteria,3NRZK@468|Moraxellaceae      1236|Gammaproteobacteria        -       -       -    --       -       -       -       -       -       -       -       -       -    -
k127_2301_1     267747.PPA0421  1.03e-203       634.0   COG2875@1|root,COG2875@2|Bacteria,2GJ97@201174|Actinobacteria,4DPG8@85009|Propionibacteriales 201174|Actinobacteria H       Belongs to the precorrin methyltransferase family    cobM     -       2.1.1.133,2.1.1.271     ko:K05936       ko00860,ko01100,map00860,map01100     -       R05181,R05810   RC00003,RC01294,RC02049 ko00000,ko00001,ko01000       -       -       -       TP_methylase
k127_3583_1     267747.PPA0191  5.501e-216      670.0   COG3173@1|root,COG3173@2|Bacteria,2GMHD@201174|Actinobacteria 201174|Actinobacteria   S       Aminoglycoside phosphotransferase     -       -       -       -       -       -    --       -       -       -       -       APH
k127_1254_1     575586.HMPREF0016_03335 2.657e-70       237.0   COG3436@1|root,COG3436@2|Bacteria,1RHJ1@1224|Proteobacteria,1S5UN@1236|Gammaproteobacteria,3NNI6@468|Moraxellaceae  1236|Gammaproteobacteria        L       IS66 Orf2 like protein        -       -       -       ko:K07484       -       -       -    -ko00000 -       -       -       TnpB_IS66
k127_5485_1     267747.PPA0021  1.644e-95       313.0   COG1762@1|root,COG1762@2|Bacteria,2H0MP@201174|Actinobacteria 201174|Actinobacteria   G       phosphoenolpyruvate-dependent sugar phosphotransferase system, EIIA 2 -       -    2.7.1.200        ko:K02773       ko00052,ko01100,ko02060,map00052,map01100,map02060    M00279  R05570  RC00017,RC03206 ko00000,ko00001,ko00002,ko01000,ko02000       4.A.5.1 -       -       PTS_EIIA_2
```

Key annotation columns:

| Column | Meaning | Use in this workflow |
| --- | --- | --- |
| `query` | Input ORF/protein ID | Primary key back to `.faa` record |
| `seed_ortholog` | Best seed ortholog used by eggNOG | Evidence anchor for downstream annotations |
| `evalue` | Search significance of seed ortholog hit | Lower is stronger |
| `score` | Alignment/search score | Higher is stronger |
| `eggNOG_OGs` | Orthologous group assignments across taxonomic levels | Functional and phylogenetic context |
| `max_annot_lvl` | Highest taxonomic level used for annotation transfer | Useful for judging annotation specificity |
| `COG_category` | One-letter COG functional category | Broad function class; `-` means unavailable |
| `Description` | Functional description | Main human-readable annotation |
| `Preferred_name` | Preferred gene/protein symbol | Use as short functional label when present |
| `GOs` | Gene Ontology terms | GO enrichment or ontology mapping |
| `EC` | Enzyme Commission number | Enzyme function annotation |
| `KEGG_ko` | KEGG orthology IDs | KEGG pathway/module mapping |
| `KEGG_Pathway` | KEGG pathway IDs | Pathway-level summary |
| `KEGG_Module` | KEGG module IDs | Module-level summary |
| `KEGG_Reaction` | KEGG reaction IDs | Reaction-level enzyme mapping |
| `KEGG_rclass` | KEGG reaction class IDs | Reaction class mapping |
| `BRITE` | KEGG BRITE hierarchy IDs | Functional hierarchy annotation |
| `KEGG_TC` | Transporter Classification IDs | Transporter annotation |
| `CAZy` | CAZy family annotations reported by eggNOG | Cross-check with separate CAZyme DIAMOND run |
| `BiGG_Reaction` | BiGG metabolic model reaction IDs | Metabolic model mapping |
| `PFAMs` | Pfam domain IDs/names | Domain-level support for function |

Typical missing-value markers are `-` or `--`. Do not treat rows with missing optional fields as failed if core columns and the header are present.

## eggNOG seed_orthologs Output

```text
#qseqid sseqid  evalue  bitscore        qstart  qend    sstart  send    pidentqcov    scov
k127_4791_1     267747.PPA1997  3.935e-122      392.0   1       196     34   229      100.0   99.5    85.6
k127_717_1      267747.PPA0155  4.735e-155      490.0   1       247     592  838      95.5    99.6    29.5
k127_3209_1     267747.PPA2279  7.343e-83       275.0   1       140     1    140      100.0   99.3    100.0
k127_1798_1     553217.ENHAE0001_0458   2.883e-35       136.0   1       68   146      213     98.5    68.0    16.900000000000002
k127_3212_1     553217.ENHAE0001_1944   4.65e-59        205.0   1       104  1104     98.0    99.0    100.0
k127_2301_1     267747.PPA0421  1.03e-203       634.0   1       311     13   323      99.3    99.7    96.3
k127_2172_1     267747.PPA2015  2.5e-57 199.0   1       95      87      181  98.9     99.0    52.5
k127_3583_1     267747.PPA0191  5.501e-216      670.0   1       320     1    320      99.3    99.7    100.0
k127_1254_1     575586.HMPREF0016_03335 2.657e-70       237.0   1       111  1111     99.0    99.1    100.0
```

Seed ortholog columns:

| Column | Meaning | Use in this workflow |
| --- | --- | --- |
| `qseqid` | Query ORF/protein ID | Links to input `.faa` and final annotations |
| `sseqid` | Seed ortholog/reference ID | Input evidence for the annotation phase |
| `evalue` | Search significance | Lower is stronger |
| `bitscore` | Alignment bit score | Higher is stronger |
| `qstart` | Start coordinate on query | Alignment span on input protein |
| `qend` | End coordinate on query | Alignment span on input protein |
| `sstart` | Start coordinate on seed ortholog | Alignment span on seed reference |
| `send` | End coordinate on seed ortholog | Alignment span on seed reference |
| `pident` | Percent identity | Similarity measure |
| `qcov` | Query coverage percent | Important for filtering partial hits |
| `scov` | Subject coverage percent | Helps identify whether only a small part of reference matched |

If the header appears as `pidentqcov` without a visible separator, treat it as a display/spacing artifact from tabular output. The intended fields are `pident`, `qcov`, and `scov`.

## RGI/CARD Output Example

Command context:

```bash
head /mnt/cephfs/s2z5/skin/00-data/8_Four2one/RGI/RGI.txt
```

Output:

```text
ORF_ID  Contig  Start   Stop    Orientation     Cut_Off Pass_Bitscore   Best_Hit_Bitscore     Best_Hit_ARO    Best_Identities ARO     Model_type      SNPs_in_Best_Hit_ARO  Other_SNPs      Drug Class      Resistance Mechanism    AMR Gene Family       Predicted_DNA   Predicted_Protein       CARD_Protein_SequencePercentage Length of Reference Sequence  ID      Model_ID        Nudged  Note Hit_Start        Hit_End Antibiotic      AST_Source
k127_3800_1 # 48 # 296 # -1 # ID=4878_1;partial=00;start_type=ATG;rbs_motif=None;gc_cont=0.434                                        Strict600     169.5   ICR-Mo  98.78   3004569 protein homolog model   n/a     n/a  peptide antibiotic       antibiotic target alteration    intrinsic colistin resistant phosphoethanolamine transferase          MLYVSDHGESLGENGIYLHGMPYKIAPKAQKHVASMFWAGKHSGIQAVPSNTELTHDAITSTLLKLFDVRAQTVQGKPLFIK    MVHLDKVSNRMSVNNSRWLAWRQQGINAYVMMGIVALFLTLTANITFFDKATEVYPFAQHIGFIGSLPLVLFGVMLLVIVLLSYRYTLKAVLIFLLLTAAVTAYFTDTYGTVYDVNMLQNALQTDKAESADLFNVNFILRILLLGVLPSVWVAWQKVTFPPIKRSILQRGLTYLVSLGLVVLPILAMSKNYASFFREHKQLRSYTNPATPVYALGKLASIQLKQAQAPKTQIMHATDAVQVSNPTTRKPKLVVFVVGETARGDHVQLNGYNRTTFPQMAATAGVTNFNQVIACGTSTAYSVPCMFSYVGMKDYDVDTANYQENVLDTLHRLKVNILWRDNNSSSKGVTNRLPAADFVDYKTARNNTMCNTNPYGECRDVGMLVGLDDYVKQQANQNTLNQDTLIVLHQMGNHGPAYFKRYDKQFEKFTPVCQSNELAKCDPQSVINAFDNALLATDDFLAKTVNWLDKYDSTHQVAMLYVSDHGESLGENGIYLHGMPYKIAPKAQKHVASMFWAGKHSGIQAVPSNTELTHDAITPTLLKLFDVRAQTVQGKPLFIK    14.70gnl|BL_ORD_ID|2736|hsp_num:0     3271    True    loose hit with at least 95 percent identity pushed strict                     colistin A; colistin B
```

Key RGI columns:

| Column | Meaning | Use in this workflow |
| --- | --- | --- |
| `ORF_ID` | Input ORF/protein identifier; can contain Prodigal-style metadata | Primary result ID |
| `Contig` | Source contig when available | Link result back to contig |
| `Start` / `Stop` | Coordinates on source sequence | Genomic/protein location context |
| `Orientation` | Strand/orientation | Useful for contig inputs |
| `Cut_Off` | RGI hit class such as Perfect, Strict, or Loose | Primary confidence category |
| `Pass_Bitscore` | Model threshold bitscore | Compare to best-hit bitscore |
| `Best_Hit_Bitscore` | Best alignment bitscore | Higher supports stronger hit |
| `Best_Hit_ARO` | Best CARD Antibiotic Resistance Ontology hit name | Main resistance gene/model label |
| `Best_Identities` | Percent identity to best ARO hit | Key confidence metric |
| `ARO` | CARD ARO numeric identifier | Stable ontology ID |
| `Model_type` | CARD model type | Explains how the hit was classified |
| `SNPs_in_Best_Hit_ARO` | Known resistance SNPs in best hit | Relevant for SNP-based models |
| `Other_SNPs` | Other observed SNPs | Extra variant evidence |
| `Drug Class` | Antibiotic class affected | Main phenotype grouping |
| `Resistance Mechanism` | Mechanism such as target alteration or efflux | Mechanistic interpretation |
| `AMR Gene Family` | Resistance gene family | Family-level summary |
| `Predicted_DNA` | Predicted nucleotide sequence when available | Sequence evidence |
| `Predicted_Protein` | Predicted protein sequence | Sequence evidence |
| `CARD_Protein_Sequence` | CARD reference protein sequence or related field | Reference comparison |
| `Percentage Length of Reference Sequence` | Query/reference length coverage percent | Helps reject tiny partial hits |
| `ID` | Internal alignment/model hit ID | Traceability |
| `Model_ID` | CARD model ID | Traceability |
| `Nudged` | Whether `--include_nudge` promoted a loose hit to strict | Important for interpreting confidence |
| `Note` | RGI explanatory note | Often explains nudge/loose/strict behavior |
| `Hit_Start` / `Hit_End` | Coordinates of hit region | Hit span |
| `Antibiotic` | Specific antibiotic names | More specific than drug class |
| `AST_Source` | AST/source metadata if available | Usually optional |

When `Nudged=True`, report that the hit was originally loose but pushed to strict by nudge logic. Do not interpret it exactly like an unnudged strict hit.

## DIAMOND VFDB outfmt 6 Example

Command context:

```bash
head /mnt/cephfs/s2z5/skin/00-data/8_Four2one/VFDB/result/vfdb.setA.tsv
```

Output:

```text
k127_1188_1     VFG036559(gb|WP_013449339)      32.9    216     136     5    29       242     10      218     5.3e-21 99.0
k127_401_1      VFG001379(gb|NP_214867) 62.1    103     37      1       1    103      24      124     3.1e-29 125.2
k127_1322_1     VFG047558(gb|WP_012279909)      27.2    92      66      1    191      249     340     2.7e-09 58.9
k127_4356_1     VFG009806(gb|WP_036377334)      58.7    167     68      1    7172     69      235     6.0e-51 198.0
k127_4096_3     VFG013149(gb|WP_041605303)      37.4    182     111     2    21       199     398     579     1.3e-28 124.0
k127_2641_1     VFG009859(gb|WP_003872811)      69.2    227     68      1    3229     1       225     2.2e-85 312.8
k127_5412_2     VFG041849(gb|WP_011136175)      30.9    379     244     9    22       395     15      380     7.5e-35 146.0
k127_1333_1     VFG024200(gb|WP_008262428)      40.3    216     120     4    4217     8       216     2.1e-29 126.7
k127_1848_1     VFG023851(gb|WP_036428980)      33.7    184     119     2    13       193     11      194     1.7e-18 90.5
k127_5028_1     VFG014106(gb|NP_251842) 43.5    200     103     5       1    198      9       200     6.7e-38 154.8
```

VFDB uses the same default DIAMOND outfmt 6 columns described above:

```text
qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore
```

For VFDB, `sseqid` often contains a virulence factor ID such as `VFG036559` plus a GenBank/RefSeq accession. Interpret `pident`, `length`, `evalue`, and `bitscore` together; short low-evalue hits can still need biological filtering depending on the downstream threshold.

## Monitoring And Failure Examples

Completed output counts:

```bash
find /mnt/cephfs/s2z2/SProject/02-meta/10-anno-mags/02_function2/ \
    -type f -name "eggNOG.emapper.annotations" | xargs -n1 dirname | sort -u | wc -l
find /mnt/cephfs/s2z2/SProject/02-meta/10-anno-mags/02_function/ \
    -type f -name "eggNOG.emapper.annotations" | xargs -n1 dirname | sort -u | wc -l
```

Observed note:

```text
function-310 function2-234  473
```

Stale lock style log:

```text
Found lock file, skipping sample: /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/02_function/CRA01251-CRR838467
Found lock file, skipping sample: /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/02_function/CRA01251-CRR838469
Found lock file, skipping sample: /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/02_function/CRA01251-CRR838471
Found lock file, skipping sample: /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/02_function/CRA01251-CRR838473
Found lock file, skipping sample: /mnt/cephfs/s2z2/SProject/02-meta/10-anno-contigs/02_function/CRA01251-CRR838475
```

Interpretation from notes: these likely came from C2 crashing midway before annotation completed.

Detached monitor example:

```bash
cd /mnt/cephfs/s2z5/skin/00-data
nohup bash monitor_emapper.sh &
```

Output:

```text
[1] 3822383
nohup: ignoring input and appending output to 'nohup.out'
```

Runtime notes:

```text
one sample: Total time: 7136 secs
about 2h per sample; 14 samples/day; 11217 samples would be about 26 months
100 samples: Estimated time: 10800 secs
C1 had I/O error/crash; user considered trying 50 concurrent jobs
788 secs
```
