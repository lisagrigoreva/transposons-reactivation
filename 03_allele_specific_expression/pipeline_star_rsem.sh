#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=20G
#SBATCH --time=12:00:00
#SBATCH --qos="long"
#SBATCH --array=1-434
#SBATCH --wait-all-nodes=1 #wait till nodes is finish job
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/allelespec_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/allelespec_%A_%a.err

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
sample_list_unique=${WORKDIR}/longread_genomes/names.txt
sample_u=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $sample_list_unique | cut -f1)
# Concatinate accessions to pseudogenome
#cat ${OUTDIR}/longread_genomes/${sample_u}.Chr_scaffolds.fa ${OUTDIR}/longread_genomes/TAIR10.fa  > ${OUTDIR}/longread_genomes/pseudogenomes_concatinated/${sample_u}.pseudogenome.fa
# Prepare gff. Flip names of chromosome so it matches assembly 
#for file in *_based_on_TAIR10.gff; do     sed -i 's/^\([^_]*\)_\(Chr[0-9]*\)/\2_\1/' "$file"; done
# Concatinate with tair10 gff file 
# Add _tair10 to the chromosome name 
#sed -e 's/^Chr\([0-9]*\)/Chr\1_tair10/' TAIR10_GFF3_genes_transposons.gff > TAIR10_GFF3_genes_transposons_name_changed.gff
# Remove chromosome from gff annotation 
#sed -i '/\tchromosome\t/d' TAIR10_GFF3_genes_transposons_name_changed.gff
#cat ${OUTDIR}/converted_gff2_tair10_based/${sample_u}_based_on_TAIR10.gff ${OUTDIR}/converted_gff2_tair10_based/TAIR10_GFF3_genes_transposons_name_changed.gff  > ${OUTDIR}/converted_gff2_tair10_based/pseudogenomes_gff/${sample_u}.pseudogenome.gff


# Convert to gtf
#awk 'BEGIN{OFS="\t"}
# Skip transposon fragments
#$3 == "transposon_fragment" {next}
# For transposable_element, create gene → transcript → exon hierarchy
#$3 == "transposable_element" {
#    match($9, /ID=([^;]+)/, id)
#    te_id = id[1]
#    # Print as gene
#    $3 = "gene"
#    $9 = "ID="te_id";Name="te_id
#    print
#    # Print as mRNA/transcript
#    $3 = "mRNA"
#    $9 = "ID="te_id".1;Parent="te_id";Name="te_id
#    print
#    # Print as exon
#    $3 = "exon"
#    $9 = "ID="te_id".1.exon1;Parent="te_id".1"
#    print
#    next
#}
## Keep all other lines (genes, exons, etc.) as-is
#{print}
#' ${OUTDIR}/converted_gff2_tair10_based/pseudogenomes_gff/${sample_u}.pseudogenome.gff > ${OUTDIR}/converted_gff2_tair10_based/pseudogenomes_gff/${sample_u}.pseudogenome_te_as_genes.gff

# Convert to gtf 
#gffread ${OUTDIR}/converted_gff2_tair10_based/pseudogenomes_gff/${sample_u}.pseudogenome_te_as_genes.gff -T -o ${OUTDIR}/converted_gff2_tair10_based/pseudogenomes_gff/${sample_u}.pseudogenome_te_as_genes.gtf &&

# Add genome name to the gene id 
#mkdir -p modified_gtf
#for gtf in *_te_as_genes.gtf; do
#    echo "Processing $gtf"
#    awk -F'\t' -v OFS='\t' '{split($1,a,"_"); s="_"a[2]; $9=gensub(/"([^"]+)"/, "\"\\1"s"\"", "g", $9); print}' "$gtf" > "modified_gtf/${gtf}"
#    echo "Created: modified_gtf/${gtf}"
#done
#echo "All files processed!"


#### STAR alignment ###
ml build-env/f2022 star/2.7.11a-gcc-12.3.0 &&
#ml build-env/f2022 gffread/0.12.7-gcccore-12.2.0 
# Make indixies 
ulimit -n 10000

#STAR_TMP="/tmp/star_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
#mkdir -p $STAR_TMP
#cd $STAR_TMP

STAR --runMode genomeGenerate \
     --genomeDir ${OUTDIR}/star_alignment_pseudogenomes/indixies/${sample_u} \
     --genomeFastaFiles ${OUTDIR}/longread_genomes/pseudogenomes_concatinated/${sample_u}.pseudogenome.fa --sjdbGTFfile ${OUTDIR}/converted_gff2_tair10_based/pseudogenomes_gff/modified_gtf/${sample_u}.pseudogenome_te_as_genes.cleaned.gtf --sjdbOverhang 59 --runThreadN 8 --genomeSAindexNbases 12 &&

# Check if STAR succeeded

STAR \
--runMode alignReads \
--twopassMode Basic \
--runThreadN 30 \
--outFilterMismatchNoverLmax 0.1 \
--outFilterMultimapNmax 10 \
--outFilterIntronMotifs RemoveNoncanonical \
--outSAMattributes NH HI AS nM NM MD jM jI XS \
--outSAMtype BAM SortedByCoordinate \
--bamRemoveDuplicatesType UniqueIdenticalNotMulti \
--outSAMprimaryFlag AllBestScore \
--genomeDir "${OUTDIR}/star_alignment_pseudogenomes/indixies/tair10_only" \
--readFilesIn /groups/nordborg/projects/ddm1_resilencing/03_processing/003_umi_dedup/all_plates_96w/${fastq_raw}_S*.dedup.woumi.fastq \
--outReadsUnmapped Fastx \
--outFilterScoreMinOverLread 0.4 \
--outFilterMatchNminOverLread 0.4 \
--quantMode TranscriptomeSAM \
--quantTranscriptomeBan Singleend \
--alignIntronMax 1 \
--alignIntronMin 2 \
--scoreDelOpen -10000 \
--scoreInsOpen -10000 \
--alignEndsType EndToEnd \
--outFileNamePrefix ${OUTDIR}/star_alignment_pseudogenomes_to_tair10_only_a_b/${fastq_raw}

#Run RSEM generate reference
#ml build-env/2020 rsem/1.3.3-foss-2018b
#rsem-prepare-reference --gtf  ${OUTDIR}/converted_gff2_tair10_based/pseudogenomes_gff/modified_gtf/${sample_u}.pseudogenome_te_as_genes.cleaned.gtf --num-threads 4 ${OUTDIR}/longread_genomes/pseudogenomes_concatinated/${sample_u}.pseudogenome.fa  ${OUTDIR}/quantification_rsem/indixies/${sample_u} --transcript-to-gene-map ${OUTDIR}/converted_gff2_tair10_based/pseudogenomes_gff/modified_gtf/${sample_u}.transcript_to_gene.txt

## Quantify with rsem 

#rsem-calculate-expression \
#    --bam \
#    --no-bam-output \
#    --alignments \
#    --forward-prob 1 \
#    --estimate-rspd \
#    --seed 12345 \
#    "${OUTDIR}/star_alignment_pseudogenomes/${fastq_raw}Aligned.toTranscriptome.out.bam" \
#    "${OUTDIR}/quantification_rsem/indixies/${sample}" \
#    "${OUTDIR}/quantification_rsem/as_forw/${fastq_raw}"
