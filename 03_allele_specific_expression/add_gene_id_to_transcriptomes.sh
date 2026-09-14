cd /groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression/converted_gff2_tair10_based/pseudogenomes_gff/modified_gtf
for file in *_as_genes.gtf; do
    output="${file%.gtf}.fixed.gtf"
    echo "Processing: $file -> $output"
    
    awk 'BEGIN{FS=OFS="\t"} 
    /^#/ || /^$/ {print; next}
    /gene_id/ {print; next}
    {
        if (match($9, /transcript_id "([^"]+)"/, arr)) {
            transcript_id = arr[1]
            if (match(transcript_id, /^([A-Z0-9]+)\.[0-9]+/, gene_arr)) {
                gene_id = gene_arr[1]
            } else {
                gene_id = transcript_id
            }
            $9 = "gene_id \"" gene_id "\"; " $9
        }
        print
    }' "$file" > "$output"
    
    echo "Done: $output"
    echo ""
done
