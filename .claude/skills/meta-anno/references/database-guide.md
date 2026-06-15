# Annotation Database Guide

Use this file when explaining what each annotation database contains, what biological question it answers, and how to interpret hits. This is conceptual guidance for the user's current workflow; exact database releases and local paths should still be verified from the server.

## Overview

The table includes both functional annotation databases and reference catalogues. SMGC is a skin microbiome catalogue/resource, not a direct replacement for eggNOG, CARD, CAZy or VFDB.

| Resource | Main question answered | Input in this workflow | Main evidence type | Typical output interpretation |
| --- | --- | --- | --- | --- |
| CAZy / CAZyme | What carbohydrate-active enzyme families are present? | Protein ORFs `.faa` | Protein homology to CAZy families | Glycoside hydrolases, glycosyltransferases, carbohydrate esterases, polysaccharide lyases, auxiliary activities, binding modules |
| eggNOG | What broad functional, orthology, pathway, and domain annotations fit each protein? | Protein ORFs `.faa` | Orthology transfer from eggNOG groups | COG category, description, gene name, GO, EC, KEGG, BRITE, CAZy, PFAM |
| CARD via RGI | Which antimicrobial resistance genes or resistance-associated variants are present? | Cleaned protein ORFs `.faa` | CARD resistance models and curated ARO ontology | AMR gene family, drug class, resistance mechanism, strict/perfect/loose hit class |
| VFDB | Which bacterial/prokaryotic virulence-factor-like genes are present? | Bacterial/prokaryotic protein ORFs `.faa` | Protein homology to bacterial virulence factor sequences | Candidate virulence factor IDs, genes, and related pathogenicity functions |
| FungAMR | Which fungi-branch virulence-factor candidates are present in this workflow? | MetaEuk fungi protein `.faa` | DIAMOND protein homology against the FungAMR resource | Candidate fungi virulence-factor matches for downstream review |
| SMGC | Which skin microbial genomes/viral contigs can improve skin read classification and catalogue-based interpretation? | Reads, assemblies, MAGs, isolate genomes, viral contigs | Skin-specific genome and viral catalogue from cultivation plus metagenomics | Improved skin read assignment, genome-centred prevalence/abundance, skin-specific taxa and viral diversity |

## CAZy / CAZyme

CAZy is a curated database of carbohydrate-active enzymes. In this workflow, the user builds a DIAMOND database from a CAZy protein FASTA such as:

```text
/mnt/cephfs/s2z1/db/CAZy/CAZy-V14.fa
```

The DIAMOND result maps ORF proteins to CAZy-like reference proteins or family labels.

Main CAZy classes:

| Class | Meaning | Biological interpretation |
| --- | --- | --- |
| `GH` | Glycoside Hydrolases | Degrade glycosidic bonds; carbohydrate degradation potential |
| `GT` | GlycosylTransferases | Build glycosidic bonds; biosynthesis of glycans, polysaccharides, cell wall components |
| `PL` | Polysaccharide Lyases | Cleave uronic-acid-containing polysaccharides |
| `CE` | Carbohydrate Esterases | Remove ester modifications from carbohydrates |
| `AA` | Auxiliary Activities | Redox enzymes supporting lignocellulose/carbohydrate breakdown |
| `CBM` | Carbohydrate-Binding Modules | Non-catalytic binding domains that target enzymes to carbohydrate substrates |

Interpretation notes:

- CAZy hits suggest enzyme family membership, not necessarily full substrate specificity.
- High identity and long alignment are more convincing than identity alone.
- `CBM` domains can appear with catalytic domains, e.g. `CBM48|GH13_8`.
- The user's DIAMOND command uses `--max-target-seqs 1`, so only the top hit is retained.

## eggNOG

eggNOG is an orthology-based functional annotation resource. It groups genes/proteins into orthologous groups across taxonomy and transfers functional annotations from known genes to query proteins.

In this workflow, eggNOG mapper is used in two major ways:

- DIAMOND mode for seed ortholog search and annotation.
- MMseqs mode for large batch annotation with `--dbmem`.

Main data contained in eggNOG annotations:

| Field family | What it represents |
| --- | --- |
| Orthology | `seed_ortholog`, `eggNOG_OGs`, taxonomic annotation levels |
| Functional category | COG single-letter categories such as metabolism, information storage, cellular processes |
| Description/name | Human-readable description and preferred gene/protein name |
| GO | Gene Ontology molecular function, biological process, cellular component terms |
| EC | Enzyme Commission numbers for enzymatic reactions |
| KEGG | KO, pathway, module, reaction, reaction class, BRITE hierarchy |
| CAZy | CAZy family annotations propagated through eggNOG |
| PFAM | Protein domains/families |
| BiGG | Metabolic model reaction links |

Interpretation notes:

- eggNOG is broad functional annotation. It is not specialized for AMR or virulence.
- Orthology transfer can be wrong for paralogs, short proteins, fragmented ORFs, or distant homologs.
- `max_annot_lvl` helps judge how specific the transferred annotation is.
- Missing optional fields are normal; a row with many `-` values can still be a valid annotation row.
- The seed ortholog table is evidence for the annotation table, not the final biological summary by itself.

## CARD / RGI

CARD is the Comprehensive Antibiotic Resistance Database. It contains curated antimicrobial resistance genes, resistance variants, antibiotics, drug classes, mechanisms, and the Antibiotic Resistance Ontology (ARO). RGI is the tool used to query sequences against CARD models.

In this workflow:

```bash
sed 's/\*//g' input.faa > clean.faa
rgi main --input_sequence clean.faa --input_type protein --alignment_tool DIAMOND --local --include_nudge
```

Main CARD/RGI concepts:

| Concept | Meaning |
| --- | --- |
| `ARO` | Antibiotic Resistance Ontology identifier |
| `Best_Hit_ARO` | Best matching resistance model/gene name |
| `Drug Class` | Antibiotic class affected |
| `Resistance Mechanism` | Mechanism such as target alteration, efflux, inactivation, protection |
| `AMR Gene Family` | Resistance gene family grouping |
| `Cut_Off` | Confidence class such as Perfect, Strict, or Loose |
| `Nudged` | Whether a loose hit was promoted by RGI nudge logic |

Interpretation notes:

- CARD/RGI is specialized for AMR. Prefer it over generic eggNOG descriptions when asking AMR-specific questions.
- `Strict` and `Perfect` hits are stronger than `Loose` hits.
- `--include_nudge` can promote a high-identity loose hit into strict; report this nuance.
- Protein input should not contain trailing `*` stop symbols, hence the cleaning step.
- A hit indicates similarity to a resistance model; downstream abundance/prevalence requires mapping/counting, not just presence in one ORF set.

## VFDB

VFDB is the Virulence Factor Database. It contains experimentally verified and predicted virulence factors from bacterial pathogens, such as toxins, secretion systems, adhesion factors, invasion factors, capsules, iron uptake systems, immune evasion factors, and motility-related virulence components.

For this workflow, restrict VFDB virulence annotation to the bacterial/prokaryotic branch. Do not use it as the fungi virulence-factor database.

The user's notes distinguish:

| VFDB set | Meaning | Tradeoff |
| --- | --- | --- |
| Set A / Core | Experimentally verified representative virulence factors | More conservative, higher precision |
| Set B / Full | Expanded set including homologs and alleles | Higher recall, more false positives |

In this workflow, VFDB Set B protein FASTA is converted to a DIAMOND database:

```text
/mnt/cephfs/s2z1/db/VFDB2025/VFDB_setB_pro.fas
```

Interpretation notes:

- VFDB DIAMOND hits are candidate virulence-factor homologs.
- High identity, long alignment, and low e-value are stronger.
- Homology alone does not prove phenotype or pathogenicity in the sample.
- Set B is useful for screening but should be filtered more carefully than Set A.
- `sseqid` often contains a `VFG...` identifier and an accession such as `gb|WP_...`.

## FungAMR

In the user's workflow, FungAMR is the designated resource for fungi-branch virulence-factor annotation.

- Input: validated fungi protein FASTA produced by MetaEuk.
- Search: prepare a DIAMOND database from the FungAMR protein FASTA when needed, then run `diamond blastp`.
- Preserve the original database FASTA; write any header-cleaned database FASTA as a derived file.
- Keep original TSV output and generate a source-specific CSV only after validation.
- Do not replace FungAMR with bacterial VFDB merely because VFDB is already installed.

## How To Choose Which Database To Trust

Use the database that matches the biological question:

| Question | Prefer |
| --- | --- |
| Broad gene function and pathways | eggNOG |
| Carbohydrate metabolism and glycan degradation/synthesis | CAZy/CAZyme DIAMOND, with eggNOG CAZy as secondary support |
| Antibiotic resistance | CARD/RGI |
| Bacterial/prokaryotic virulence factors | VFDB |
| Fungi-branch virulence factors | FungAMR |
| Protein domains | eggNOG PFAM field or a direct Pfam workflow if available |
| Skin microbiome genome catalogue, MAG comparison, or skin read classification | SMGC-style catalogue/reference mapping; see `references/smgc-2021-natmicrobiol.md` |

When databases disagree:

1. Check whether the query alignment is long enough and not just a small domain.
2. Check identity, e-value, and bitscore.
3. Check whether the specialized database applies to the question.
4. Prefer specialized curated databases for AMR/virulence/CAZyme calls.
5. Keep broad eggNOG descriptions as context, not as the only evidence.

## Local Database Provenance Checklist

When diagnosing unexpected results, ask Claude Code to verify:

```bash
ls -lh /path/to/db
stat /path/to/db
diamond dbinfo --db /path/to/db 2>/dev/null || true
emapper.py --version
rgi database --version 2>/dev/null || true
```

If `diamond dbinfo` is not available in the installed DIAMOND version, fall back to file size, timestamp, command history, and build logs.

Record:

- Database name and release if available.
- Source FASTA path.
- Build command.
- Build date or file timestamp.
- Tool version used to build/search it.
- Whether the search used Set A/Core, Set B/Full, or a custom subset.
