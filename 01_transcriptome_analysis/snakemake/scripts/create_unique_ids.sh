awk -F'\t' 'BEGIN{OFS="\t"} 
NR==1 {print $0, "unique_id"; next} 
{count[$1]++; print $0, $1"_"count[$1]}' samples.tsv > samples_uniq.tsv
