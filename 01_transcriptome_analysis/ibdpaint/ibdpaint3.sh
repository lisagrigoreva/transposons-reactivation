#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5G
#SBATCH --time=08:00:00
#SBATCH --array=1
#SBATCH --wait-all-nodes=1 #wait till nodes is finish job
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/snp_match_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/snp_match_%A_%a.err

ml build-env/f2022 bcftools/1.17-gcc-12.2.0

workdir='

# Get a list of SNP positions in the VCF for the progeny
bcftools view --include 'AVG(FORMAT/DP)>=5' snp_matrix_clean_names.vcf.gz | bcftools query -f"%CHROM\t%POS\n" > progeny_snp_positions.txt
# Convert to BED format. Positions are given as Chr, Position, Position +1
awk '{print $1"\t"$2"\t"$2+1}' progeny_snp_positions.txt > progeny_snp_positions.bed
# Select only features labelled as coding genes in the GFF, and convert to BED
grep "Note=protein_coding_gene" TAIR10_GFF3_genes.gff | awk -F'\t' '{print $1"\t"$4"\t"$5}' > annotated_genes.bed
# Get only those SNPs that are inside genes.
# Bedtools intersect finds the SNPs inside genes, and awk reformats for bcftools
bedtools intersect -a progeny_snp_positions.bed -b annotated_genes.bed -wb | awk -F'\t' '{print $1"\t"$2}' > snps_in_genes.bed
# Make a correct bed format 
awk '{print $1"\t"$2"\t"$2}' snps_in_genes.bed > snps_regions.txt
# Subset the parental vcf 
bcftools view -R snps_regions.txt -O z -o parents_subset.vcf.gz 1163g.179kB.prior15.gauss4.ts99.5.BIALLELIC.heterozygous_acc_removed.hetmasked.vcf.gz
# Subset the progeny vcf 
bcftools view -R snps_regions.txt -O z -o progeny_subset.vcf.gz  snp_matrix_clean_names.vcf.gz
