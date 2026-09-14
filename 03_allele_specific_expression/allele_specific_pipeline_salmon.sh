#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5G
#SBATCH --time=03:00:00
#SBATCH --array=1-378
#SBATCH --wait-all-nodes=1 #wait till nodes is finish job
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/allelespec_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/allelespec_%A_%a.err


ml build-env/f2022 bedtools/2.30.0-gcc-12.2.0
ml build-env/f2022 salmon/1.10.1-gcc-12.2.0

WORKDIR=/groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression
OUTDIR=/groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression
# Read sample list - get the sample ID from first column based on array task ID
sample_list=${WORKDIR}/quantification/accessions_intersect_with_ddm1_dataset_unique.txt
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $sample_list | cut -f1)

second_list_for_quant=${WORKDIR}/quantification/sample_map_for_quant.txt
sample_raw=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $second_list_for_quant | cut -f1)
fastq_raw=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $second_list_for_quant | cut -f2)
accession_raw=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $second_list_for_quant | cut -f3)

# Convert to cdna
#agat_sp_extract_sequences.pl -g ${WORKDIR}/converted_gff2/${sample}.based_on_TAIR10_flipped.gff -f ${WORKDIR}/genomes/${sample}.renamed.Chr_scaffolds.fa -o ${OUTDIR}/cdna_genomes_liftov/${sample}.cdna.fasta --cdna
# Keep only full transcripts
#awk '
#/^>.*-Protein/ {skip=1; next}
#/^>/ {skip=0; print $1; next}
#!skip
#' ${OUTDIR}/cdna_genomes_liftov/${sample}.cdna.fasta > ${OUTDIR}/cdna_genomes_liftov/${sample}.cdna.clean.fasta
#Add name to the gene
#for i in *.cdna.clean.fasta; do     sample=$(basename "$i" .cdna.clean.fasta);     awk -v s="$sample" '/^>/ {print $1"_"s; next} {print}' "$i" > "${i}.tmp" && mv "${i}.tmp" "$i"; done

# Extract TE
#cat ${WORKDIR}/converted_gff2/${sample}.based_on_TAIR10_flipped.gff | grep 'TE' | grep -v 'gene' > ${OUTDIR}/cdna_genomes_liftov/${sample}.based_on_TAIR10_flipped.onlyte.gff
# Extract fasta of TEs
#bedtools getfasta -fi ${WORKDIR}/genomes/${sample}.renamed.Chr_scaffolds.fa -bed ${OUTDIR}/cdna_genomes_liftov/${sample}.based_on_TAIR10_flipped.onlyte.gff -s -nameOnly  > ${OUTDIR}/cdna_genomes_liftov/${sample}.te.fasta
# Remove strand info from the fasta file
#for i in *.te.fasta; do sed -i 's/(.*//g' $i ; done
#Add name to the gene
#for i in *.te.fasta; do     sample=$(basename "$i" .te.fasta);     awk -v s="$sample" '/^>/ {print $1"_"s; next} {print}' "$i" > "${i}.tmp" && mv "${i}.tmp" "$i"; done

# Combine tes and genes into one cdna for accession
#cat ${OUTDIR}/cdna_genomes_liftov/${sample}.te.fasta  ${OUTDIR}/cdna_genomes_liftov/${sample}.cdna.clean.fasta  > ${OUTDIR}/cdna_genomes_liftov/${sample}_tes_and_cdna_with_ids.fasta
# Make a pseudogenome (te+cdna tair10)+ (te_cdna accession)
#awk '/^>/ {print $1"_tair10"; next} {print}' Arabidopsis_thaliana.TAIR10.cdna.all_with_tes.fa > temp.fa && mv temp.fa Arabidopsis_thaliana.TAIR10.cdna.all_with_tes.fa
#cat ${OUTDIR}/cdna_genomes_liftov/Arabidopsis_thaliana.TAIR10.cdna.all_with_tes.fa ${OUTDIR}/cdna_genomes_liftov/${sample}_tes_and_cdna_with_ids.fasta > ${OUTDIR}/cdna_genomes_liftov/${sample}_tes_and_cdna_pseudogenome.fasta


### QUANTIFICATION ###
# Make decoys
#grep "^>" ${WORKDIR}/concatinated_genomes/${sample}_renamed.concatenated.fasta > ${OUTDIR}/quantification/${sample}.decoys.txt 
#sed -i 's/>//g' ${OUTDIR}/quantification/${sample}.decoys.txt

# Make a gentrome
#cat ${OUTDIR}/cdna_genomes_liftov/${sample}_tes_and_cdna_pseudogenome.fasta ${WORKDIR}/concatinated_genomes/${sample}_renamed.concatenated.fasta  > ${OUTDIR}/quantification/${sample}.gentrome.fasta &&
# Create an index 
#salmon index -t ${OUTDIR}/quantification/${sample}.gentrome.fasta -d ${OUTDIR}/quantification/${sample}.decoys.txt -p 12 -i ${OUTDIR}/quantification/${sample}.salmon_index --keepDuplicates

# Create a tx2gene object
#grep '^>' ${OUTDIR}/cdna_genomes_liftov/${sample}_tes_and_cdna_pseudogenome.fasta  > ${OUTDIR}/quantification/${sample}.headers.txt 
#grep ">" ${OUTDIR}/quantification/${sample}.headers.txt | sed 's/>//' | awk '{print $0 "\t" $0}' | sed 's/\.[0-9]\+_/_/2' > ${OUTDIR}/quantification/${sample}.tx2gene.txt

# Perform quantification
salmon quant -l SF -i ${OUTDIR}/quantification/${sample_raw}.salmon_index -r /groups/nordborg/projects/ddm1_resilencing/03_processing/003_umi_dedup/all_plates_96w/${fastq_raw}_S*.dedup.woumi.fastq -p 10 --softclip --noLengthCorrection -o ${OUTDIR}/counts/${fastq_raw} --hardFilter --validateMappings --geneMap ${OUTDIR}/quantification/${sample_raw}.tx2gene.txt 
