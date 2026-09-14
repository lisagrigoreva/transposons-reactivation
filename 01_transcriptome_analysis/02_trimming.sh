#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=20G
#SBATCH --time=08:00:00
#SBATCH --array=1-70
#SBATCH --wait-all-nodes=1
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/bbduk_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/bbduk_%A_%a.err

ml build-env/2020
ml bbmap/38.26-foss-2018b

# Label directories
workdir="/groups/nordborg/projects/ddm1_resilencing"
indir="${workdir}/03_processing/001_umi_extract/all_plates_96w/additional_seq_20250807"
outdir="${workdir}/03_processing/002_trimming/all_plates_96w/additional_seq_20250807"
logfile="${outdir}/processing_log.txt"
failed_log_dir="${outdir}/failed_logs"
mkdir -p "$failed_log_dir"

# Collect all R1 files from the specified directory
ALL_R1_FILES=(${indir}/*_R1.umi_added.fastq.gz)

# Calculate the total number of files
TOTAL_FILES=${#ALL_R1_FILES[@]}
if [ $TOTAL_FILES -eq 0 ]; then
    echo "No R1 files found."
    exit 1
fi

# Check if the current task ID is within the range of available files
i=$SLURM_ARRAY_TASK_ID
if [ $i -gt $TOTAL_FILES ]; then
    echo "Task ID $i exceeds the number of available files ($TOTAL_FILES). Exiting."
    exit 0
fi

# Get the file to process for this task
FS=${ALL_R1_FILES[$((i-1))]}
FQBase=$(basename -s _R1.umi_added.fastq.gz $FS)
truseqad=${workdir}/11_resources/BBMap/resources/nextera.fa.gz
polya=${workdir}/11_resources/BBMap/resources/polyA.fa.gz


# Define output file paths
OUT="${outdir}/${FQBase}_R1.trimmed.cleaned.fastq"
FASTP_LOG="${failed_log_dir}/${FQBase}_fastp.log"

# Create output directory if it does not exist
mkdir -p ${outdir}

fastp -i "$FS" -o  "$OUT" --trim_poly_x --length_required 50 --max_len1 60 --adapter_fasta /groups/nordborg/projects/ddm1_resilencing/02_scripts/20241209_quantify_TM3_with_tag_seq_pipeline/adapter_fasta_for_fastp.fasta

# **Check if output files were created and log results**
if [[ -f "$OUT" ]]; then
    echo "SUCCESS: $FS → $OUT" >> "${logfile}.${SLURM_ARRAY_TASK_ID}"
    [[ -n "$FASTP_LOG" && -f "$FASTP_LOG" ]] && rm -f "$FASTP_LOG"  # Remove log only if defined and exists
else
    echo "FAILED: $FS did not generate expected output. See $FASTP_LOG" >> "${logfile}.${SLURM_ARRAY_TASK_ID}"
fi


