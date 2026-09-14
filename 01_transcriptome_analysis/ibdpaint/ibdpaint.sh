#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=15G
#SBATCH --time=08:00:00
#SBATCH --array=1-2044
#SBATCH --wait-all-nodes=1 #wait till nodes is finish job
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/snp_match_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/snp_match_%A_%a.err

#Label directories
workdir="/groups/nordborg/projects/ddm1_resilencing/03_processing/006_ibd_paint"
outdir="/groups/nordborg/projects/ddm1_resilencing/03_processing/006_ibd_paint/out_vs_1001_6981_maternal"
i=$SLURM_ARRAY_TASK_ID
sample_file="${workdir}/expected_parents.txt"
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$sample_file")

line=$(sed -n "${i}p" "$sample_file")
col0=$(echo "$line" | awk '{print $1}')
col1=$(echo "$line" | awk '{print $2}')
col2=$(echo "$line" | awk '{print $3}')
expected_match="${col1} ${col2}"

# Run ibdpainting with the extracted columns
ibdpainting -i ${workdir}/progeny_subset.h5 -r ${workdir}/parents_subset.h5 --window_size 500000 --sample_name $col0 --expected_match $expected_match --outdir ${outdir} --interactive
