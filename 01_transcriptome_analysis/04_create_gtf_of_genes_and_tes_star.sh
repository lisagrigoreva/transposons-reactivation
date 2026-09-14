# Filter out transposable element fragment
grep -v -E 'transposon_fragment|transposable_element' TAIR10_GFF3_genes_transposons.gff > TAIR10_GFF3_genes_transposons.nofrag.gff
## Select transposons 
awk -F'\t' 'BEGIN{OFS="\t"}
$3 == "transposable_element" && $9 ~ /ID=|Parent=/ {
    id = $9
    if (match(id, /Parent=[^;]+/)) {
        tid = substr(id, RSTART+7, RLENGTH-7)
    } else if (match(id, /ID=[^;]+/)) {
        tid = substr(id, RSTART+3, RLENGTH-3)
    } else next

    if (!(tid in seen)) {
        seen[tid] = 1
        print $1, $2, "transcript", $4, $5, $6, $7, ".", "ID=" tid ".1;Parent=" tid ";"
        print $1, $2, "gene", $4, $5, $6, $7, ".", "ID=" tid ";"
    }
    print $1, $2, "exon", $4, $5, $6, $7, ".", "Parent=" tid ".1;"
}' TAIR10_GFF3_genes_transposons.gff > TAIR10_TE_synthetic.gff

## Get opposite strand of tes from .gff
awk -F'\t' 'BEGIN{OFS="\t"}
$9 ~ /AT[1-5]TE[0-9]+/ {
    strand = ($7 == "+") ? "-" : "+"
    $7 = strand
    gsub(/AT[1-5]TE[0-9]+(\.[0-9]+)?/, "&_OP", $9)
    print
}' TAIR10_TE_synthetic.gff > TAIR10_TEs_OP.gff
# Concatinate TE opposite and cannonical direction
cat TAIR10_TEs_OP.gff TAIR10_TE_synthetic.gff >  TAIR10_TE_synthetic_with_OP_direction.gff
## Add opposite direction TEs
cat TAIR10_GFF3_genes_transposons.nofrag.gff  TAIR10_TE_synthetic_with_OP_direction.gff >  TAIR10_TE_genes_synthetic_with_OP_direction.gff
# Convert to gtf 
gffread TAIR10_TE_genes_synthetic_with_OP_direction.gff -T -o TAIR10_TE_genes_synthetic_with_OP_direction.gtf
