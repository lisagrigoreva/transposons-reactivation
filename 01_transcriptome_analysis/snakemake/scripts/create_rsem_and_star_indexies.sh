
## This script creates a GTF for genes and TEs with the opposite direction of TEs ###
## and indexies for STAR and RSEM ##

# 1. Drop TE fragments and raw TEs from annotation
awk -F'\t' '$3 != "transposon_fragment" && $3 != "transposable_element"' \
  TAIR10_GFF3_genes_transposons.gff > TAIR10_genes_only.gff

# 2. Convert the gene set to GTF
gffread TAIR10_genes_only.gff -T -o TAIR10_genes_only.gtf

# 3. Create a synthenic gene_id/transcript_id for TEs, written directly as GTF. Each TE should carry a transcript and exon in order to be quantified 
awk -F'\t' 'BEGIN{OFS="\t"}
$3 == "transposable_element" && $9 ~ /ID=|Parent=/ {
    id = $9
    if (match(id, /Parent=[^;]+/)) {
        tid = substr(id, RSTART+7, RLENGTH-7)
    } else if (match(id, /ID=[^;]+/)) {
        tid = substr(id, RSTART+3, RLENGTH-3)
    } else next
    if (tid in seen) next
    seen[tid] = 1
    attr = "gene_id \"" tid "\"; transcript_id \"" tid ".1\";"
    print $1, $2, "transcript", $4, $5, $6, $7, ".", attr
    print $1, $2, "exon",       $4, $5, $6, $7, ".", attr
}' TAIR10_GFF3_genes_transposons.gff > TAIR10_TE_synthetic.gtf

# 4. For TEs flip the strand. TEs can be expressed from non-cannonical to annotation strand 
awk -F'\t' 'BEGIN{OFS="\t"}
$9 ~ /AT[1-5]TE[0-9]+/ {
    $7 = ($7 == "+") ? "-" : "+"
    gsub(/AT[1-5]TE[0-9]+/, "&_OP", $9)
    print
}' TAIR10_TE_synthetic.gtf > TAIR10_TEs_OP.gtf

# 5. Combine: genes + cannonical strand TEs + non-cannonical strand TEs
cat TAIR10_genes_only.gtf TAIR10_TE_synthetic.gtf TAIR10_TEs_OP.gtf \
  > TAIR10_TE_genes_synthetic_with_OP_direction.gtf

## Create indexies 
# STAR
STAR --runMode genomeGenerate --runThreadN 8 \
--genomeDir /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/star_index \
--genomeFastaFiles /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/TAIR10_chr_all.fas \
--genomeSAindexNbases 12 \
--sjdbGTFfile /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/TAIR10_TE_genes_synthetic_with_OP_direction.gtf \
--sjdbOverhang 100

# RSEM
rsem-prepare-reference --gtf TAIR10_TE_genes_synthetic_with_OP_direction.gtf \
--num-threads 4 TAIR10_chr_all.fas ./rsem_index_with_opposite_orientation_te_col0/TAIR10_chr_all