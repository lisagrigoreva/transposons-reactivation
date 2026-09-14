#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5G
#SBATCH --wait-all-nodes=1
#SBATCH --time=01:00:00
#SBATCH --array=1-2040
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/star_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/star_%A_%a.err

ml deeptools/3.5.4-foss-2022a
# Directories
workdir="/groups/nordborg/projects/ddm1_resilencing"
indir="${workdir}/03_processing/003_umi_dedup/all_plates_96w"
outdir="${workdir}/03_processing/004_alignment/all_plates_96w/mapping_bias"

# Get the input file for this array task
FS=$(ls "${indir}"/*.dedup.woumi.fastq.gz | sed -n "${SLURM_ARRAY_TASK_ID}p")

# Check if file exists
if [ -z "$FS" ] || [ ! -f "$FS" ]; then
    echo "ERROR: File not found for task ID ${SLURM_ARRAY_TASK_ID}" >&2
    exit 1
fi

# Get base name
FQBase=$(basename "$FS" .dedup.woumi.fastq.gz)

# Set ulimit
ulimit -n 10000

#Compute matrix of 3' bias for genes
computeMatrix reference-point \
    --referencePoint TES \
    -b 500 \
    -a 500 \
    -R "${workdir}/11_resources/ref_genome/genes_transcripts.bed" \
    -S "${outdir}/${FQBase}.CPM.bw" \
    --skipZeros \
    -o "${outdir}/${FQBase}.genes_TES_matrix.gz" &&
 
## For TEs
computeMatrix reference-point \
    --referencePoint TES \
    -b 500 \
    -a 500 \
    -R "${workdir}/11_resources/ref_genome/te_transcripts.bed" \
    -S "${outdir}/${FQBase}.CPM.bw" \
    --skipZeros \
    -o "${outdir}/${FQBase}.te_TES_matrix.gz"
