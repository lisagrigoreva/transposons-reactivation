cd /scratch-cbe/users/elizaveta.grigoreva/ddm1_resilencing/processing/snakemake_run/

echo -e "sample\tinput_reads\treads_after_filtering\tpercent_retained" > trimming_summary.tsv

for log in logs/fastp/*_trim.log; do
    sample=$(basename "$log" _trim.log)
    awk -v s="$sample" '
        /^Read1 before filtering:/ {blk="before"}
        /^Read1 after filtering:/  {blk="after"}
        /^total reads:/ {
            if (blk=="before") inp=$3
            else if (blk=="after") out=$3
        }
        END {
            if (inp>0) printf "%s\t%d\t%d\t%.2f\n", s, inp, out, 100*out/inp
        }' "$log"
done >> trimming_summary.tsv

column -t trimming_summary.tsv | head
awk -F'\t' 'NR>1 {s+=$4; n++} END {printf "Samples: %d  Mean retention: %.2f%%\n", n, s/n}' trimming_summary.tsv
