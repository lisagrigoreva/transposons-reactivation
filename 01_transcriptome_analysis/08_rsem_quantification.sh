#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH --partition="m"
#SBATCH --qos="medium"
#SBATCH --wait-all-nodes=1
#SBATCH --time=15:00:00
#SBATCH --array=1-2041
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/rsem_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/rsem_%A_%a.err

ml build-env/2020 rsem/1.3.3-foss-2018b

workdir="/groups/nordborg/projects/ddm1_resilencing/"
indir="${workdir}/03_processing/004_alignment/all_plates_96w/with_tes_flipped"
outdir="${workdir}/03_processing/005_quant/rsem/sense_with_flipped_tes"

## Make rsem quantification
# Prepare genome 
# cd /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome
# Get transcript-to-gene map
#awk -F'\t' '$3=="transcript"{
#  match($9, /transcript_id "([^"]+)"/, t);
#  match($9, /gene_id "([^"]+)"/, g);
#  print g[1]"\t"t[1]
#}' TAIR10_TE_genes_synthetic_with_OP_direction.gtf > transcript_to_gene.tsv

#rsem-prepare-reference --gtf TAIR10_TE_genes_synthetic_with_OP_direction.gtf --num-threads 4 TAIR10_chr_all.fas --transcript-to-gene-map transcript_to_gene.tsv ./rsem_index_with_opposite_orientation_te_col0/

#Get samples
BAM=$(ls ${indir}/*_S*Aligned.toTranscriptome.out.bam | sed -n "${SLURM_ARRAY_TASK_ID}p")
rsem_ref=${workdir}/11_resources/ref_genome/rsem_index_with_opposite_orientation_te_col0/TAIR10_chr_all
FQBase=$(basename "$BAM" Aligned.toTranscriptome.out.bam)

rsem-calculate-expression \
    --bam \
    --no-bam-output \
    --alignments \
    --forward-prob 1 \
    --estimate-rspd \
    -p 8 \
    --seed 12345 \
    "${BAM}" \
    "${rsem_ref}" \
    "${outdir}/${FQBase}"

echo "RSEM quantification completed for ${FQBase}"
