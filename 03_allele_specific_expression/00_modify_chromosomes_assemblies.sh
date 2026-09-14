# Add accession identifier to the chromosomes
for f in *.Chr_scaffolds.fa; do
id=$(basename "$f" .Chr_scaffolds.fa) \
sed -i "/^>/ s/>Chr\([0-9]*\)/>Chr\1_${id}/" "$f";  done
# Replace tair10 as well
sed -i '/^>/ s/^>Chr\([0-9]*\).*/>Chr\1_tair10/' TAIR10_chr_all.fas
