#!/usr/bin/env bash

# Combine per chromosome VCF files into one.
# Rename the samples in the VCF files to remove absolute paths and suffixes

# Input: VCF files for each chromosome separately for all the samples
# Output: A single VCF file

# Script by Elizaveta Grigoreva, adapting code from Tom Ellis 12 Jan 2026

# SLURM
#SBATCH --job-name=merge_VCF
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/%x.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/%x.err
#SBATCH --mem=10GB
#SBATCH --qos=medium
#SBATCH --time=20:00:00

# Set working directory

# === Input data === #
ml build-env/f2022 bcftools/1.17-gcc-12.2.0

# Directory containing SNP calls for each chromosome separately.

indir=/groups/nordborg/projects/ddm1_resilencing/03_processing/006_snp_call/bcftools_mpileup
# VCF files for each chromosome separately
VCF_chr1=$indir/F1_snp_matrix_Chr1.vcf.gz
VCF_chr2=$indir/F1_snp_matrix_Chr2.vcf.gz
VCF_chr3=$indir/F1_snp_matrix_Chr3.vcf.gz
VCF_chr4=$indir/F1_snp_matrix_Chr4.vcf.gz
VCF_chr5=$indir/F1_snp_matrix_Chr5.vcf.gz

# === Define outputs === #

# Directory for the output files
outdir=$indir/merge_VCF
mkdir -p $outdir
# File name for the concatenated SNP matrix
vcf_with_full_paths=$outdir/snp_matrix_full_paths.vcf.gz
vcf_with_sample_names=$outdir/snp_matrix.vcf.gz
# Directory to stage out the resulting SNP matrix
# === Script === #

# Concatenate VCF files
#rm $vcf_with_full_paths
bcftools concat \
    -o $vcf_with_full_paths \
    $VCF_chr1 $VCF_chr2 $VCF_chr3 $VCF_chr4 $VCF_chr5
if [ $? -eq 0 ] ; then echo "Concatenating VCF files completed successfully"; fi

# Rename the samples to remove absolute paths and .bam suffixes
# Create text files giving the old and new names
#bcftools query -l $vcf_with_full_paths > $outdir/header_names.txt # Old names
#sed  -i 's|/groups/nordborg/projects/ddm1_resilencing/03_processing/004_alignment/all_plates_96w/controls/||g' header_names.txt  # New names
#sed  -i 's|/groups/nordborg/projects/ddm1_resilencing/03_processing/004_alignment/all_plates_96w/||g' header_names.txt
#sed -i 's/_.*//g' header_names.txt

# Swap the names
#bcftools reheader \
#    -s $outdir/header_names.txt  \
#    -o $vcf_with_sample_names \
#    $vcf_with_full_paths
#if [ $? -eq 0 ] ; then echo "Renamed samples successfully"; fi
# Index the VCF file
#tabix $vcf_with_sample_names
