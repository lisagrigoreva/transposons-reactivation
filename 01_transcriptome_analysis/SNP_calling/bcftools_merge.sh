#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=50G
#SBATCH --time=50:00:00
#SBATCH --qos="long"
#SBATCH --array=1
#SBATCH --wait-all-nodes=1 #wait till nodes is finish job
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/gatk_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/gatk_%A_%a.err

#Load modules
ml build-env/f2022 bcftools/1.17-gcc-12.2.0
#Label directories
workdir="/groups/nordborg/projects/ddm1_resilencing"
al_dir="${workdir}/03_processing/004_alignment/all_plates_96w"
outdir="${workdir}/03_processing/006_snp_call/bcftools"


# Collect all trimmed R1 files from the specified directory
ALL_FILES=(${al_dir}/*Aligned.sortedByCoord.out.bam)


# Calculate the total number of files
TOTAL_FILES=${#ALL_FILES[@]}
if [ $TOTAL_FILES -eq 0 ]; then
    echo "No  files found."
    exit 1
fi

# Check if the current task ID is within the range of available files
i=$SLURM_ARRAY_TASK_ID
if [ $i -gt $TOTAL_FILES ]; then
    echo "Task ID $i exceeds the number of available files ($TOTAL_FILES). Exiting."
    exit 0
fi

# Get the file to process for this task
FS=${ALL_FILES[$((i-1))]}
FQBase=$(basename -s Aligned.sortedByCoord.out.bam $FS)
ref="/groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/TAIR10_chr_all.fas"
# Merge files
#bcftools index ${outdir}/${FQBase}.vcf.gz 
bcftools merge -o ${outdir}/merged.vcf.gz  ${outdir}/*.vcf.gz &&
# Index 
bcftools index -t ${outdir}/merged.vcf.gz
