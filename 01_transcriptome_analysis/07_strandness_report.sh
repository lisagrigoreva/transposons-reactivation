#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=30G
#SBATCH --wait-all-nodes=1
#SBATCH --time=08:00:00
#SBATCH --array=1-2040
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/infer_exp_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/infer_exp_%A_%a.err

# conda activate transcriptome

# Directories
workdir="/groups/nordborg/projects/ddm1_resilencing"
indir="${workdir}/03_processing/004_alignment/all_plates_96w"
outdir="${indir}/mapping_bias"
bed12="${workdir}/11_resources/ref_genome/te_transcripts.bed12"

# Get the input file for this array task
FS=$(ls "${indir}"/*Aligned.sortedByCoord.out.bam | sed -n "${SLURM_ARRAY_TASK_ID}p")

# Check if file exists
if [ -z "$FS" ] || [ ! -f "$FS" ]; then
    echo "ERROR: File not found for task ID ${SLURM_ARRAY_TASK_ID}" >&2
    exit 1
fi

# Extract sample base name
FQBase=$(basename "$FS" Aligned.sortedByCoord.out.bam)

# Set ulimit
ulimit -n 10000

# Infer library strandedness using annotated multi-exon genes
infer_experiment.py \
    -r "$bed12" \
    -i "$FS" \
    -q 30 \
    -s 200000 \
    > "${outdir}/${FQBase}.strandness_report_tes_mapq30.txt"
