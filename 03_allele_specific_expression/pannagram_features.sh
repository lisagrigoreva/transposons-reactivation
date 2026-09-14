#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=40G
#SBATCH --time=100:00:00
#SBATCH --partition=m
#SBATCH --qos="long"
#SBATCH --array=1
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/pannagram_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/pannagram_%A_%a.err

features -path_project /groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression/pannagram_tair10_based  -ref 'TAIR10' -seq -blocks -snp  -cores 10 
