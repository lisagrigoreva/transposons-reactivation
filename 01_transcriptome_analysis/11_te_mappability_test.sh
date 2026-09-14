cd /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome
# Select TEs bed 
awk -F'\t' 'BEGIN{OFS="\t"}
$3 == "exon" {
    id = $9
    sub(/.*Parent=/, "", id)
    sub(/;.*/, "", id)
    print $1, $4-1, $5, id, ".", $7
}' TAIR10_TE_synthetic.gff > TEs.bed  

# Extract strand orientation
bedtools getfasta \
    -fi TAIR10.fa \
    -bed TEs.bed \
    -s \
    -name \
    > TEs.fa
# Get first 60 bp
seqkit subseq -r 1:60 TEs.fa > TEs_first60bp.fa
#Mapping, calculate matches
bowtie-build TAIR10.fa TAIR10_bowtie_index

bowtie \
    -f \
    -v 0 \
    -a \
    --best \
    --strata \
    TAIR10_bowtie_index \
    TEs_first60bp.fa \
    > TEs_first60bp_all_hits.txt 
cut -f1 TEs_first60bp_all_hits.txt | sort | uniq -c > TEs_first60bp_hit_counts.txt
