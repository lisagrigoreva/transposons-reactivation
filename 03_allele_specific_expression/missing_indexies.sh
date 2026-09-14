#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=70G
#SBATCH --time=08:00:00
#SBATCH --array=1
#SBATCH --wait-all-nodes=1 #wait till nodes is finish job
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/allelespec_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/allelespec_%A_%a.err


ml build-env/f2022 star/2.7.11a-gcc-12.3.0

WORKDIR=/groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression
OUTDIR=/groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression
# Match assembly id
#awk -F'\t' 'NR==FNR {map[$2]=$1; next} FNR==1 {print "Assembly_ID\tSample_id\tAccession"; next} $3 in map {print map[$3]"\t"$2"\t"$3}' filtered_best_version.txt <(sed 's/,/\t/g' tm3_phenotype_preprocessed_based_on_pca_with_selfers_v2.csv) > matched_output.txt
# Read sample list - get the sample ID from first column based on array task ID
sample_list=${WORKDIR}/longread_genomes/matched_output.txt
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $sample_list | cut -f1)
fastq_raw=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $sample_list | cut -f2)
accession_raw=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $second_list_for_quant | cut -f3)

# Make a unique samplelist
sample_list_unique=/groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression/star_alignment_pseudogenomes/indixies/missing_star_indices.txt
sample_u=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $sample_list_unique | cut -f1)


ulimit -n 10000

STAR --runMode genomeGenerate \
     --genomeDir ${OUTDIR}/star_alignment_pseudogenomes/indixies/${sample_u} \
     --genomeFastaFiles ${OUTDIR}/longread_genomes/pseudogenomes_concatinated/${sample_u}.pseudogenome.fa --sjdbGTFfile ${OUTDIR}/converted_gff2_tair10_based/pseudogenomes_gff/modified_gtf/${sample_u}.pseudogenome_te_as_genes.fixed.gtf --sjdbOverhang 59 --runThreadN 8 --genomeSAindexNbases 12 --genomeChrBinNbits 16 
