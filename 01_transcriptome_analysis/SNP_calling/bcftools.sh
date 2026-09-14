#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5G
#SBATCH --time=02:00:00
#SBATCH --array=1-2040
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
samtools index ${FS}

#bcftools mpileup --min-MQ 20 -a FORMAT/DP,FORMAT/AD --skip-indels -f ${ref} ${FS} -d 1000 | bcftools call -m | bcftools norm -m -both -f ${ref}  -Oz -o ${outdir}/${FQBase}.temp.vcf.gz &&
#bcftools index ${outdir}/${FQBase}.temp.vcf.gz &&
# Filter for biallelic and non variable sites and chromosomes
#bcftools view -m1 -M2 -r Chr1,Chr2,Chr3,Chr4,Chr5 ${outdir}/${FQBase}.temp.vcf.gz -Oz -o ${outdir}/${FQBase}.vcf.gz &&
# Clean up
#rm ${outdir}/${FQBase}.temp.vcf.gz
# Index files 
#bcftools index ${outdir}/${FQBase}.vcf.gz
