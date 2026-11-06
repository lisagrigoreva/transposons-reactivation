
# Transcriptome Analysis of *Arabidopsis thaliana* F1 Hybrids

This code is accompanying following paper/s: 

> Grigoreva E., *et al.* (YEAR). *Title.* **Journal**. https://doi.org/xxx

## Overview

This project investigates parental effects and *cis*/*trans* regulation of transposable element (TE) expression in F1 hybrids of *Arabidopsis thaliana*. All crosses share a Col0 maternal background and are pollinated by a panel of natural accessions mainly from [1001G project](https://1001genomes.org/) :

- **Mutant set:** Col-0 *ddm1* (♀) × natural accession (♂)
- **Wild-type set:** Col-0 *DDM1* (♀) × natural accession (♂)

*DDM1* (*DECREASE IN DNA METHYLATION 1*) is required for TE silencing, so comparing the two sets reveals which TEs are reactivated in the mutant background and how re-activation and re-silencing depends on the paternal genotype.

## Data

## Computational pipelines

The repository is organised around three aims.

### 1. Differential expression of genes and TEs (*ddm1* vs wild type)

1. **[Read processing and quantification](01_transcriptome_analysis/snakemake)**: a Snakemake pipeline from raw sequencing `.tar` to gene- and TE-level counts.
2. **[Sample identity verification](02_ibdpaint/snakemake)**: SNP calling and IBD painting to confirm the parents of each F1 and exclude selfed or contaminated plants.
3. **[Filtering and differential expression](01_transcriptome_analysis/r_scripts)**: R scripts for expression filtering, normalisation and differential expression.

### 2. Phenotypes for GWAS
1. Heritability and phenotypes See [`<folder>`](<folder>).
2. GWAS runs with detection of the traget genes  [`<folder>`](<folder>).

### 3. Allele-specific expression

Allele-specific expression analysis in F1 hybrids using long-read genome assemblies of the paternal accessions. See [`<folder>`](<folder>).

### 4. An explicit model of re-silencing

## Authors and contributions

## Dependencies 







