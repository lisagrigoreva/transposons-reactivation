#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH --time=08:00:00
#SBATCH --array=1-70
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/umiextract_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/umiextract_%A_%a.err

# Label directories
workdir="/groups/nordborg/projects/ddm1_resilencing"
outdir="/groups/nordborg/projects/ddm1_resilencing/03_processing/001_umi_extract/all_plates_96w/additional_seq_20250807"
logfile="${outdir}/processing_log.txt"  # Log file for results
failed_log_dir="${outdir}/failed_logs"  # Directory for failed sample logs
mkdir -p "$failed_log_dir"

# Read the sample file
sample_file="${workdir}/01_data/96_plates_tm3_rnaseq/23553LLT3_5_R19136_20250807/sample_list.txt"
samples=($(cat "$sample_file"))

# Total number of samples
TOTAL_SAMPLES=${#samples[@]}

# Check if task ID is within range
i=$SLURM_ARRAY_TASK_ID

# If task ID exceeds available files
if [ "$i" -gt "$TOTAL_SAMPLES" ]; then
    echo "Task ID $i exceeds available files ($TOTAL_SAMPLES)." >> "${logfile}.${SLURM_ARRAY_TASK_ID}"
    exit 0
fi

# Get the sample from the list based on the task ID
sample=${samples[$((i-1))]}  # Adjusting for 0-based array index

# Define R1 and R2 file names based on the sample
R1_file="${sample}_R1_001.fastq.gz"
R2_file="${sample}_R2_001.fastq.gz"

# Check if R1 and R2 files exist
if [ ! -f "$R1_file" ]; then
    echo "R1 file $R1_file not found." >> "$logfile"
    exit 1
fi

if [ ! -f "$R2_file" ]; then
    echo "R2 file $R2_file not found." >> "$logfile"
    exit 1
fi

# Define output filenames for processing
FQBase1=$(basename -s _R1_001.fastq.gz "$R1_file")
FQBase2=$(basename -s _R2_001.fastq.gz "$R2_file")

OUT_R1="${outdir}/${FQBase1}_R1.umi_added.fastq.gz"
OUT_R2="${outdir}/${FQBase2}_R2.umi_added.fastq.gz"
FASTP_LOG="${failed_log_dir}/${FQBase1}_fastp.log"

# Run fastp and capture output
fastp -i "$R1_file" -o "$OUT_R1" -I "$R2_file" -O "$OUT_R2" --umi --umi_loc=read2 --umi_len=12 -Q -A -L --umi_prefix=UMI &> "$FASTP_LOG"

# Check if output files were created and log results
echo "Checking files: $OUT_R1 and $OUT_R2" >> "$logfile"
cat "$FASTP_LOG" >> "$logfile"
echo "Processing task ID: $SLURM_ARRAY_TASK_ID" >> "$logfile"
if [[ -f "$OUT_R1" && -f "$OUT_R2" ]]; then
    echo "SUCCESS: $R1_file → $OUT_R1 && $R2_file → $OUT_R2" >> "${logfile}.${SLURM_ARRAY_TASK_ID}"
    mv "$FASTP_LOG" "${failed_log_dir}/backup_${FQBase1}_fastp.log"
else
    echo "FAILED: $R1_file or $R2_file did not generate expected output. See $FASTP_LOG" >> "${logfile}.${SLURM_ARRAY_TASK_ID}"
fi
