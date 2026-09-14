# Load the library
library(pannagram)

# Define variables
path.to.alignment <- '/groups/nordborg/projects/ddm1_resilencing/01_data/pacbio_genomes_1001_phase2/test_run_as/ref_free_alignment'
acc1 <- 'TAIR10'
acc2 <- '100752'

# Example input files
file.gff1 <- '/groups/nordborg/projects/ddm1_resilencing/01_data/pacbio_genomes_1001_phase2/test_run_as/TAIR10_TE_genes_synthetic_with_OP_direction.pannagram.gff'

# Read annotation/regions
gff1 <- read.table(file.gff1)

gff2.ref.free <- gff2gff(
    path.proj = path.to.alignment,
    acc1 = acc1,
    acc2 = acc2,
    gff1 = gff1
)
write.table(
    gff2.ref.free,
    file = "/groups/nordborg/projects/ddm1_resilencing/01_data/pacbio_genomes_1001_phase2/test_run_as/TAIR10_TE_genes_synthetic_with_OP_direction.100752.gff",
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = FALSE
)

## Rename chromosome
awk -F'\t' 'BEGIN{OFS="\t"}
{
    match($1, /Chr([0-9]+)/, arr)
    $1 = "Chr" arr[1] "_100752"
    print
}' TAIR10_TE_genes_synthetic_with_OP_direction.100752.gff > TAIR10_TE_genes_synthetic_with_OP_direction.100752.renamed_chr.gff


awk -F'\t' 'BEGIN{OFS="\t"}
{
    match($1, /Chr([0-9]+)/, arr)
    $1 = "Chr" arr[1] "_tair10"
    print
}' TAIR10_TE_genes_synthetic_with_OP_direction.gff > TAIR10_TE_genes_synthetic_with_OP_direction.renamed.gff
```
```
## Concatinate genomes 
cat TAIR10_TE_genes_synthetic_with_OP_direction.renamed.gff TAIR10_TE_genes_synthetic_with_OP_direction.100752.renamed_chr.gff > concatinated_genome_test.gff

# Convert to gtf 
gffread concatinated_genome_test.gff -T -o concatinated_genome_test.gtf
```


```
# add allele names 
awk -F'\t' 'BEGIN{OFS="\t"}
function tag(attr, key,   pre, val, post) {
    if (match(attr, key " \"[^\"]+\"") == 0) return attr
    pre  = substr(attr, 1, RSTART - 1)
    val  = substr(attr, RSTART + length(key) + 2, RLENGTH - length(key) - 3)
    post = substr(attr, RSTART + RLENGTH)
    return pre key " \"" val "_" suffix "\"" post
}
{
    suffix = $1
    sub(/^[^_]+_/, "", suffix)

    if ($9 !~ /gene_id "/ && match($9, /transcript_id "[^"]+"/)) {
        gid = substr($9, RSTART + 15, RLENGTH - 16)
        sub(/\.[0-9]+$/, "", gid)
        $9 = "gene_id \"" gid "\"; " $9
    }

    $9 = tag($9, "transcript_id")
    $9 = tag($9, "gene_id")
    print
}' concatinated_genome_test.gtf > concatinated_genome_test_withalleles.gtf

## Check that transcripts are ok orientation

awk -F'\t' 'BEGIN{OFS="\t"}
{
    if (match($9, /transcript_id "[^"]+"/)) {
        tid = substr($9, RSTART+16, RLENGTH-17)
    } else next
}
NR == FNR {
    if ($1 ~ /_100752$/) {
        if (tid in strand && strand[tid] != $7) bad[tid] = 1
        strand[tid] = $7
    }
    next
}
{
    if ($1 ~ /_100752$/ && tid in bad) next
    print
}' concatinated_genome_test_withalleles.gtf \
   concatinated_genome_test_withalleles.gtf \
> concatinated_genome_test_withalleles.filtered_orientation_transcripts.gtf
##Remove cholorplast and mitochondrial  transcripts
grep -vE 'gene_id "AT[MC][A-Z0-9]*_' concatinated_genome_test_withalleles.filtered_orientation_transcripts.gtf > concatinated_genome_test.filtered.with_gene_id.no_organelle.gtf

ml build-env/2020 rsem/1.3.3-foss-2018b
## run rsem 
rsem-prepare-reference --gtf concatinated_genome_test.filtered.with_gene_id.no_organelle.gtf  --num-threads 4 concatinated_genome_tair10_100752.fa  ./rsem_index/
```

## Run STAR
```{r}
ml build-env/f2022 star/2.7.11a-gcc-12.3.0
STAR --runMode genomeGenerate --runThreadN 8 --genomeDir ./star_indixies_tair10_100752  --genomeFastaFiles concatinated_genome_tair10_100752.fa  --genomeSAindexNbases 12 --sjdbGTFfile concatinated_genome_test.filtered.with_gene_id.no_organelle.gtf --sjdbOverhang 59
```

```
STAR \
--runMode alignReads \
--twopassMode Basic \
--runThreadN 30 \
--outFilterMismatchNoverLmax 0.1 \
--outFilterMultimapNmax 100 \
--winAnchorMultimapNmax 200 \
--outFilterIntronMotifs RemoveNoncanonical \
--outSAMattributes NH HI AS nM NM MD jM jI XS \
--outSAMtype BAM SortedByCoordinate \
--outSAMprimaryFlag AllBestScore \
--genomeDir ./star_indixies_tair10_100752 \
--readFilesIn /groups/nordborg/projects/ddm1_resilencing/03_processing/003_umi_dedup/all_plates_96w/300471_S105.dedup.woumi.fastq.gz \
--readFilesCommand zcat \
--outFilterScoreMinOverLread 0.4 \
--outFilterMatchNminOverLread 0.4 \
--quantMode TranscriptomeSAM \
--quantTranscriptomeBan IndelSoftclipSingleend \
--alignEndsType EndToEnd \
--alignIntronMax 1 \
--alignIntronMin 2 \
--scoreDelOpen -10000 \
--scoreInsOpen -10000 \
--outFileNamePrefix "star_alignment/300471"
```

```
# RSEM quantification
rsem-calculate-expression \
    --bam \
    --output-genome-bam \
    --alignments \
    --forward-prob 1 \
    --estimate-rspd \
    -p 8 \
    --seed 12345 \
    "./star_alignment/300471Aligned.toTranscriptome.out.bam" \
    "./rsem_index/index_tair10_100752" \
    "./rsem_quantification/300471"
``

