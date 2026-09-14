#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=30G
#SBATCH --time=20:00:00
#SBATCH --partition=m
#SBATCH --qos="long"
#SBATCH --array=1
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/pannagram_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/pannagram_%A_%a.err

# Activate environment
#conda activate pannagram
# Run pannagram
pannagram -cores 5 -path_in  /groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression/pacbio_genomes  -path_out  /groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression/pannagram_tair10_based_pacbiogenomes -nchr 5 -one2one -ref 'TAIR10'
