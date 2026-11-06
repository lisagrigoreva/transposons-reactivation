#!/usr/bin/env bash
#SBATCH --job-name=pannagram
#SBATCH --cpus-per-task=40
#SBATCH --mem=450G
#SBATCH --time=02-00:00:00
#SBATCH --partition=m
#SBATCH --qos=long
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/pannagram_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/pannagram_%A_%a.err

# Activate environment
#conda activate pannagram
# Run pannagram
ulimit -n 10000
pannagram -path_genomes  /groups/nordborg/projects/ddm1_resilencing/03_processing/03_allele_specific_expression/ase_longreadgenomes/longreadgenomes -path_project   /groups/nordborg/projects/ddm1_resilencing/03_processing/03_allele_specific_expression/ase_longreadgenomes/pannagram_out_ref_free -cores 40 -refs '100000.Chr_scaffolds,100159.Chr_scaffolds' -nchr 5
