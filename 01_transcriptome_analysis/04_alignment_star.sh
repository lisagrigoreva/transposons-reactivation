#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=100G
#SBATCH --qos="medium"
#SBATCH --partition="m"
#SBATCH --wait-all-nodes=1
#SBATCH --time=08:00:00
#SBATCH --array=1-2044
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/star_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/star_%A_%a.err
# Load modules
ml build-env/f2022 star/2.7.11a-gcc-12.3.0
# Create .gtf annotation with an opposite strand 
#./04_create_gtf_of_genes_and_tes_star.sh
# Construct indixies for STAR
#STAR --runMode genomeGenerate --runThreadN 8 --genomeDir /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/star_indixies_tari10_te_flipped --genomeFastaFiles /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/TAIR10_chr_all.fas --genomeSAindexNbases 12 --sjdbGTFfile /groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/TAIR10_genes_transposons_with_opposite.gtf --sjdbOverhang 59
# Directories
workdir="/groups/nordborg/projects/ddm1_resilencing"
indir="${workdir}/03_processing/003_umi_dedup/all_plates_96w"
outdir="${workdir}/03_processing/004_alignment/all_plates_96w/with_tes_flipped"
indexies="${workdir}/11_resources/ref_genome/star_indixies_tari10_te_flipped"
failed_log_dir="${outdir}/failed_logs"

mkdir -p "$failed_log_dir"
mkdir -p "$outdir"

# Get the input file for this array task
FS=$(ls "${indir}"/*.dedup.woumi.fastq.gz | sed -n "${SLURM_ARRAY_TASK_ID}p")

# Check if file exists
if [ -z "$FS" ] || [ ! -f "$FS" ]; then
    echo "ERROR: File not found for task ID ${SLURM_ARRAY_TASK_ID}" >&2
    exit 1
fi

# Get base name
FQBase=$(basename "$FS" .dedup.woumi.fastq.gz)

# Debug output
echo "Processing task: ${SLURM_ARRAY_TASK_ID}"
echo "Input file: ${FS}"
echo "Base name: ${FQBase}"
ls -lh "${FS}"

# Set ulimit
ulimit -n 20000

# Run STAR
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
--genomeDir "${indexies}" \
--readFilesIn "${FS}" \
--readFilesCommand zcat \
--outFilterScoreMinOverLread 0.4 \
--outFilterMatchNminOverLread 0.4 \
--quantMode TranscriptomeSAM \
--quantTranscriptomeBan IndelSoftclipSingleend \
--alignEndsType EndToEnd \
--alignIntronMax 1 \
--alignIntronMin 2 \
--limitBAMsortRAM 3338414228 \
--scoreDelOpen -10000 \
--scoreInsOpen -10000 \
--outFileNamePrefix "${outdir}/${FQBase}"

# Collect STAR statistics 
#awk '
#BEGIN {
#    print "sample_id\tinput_reads\tuniquely_mapped_reads"
#}
#FNR==1 {
#    sample = FILENAME
#    sub(/_S[0-9]+.*$/, "", sample)
#}
#/Number of input reads/ {
#    split($0, a, "\t")
#    input_reads = a[2]
#    gsub(/^[ \t]+|[ \t]+$/, "", input_reads)
#}
#/Uniquely mapped reads number/ {
#    split($0, a, "\t")
#    unique_reads = a[2]
#    gsub(/^[ \t]+|[ \t]+$/, "", unique_reads)
#    print sample "\t" input_reads "\t" unique_reads
#}
#' *Log.final.out

## Check mapping bias 
#samtools index ${outdir}/${FQBase}Aligned.sortedByCoord.out.bam 
## Create bigwig files
#bamCoverage --bam "${outdir}/${FQBase}Aligned.sortedByCoord.out.bam" --outFileName "${outdir}/mapping_bias/${FQBase}.CPM.bw" --normalizeUsing CPM

