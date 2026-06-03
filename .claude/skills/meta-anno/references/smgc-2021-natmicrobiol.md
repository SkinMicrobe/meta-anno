# SMGC 2021 Nature Microbiology Notes

Use this reference when the user asks about SMGC, skin metagenome genome catalogues, multi-kingdom skin microbiome analysis, MAG recovery, viral/eukaryotic branches, or how literature should inform the `meta-anno` workflow.

## Paper Identity

- Paper: "Integrating cultivation and metagenomics for a multi-kingdom view of skin microbiome diversity and functions"
- Journal: Nature Microbiology
- DOI: `10.1038/s41564-021-01011-w`
- Catalogue: SMGC means Skin Microbial Genome Collection in this paper.
- Important guardrail: do not infer a soil workflow from the filename alone. This SMGC paper is about the human skin microbiome.

## Central Claim

The paper builds a skin-specific, multi-kingdom genome catalogue by combining:

- bacterial cultivation and isolate genome sequencing;
- shotgun metagenomic assembly and binning;
- public skin metagenomes;
- separate prokaryotic, eukaryotic and viral analysis branches;
- read mapping/classification against the resulting catalogue.

The key workflow lesson is that a high-quality metagenome catalogue is not just an annotation step. It depends on input design, assembly strategy, binning, dereplication, quality filtering, kingdom-specific detection, reference comparison and read-level validation.

## Mental Model For This Paper

Understand the paper as three connected layers:

1. Catalogue construction: recover genomes and viral contigs from cultivation, assembly, binning, quality control, dereplication and taxonomy.
2. Biological interpretation: annotate protein-coding genes, metabolic pathways, pan-genomes, eukaryotic genomes and viral clusters to explain what the catalogue contains.
3. Catalogue validation/use: map reads back to the catalogue and compare read assignment against general reference databases.

This matters for `meta-anno` because the paper is not mainly teaching "run one annotation command". It teaches that annotation results become biologically useful only after the sequence origin, genome quality, catalogue redundancy, kingdom-specific branch and read-level support are controlled.

Do not flatten the paper into an eggNOG recipe. eggNOG appears only as one component, especially for viral/jumbo-phage functional characterization; the prokaryotic genome metabolism conclusions rely more directly on Prokka, DRAM and KOfam/HMMER pathway completeness.

## Main Assets And Numbers

- SMGC contains 622 prokaryotic species derived from 7,535 quality-filtered MAGs plus 251 cultured bacterial isolate genomes.
- It also includes 12 eukaryotic species and thousands of non-redundant viral sequences.
- The paper reports 174 newly identified bacterial species, 12 newly identified bacterial genera, 4 newly identified eukaryotic species and 20 jumbo phages.
- The catalogue increased the characterized set of known skin bacteria by about 26%.
- Read assignment improved for skin metagenomes: SMGC assigned a median of 85% of reads, compared with 69% for the Kraken2 standard RefSeq database and 65% for the previous Pasolli skin catalogue.
- The catalogue is mainly built from samples from North America, so do not present it as globally complete.

## Study Design

- The study used longitudinal shotgun metagenomes from 12 healthy volunteers and 19 body sites, plus an additional fourth time point for selected sites.
- It supplemented those samples with public skin metagenomes from multiple studies, countries, age groups and skin conditions.
- The total analysed metagenome set spanned 1,918 samples from 15 studies.
- The Skin Bacteria Culture Collection (SBCC) contained 251 isolates from 15 body sites and 34 individuals.
- Negative controls were sequenced and mapped to the catalogue; the authors did not automatically exclude skin commensals detected in controls because index bleed-through and cross-contamination can make true skin signals appear in negative controls.

## Assembly And MAG Recovery

The paper used multiple assembly inputs instead of a single per-sample strategy:

- Single sequencing run.
- Per sample.
- Pool by healthy volunteer (`Pool HV`).
- Pool by body site (`Pool Site`).
- Pool by time across time points (`Pool Time`).

Operational interpretation:

- Co-assembly/pooling can recover low-abundance organisms missed by per-sample assembly.
- Pooling can also introduce chimerism or strain-mixing risk, so it must be paired with quality and chimerism checks.
- Do not treat one assembly mode as sufficient when the goal is catalogue completeness.

Major tools and checks:

- Preprocessing: KneadData with Bowtie2 and Trimmomatic.
- Assembly: SPAdes `--meta`; pooled assemblies also used `--only-assembler` to reduce assembly time.
- Binning: metaWRAP binning with MaxBin2, MetaBAT2 and CONCOCT.
- Refinement: metaWRAP `bin_refinement` with >=50% completeness and <=10% contamination.
- Quality: CheckM `lineage_wf`; N50 from BBMap `stats.sh`.
- Original SMGC rRNA/tRNA: INFERNAL/Rfam for 5S, 16S and 23S rRNAs; tRNAscan-SE for standard bacterial tRNAs.
- User's current SMGC-derived workflow: rRNA detection is replaced by `Barrnap`; do not reinterpret this local replacement back into `INFERNAL` unless live evidence shows an old INFERNAL step is actually running.
- When adapting the paper to the user's local directories, keep rRNA and tRNA branches separate: `Barrnap` for current rRNA detection and `tRNAscan-SE` for tRNA. Do not use tRNA summaries as proof that the original `INFERNAL`/`cmsearch` branch is valid or worth rerunning.
- Chimerism: GUNC thresholds were used to exclude chimeric MAGs.
- Taxonomic consistency: CAT/BAT compared contig-level taxonomy against MAG-level taxonomy.
- Isolate validation: Mash, MUMmer `dnadiff`, QUAST and genome dot plots compared MAGs to cultured isolates from the same ecosystem.

MIMAG quality criteria used by the paper:

- Medium-quality MAG: >=50% completeness and <10% contamination.
- High-quality draft MAG: >90% completeness, <5% contamination, 5S/16S/23S rRNAs and at least 18 tRNAs.
- Near-complete MAG: same as high quality except the rRNA requirement.

## Dereplication And Taxonomy

Main logic:

- Use dRep to remove redundancy and define species-level representative genomes.
- Select representatives by completeness, contamination and N50.
- Prefer isolate genomes over MAGs when both fall into the same species cluster.
- Use GTDB-Tk for taxonomy.
- Define novelty by comparison with GTDB and previous skin MAG catalogues.

Key thresholds and commands from the paper:

- dRep primary clustering for highly similar genomes: `-pa 0.999`, `-nc 0.30`, `--SkipSecondary -cm larger -comp 90 -con 5`.
- dRep species-level clustering: `-pa 0.9`, `-sa 0.95`, `-nc 0.30`, `-cm larger`, `-comp 50`, `-con 5`.
- Species-level match to isolate or fungal reference: at least 30% aligned fraction and at least 95% ANI.

## Functional Characterization

The functional branch was genome-centric:

- Protein-coding genes in MAGs were predicted with Prokka.
- Pan-genomes of near-complete conspecific genomes were analysed with Panaroo.
- Genome metabolism was annotated with DRAM.
- KEGG pathway characterization used HMMER `hmmscan` against KOfam models.
- KEGG pathway completeness per genome was computed as the percentage of required KOs detected.
- Bacterial pathways with >80% completeness were kept for downstream analysis.

Important interpretation:

- This paper does not use a single eggNOG-only functional annotation workflow for all conclusions.
- It separates gene prediction, pan-genome analysis, DRAM metabolic annotation and KOfam pathway completeness.
- For the user's `meta-anno` workflows, eggNOG remains useful for broad orthology/function transfer, but SMGC shows that genome-centric biological claims need pathway completeness, MAG quality and abundance/prevalence evidence.

## Eukaryotic Branch

The paper did not treat eukaryotic genomes as ordinary bacterial MAGs.

Workflow:

- Start from CONCOCT bins generated from the original SPAdes contigs.
- Filter bins with EukRep to retain bins with significant eukaryotic DNA, specifically >1 Mbp of eukaryotic bases.
- Estimate completeness and contamination with EukCC.
- Keep eukaryotic MAGs with >=50% completeness and <5% contamination.
- Dereplicate fungal MAGs with dRep.
- Inspect differential coverage and GC content with anvi'o and exclude apparent chimeras.
- Compare fungal MAGs to GenBank fungi using Mash and MUMmer.
- Build Malassezia phylogeny using BUSCO single-copy marker genes, MUSCLE, trimAl and IQ-TREE.

Workflow implication:

- If the user asks for a multi-kingdom annotation workflow, do not push every input through the same bacterial ORF route.
- Eukaryotic contigs or bins need eukaryote-aware classification, completeness and phylogenomics. This is consistent with the user's rule that eukaryotic input should use `metaeuk` in prediction-stage discussions.

## Viral Branch

The viral component was handled as a separate discovery and characterization branch.

Workflow:

- Detect viral sequences with VIRify on unbinned metagenome assemblies, with minimum length 5 kb.
- Dereplicate viral sequences with CD-HIT-EST at 90% nucleotide identity using local alignment settings.
- Assess viral quality with CheckV.
- Keep viral sequences if they are high-confidence by VIRify, medium quality or higher by CheckV, or contain more viral genes than host genes by CheckV.
- Identify jumbo phages as Myoviridae or Siphoviridae bacteriophages longer than 200 kb.
- Compare viral novelty against IMG/VR and the Gut Phage Database using BLASTn.
- Classify viral contigs with DemoVir.
- Cluster viral proteins with vContact2 using DIAMOND mode against RefSeq prokaryotic viruses.
- Predict viral proteins with Prodigal before protein-content clustering.
- Functionally characterize jumbo phages with eggNOG in DIAMOND mode.
- Link phages to hosts using CRISPRCasFinder spacers from prokaryotic MAGs and BLASTn against the viral catalogue.

Workflow implication:

- Viral or mobile-element analysis should be separate from ordinary bacterial functional annotation.
- For this skill, do not collapse viral discovery, host prediction and phage functional annotation into plain eggNOG or CAZy annotation.

## Read Mapping, Presence And Abundance

The paper used read mapping back to the genome catalogue to quantify species presence and abundance.

Rules:

- BWA-MEM mapped reads to isolates, bacterial MAGs, eukaryotic MAGs and viruses.
- Bacterial/fungal species presence required at least 30% genome breadth coverage.
- Relative abundance used primary alignments where at least 60% of the read aligned with at least 90% identity.
- Correctly paired reads were counted with SAMtools filters including mapping quality and proper-pair constraints.
- Abundance was normalized as RPKM.
- Viral presence required 75% of the viral contig covered at >=90% identity.
- Kraken2 comparisons used `--confidence 0.1`.

Workflow implication:

- Presence/absence should not be inferred from a single best-hit annotation row.
- For catalogue-based claims, require genome breadth or contig breadth thresholds plus read-level evidence.

## Biological Findings To Preserve

- Actinobacteriota was the most represented phylum in the SMGC.
- Novel species contributed about 26% more phylogenetic diversity to known skin bacteria.
- Corynebacterium contained many newly identified skin species.
- The uncultured genus QFNR01 was named "Candidatus Pellibacterium"; an abundant member was named "Candidatus Pellibacterium faciei".
- Some uncultured skin bacteria were depleted in aerobic respiration pathways, suggesting strict anaerobes or low oxygen tolerance as one reason they are hard to culture.
- Common skin genera can have substantial strain-level and pan-genome diversity; Corynebacterium and Staphylococcus showed high rates of gene gain per strain.
- Staphylococcus had pathways related to multidrug resistance; Corynebacterium had distinctive amino-acid, vitamin, glycogen and trehalose-related pathways.
- The eukaryotic branch recovered Malassezia diversity, including novel species, and did not detect protists in the analysed datasets.
- The viral branch found extensive viral novelty and 20 jumbo phages, many associated with foot sites and skin-associated bacterial hosts.

## How To Use This In Meta-Anno Responses

When the user asks how this paper should change a workflow, answer with these principles:

- Start with input type and biological kingdom. Do not run one generic annotation route for bacteria, eukaryotes and viruses.
- For catalogue construction, assembly/binning/dereplication/quality control come before functional annotation.
- Use multiple assembly strategies when the goal is maximal genome recovery, but pair pooling with chimerism and contig-taxonomy checks.
- Use genome quality metrics before interpreting functional profiles.
- Use read-mapping breadth thresholds to support prevalence and abundance claims.
- Treat specialized branches separately: prokaryotic MAGs, eukaryotic MAGs and viral contigs need different tools and validation logic.
- Keep eggNOG as broad functional evidence, not the sole basis for genome-centred claims.
- For skin datasets, SMGC can be treated as a reference catalogue or conceptual model for improving classification, not as a replacement for eggNOG, CARD, CAZy or VFDB.
- Preserve the user's existing prediction-stage rule unless explicitly asked to critique it: mixed FASTA uses `prodigal`, separated prokaryotic input uses `prodigal`, eukaryotic input uses `metaeuk`, bacterial input uses `genomad`, and large FASTA should be split with `seqkit` before memory-heavy annotation.

When adapting the paper to the user's scripts, separate these questions:

- Are we annotating an existing `.faa` file? Then use the current eggNOG/DIAMOND/RGI/CAZy/VFDB workflow and resource checks.
- Are we building a genome catalogue from contigs or reads? Then add assembly, binning, dereplication, MAG quality and read-mapping validation before treating annotations as biological conclusions.
- Are the sequences bacterial, eukaryotic or viral/mobile? Then route them through different prediction/detection branches instead of forcing one ORF predictor.
- Are we claiming prevalence or abundance? Then require read-mapping breadth/identity thresholds, not just an annotation hit.

## Common Mistakes To Avoid

- Do not call SMGC an annotation database like eggNOG or CARD. It is primarily a skin microbial genome/viral catalogue with annotations.
- Do not generalize SMGC to non-skin biomes without saying the domain changed.
- Do not present pooled assembly as automatically superior; it improves recovery but requires chimerism checks.
- Do not discard taxa from a catalogue only because they appear in negative controls; first consider read breadth, expected skin commensals, bleed-through and control behaviour.
- Do not compare catalogues only by species count; read assignment, novelty, genome quality, N50, contamination, chimerism and body-site coverage all matter.
- Do not infer biological function from presence of a gene alone when the paper used pathway completeness and genome-level context.
