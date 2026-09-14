#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=200G
#SBATCH --partition="m"
#SBATCH --qos="long"
#SBATCH --time=08:00:00
#SBATCH --array=1-46
#SBATCH --wait-all-nodes=1
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/umi_collapse_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/umi_collapse_%A_%a.err

ml build-env/f2022 bbmap/39.08-gcc-12.2.0

# Label directories
workdir="/groups/nordborg/projects/ddm1_resilencing"
indir="${workdir}/03_processing/002_trimming/all_plates_96w/controls"
outdir="${workdir}/03_processing/003_umi_dedup/all_plates_96w/controls"
logfile="${outdir}/processing_log.txt"
failed_log_dir="${outdir}/failed_logs"
mkdir -p "$failed_log_dir"
mkdir -p "$outdir"

# Function to log failures
log_failure() {
    local step=$1
    local input_file=$2
    local error_log=$3
    echo "FAILED: ${step} failed for ${input_file}" >> "${logfile}.${SLURM_ARRAY_TASK_ID}"
    # Copy detailed error information to failed_logs directory
    cp "${error_log}" "${failed_log_dir}/${FQBase}_${step}_error.log"
}

# Collect all R1 files from the specified directory
ALL_R1_FILES=(${indir}/*_R1.trimmed.cleaned.fastq)

# Calculate the total number of files
TOTAL_FILES=${#ALL_R1_FILES[@]}
if [ $TOTAL_FILES -eq 0 ]; then
    echo "No R1 files found." >&2
    exit 1
fi

# Check if the current task ID is within the range of available files
i=$SLURM_ARRAY_TASK_ID
if [ $i -gt $TOTAL_FILES ]; then
    echo "Task ID $i exceeds the number of available files ($TOTAL_FILES). Exiting." >&2
    exit 0
fi

# Get the file to process for this task
FS=${ALL_R1_FILES[$((i-1))]}
FQBase=$(basename -s _R1.trimmed.cleaned.fastq $FS)

# Define output file paths
added_umi_file="${outdir}/${FQBase}.addedumi.fastq"
dedup_file="${outdir}/${FQBase}.dedup.fastq"
final_output="${outdir}/${FQBase}.dedup.woumi.fastq"

# Define error log files for each step
umi_error_log="${failed_log_dir}/${FQBase}_umi_add.log"
dedup_error_log="${failed_log_dir}/${FQBase}_dedup.log"
remove_umi_error_log="${failed_log_dir}/${FQBase}_remove_umi.log"

# Add UMI to the header
python 03_add_umi.py "$FS" "$added_umi_file" 2> "$umi_error_log" &&
if [[ $? -ne 0 || ! -f "$added_umi_file" ]]; then
    log_failure "UMI_addition" "$FS" "$umi_error_log"
    exit 1
fi

# Deduplicate
clumpify.sh -ea -Xmx29634m -Xms29634m in="$added_umi_file" out="$dedup_file" dedupe addcount subs=2 2> "$dedup_error_log" &&
if [[ $? -ne 0 || ! -f "$dedup_file" ]]; then
    log_failure "Deduplication" "$added_umi_file" "$dedup_error_log"
    exit 1
fi

# Remove UMI
python 03_remove_umi.py "$dedup_file" "$final_output" 2> "$remove_umi_error_log"
if [[ $? -ne 0 || ! -f "$final_output" ]]; then
    log_failure "UMI_removal" "$dedup_file" "$remove_umi_error_log"
    exit 1
fi

# Check final output and clean up logs if successful
if [[ -f "$final_output" ]]; then
    echo "SUCCESS: $FS → $final_output" >> "${logfile}.${SLURM_ARRAY_TASK_ID}"
    # Clean up error logs if successful
    rm -f "$umi_error_log" "$dedup_error_log" "$remove_umi_error_log"
else
    echo "FAILED: $FS did not generate expected output." >> "${logfile}.${SLURM_ARRAY_TASK_ID}"
fi
