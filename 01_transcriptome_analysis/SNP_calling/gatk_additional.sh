#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=100G
#SBATCH --time=15:00:00
#SBATCH --qos="long"
#SBATCH --partition="m"
#SBATCH --array=1
#SBATCH --wait-all-nodes=1 #wait till nodes is finish job
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/gatk_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/gatk_%A_%a.err

#Load modules
ml build-env/f2021
ml gatk/4.2.6.1-gcccore-10.2.0-java-13
ml picard/2.27.1-java-13
#Label directories
workdir="/groups/nordborg/projects/ddm1_resilencing"
al_dir="${workdir}/03_processing/004_alignment/all_plates_96w/additional_seq_20250807"
outdir="${workdir}/03_processing/006_snp_call/all_plates_96w/additional_seq_20250807"


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


#Create sequence dictionary
#java -jar $EBROOTPICARD/picard.jar CreateSequenceDictionary R=${workdir}/11_resources/ref_genome/TAIR10_chr_all.fas  O=${workdir}/11_resources/ref_genome/TAIR10_chr_all.fas.genomic.dict &&
#Sort bam files picard
#java -jar $EBROOTPICARD/picard.jar SortSam CREATE_INDEX=true INPUT=${FS}  OUTPUT=${outdir}/${FQBase}.sorted.picard.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=STRICT &&

#Add or replace group
#java -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups I=${outdir}/${FQBase}.sorted.picard.bam O=${outdir}/${FQBase}.sorted.picard.addggroup.bam RGID=1 RGLB=lib1 RGPL=ILLUMINA RGPU=unit1 RGSM=${FQBase} &&

#Mark duplicates
#java -jar $EBROOTPICARD/picard.jar  MarkDuplicates  CREATE_INDEX=true INPUT=${outdir}/${FQBase}.sorted.picard.addggroup.bam  VALIDATION_STRINGENCY=STRICT O=${outdir}/${FQBase}.sorted.addgroup.picard.markeddupl.bam  METRICS_FILE=${outdir}/${FQBase}.duplmetrix.txt &&

#Split'N'Trim and reassign mapping qualities
#gatk SplitNCigarReads -R ${workdir}/11_resources/ref_genome/TAIR10_chr_all.fas -I ${outdir}/${FQBase}.sorted.addgroup.picard.markeddupl.bam -O ${outdir}/${FQBase}.sorted.addgroup.picard.markeddupl.split.bam &&

#Haplotypecaller
#gatk --java-options "-Xmx40g" HaplotypeCaller -R /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/TAIR10_chr_all.fas  -I ${outdir}/${FQBase}.sorted.addgroup.picard.markeddupl.split.bam -O ${outdir}/${FQBase}.variants_non_filter.g.vcf.gz -ERC GVCF

#CombineGVCF
#Create a map file
#find ${outdir} -name "*.variants_non_filter.g.vcf.gz" | while read vcf_path; do
#    # Extract sample name from filename
#    sample=$(basename "$vcf_path" | sed 's/.variants_non_filter.g.vcf.gz//')
    # Append to map file
#    echo -e "${sample}\t${vcf_path}" >> ${outdir}/map_file.txt
#done

#GenomicsDBImport
cd /groups/nordborg/projects/ddm1_resilencing/03_processing/006_snp_call/additional_seq_20250807
gatk --java-options "-Xmx80g" GenomicsDBImport --genomicsdb-workspace-path genomicdb --batch-size 20 --sample-name-map map_file.txt --reader-threads 10 -L TAIR10_chromosomes.bed 

#GenotypeGVCFs
#cd ${outdir}
#gatk --java-options "-Xmx80g" GenotypeGVCFs -R /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/TAIR10_chr_all.fas -V gendb://genomicdb -O ${outdir}/combined_db.vcf &&

#Select SNPs and non-variant sites
#gatk SelectVariants -R ${workdir}/11_resources/ref_genome/TAIR10_chr_all.fas -V ${outdir}/combined_db.vcf -O ${outdir}/genotyped.samples.snps.variant_non_variant.vcf  &&

#Filter
#gatk VariantFiltration \
#  -R /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/TAIR10_chr_all.fas \
#  -V ${outdir}/genotyped.samples.snps.variant_non_variant.vcf \
#  --filter-expression "QD < 2.0" \
#  --filter-name "SNP_QDlt2" \
#  --filter-expression "FS > 60.0" \
#  --filter-name "SNP_FSgt60" \
#  --filter-expression "MQ < 40.0" \
#  --filter-name "SNP_MQlt40" \
#  --filter-expression "MQRankSum < -12.5" \
#  --filter-name "SNP_MQRSneg12.5" \
#  --filter-expression "ReadPosRankSum < -8.0" \
#  --filter-name "SNP_RPRSneg8" \
#  --filter-expression "SOR > 4.0" \
#  --filter-name "SNP_SORgt4" \
#  -O ${outdir}/genotyped.samples.snps.variant_non_variant.filtered.vcf
