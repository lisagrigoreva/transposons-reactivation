#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5G
#SBATCH --time=08:00:00
#SBATCH --array=1-2029
#SBATCH --wait-all-nodes=1 #wait till nodes is finish job
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/snp_match_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/snp_match_%A_%a.err

ml build-env/f2022 bcftools/1.17-gcc-12.2.0

#Label directories
workdir="/groups/nordborg/projects/ddm1_resilencing/03_processing/006_ibd_paint"
outdir="/groups/nordborg/projects/ddm1_resilencing/03_processing/006_ibd_paint/out"
i=$SLURM_ARRAY_TASK_ID
sample_file="${workdir}/expected_parents_wo_failed_sanger.txt"
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$sample_file")

line=$(sed -n "${i}p" "$sample_file")
id=$(echo "$line" | awk '{print $1}')
p1=$(echo "$line" | awk '{print $2}')
p22=$(echo "$line" | awk '{print $3}')
expected_match="${col1} ${col2}"

#bcftools index ${workdir}/${id}.vcf.gz 
#bcftools view -R ${workdir}/annotated_genes.bed -i 'MIN(FMT/DP)>=5' ${workdir}/${id}.vcf.gz | bcftools query -f"%CHROM\t%POS\n" > ${outdir}/${id}.snppos.txt
#awk '{print $1"\t"$2"\t"$2+1}' ${outdir}/${id}.snppos.txt > ${outdir}/${id}.snppos.bed
#Get min depth 5 and genic regions from vcf files
bcftools view -R ${outdir}/${id}.snppos.bed  ${workdir}/${id}.vcf.gz -Ob -o ${outdir}/${id}.depth5genes.bcf  &&
bcftools index ${outdir}/${id}.depth5genes.bcf



