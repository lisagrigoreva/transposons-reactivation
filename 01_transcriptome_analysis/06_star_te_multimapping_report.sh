#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH --time=02:00:00
#SBATCH --array=1-2040
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/te_NH_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/te_NH_%A_%a.err

module purge
ml build-env/f2022 samtools/1.18-gcc-12.3.0
ml build-env/f2022 bedtools/2.31.1-gcc-13.2.0

workdir="/groups/nordborg/projects/ddm1_resilencing"
indir="${workdir}/03_processing/004_alignment/all_plates_96w"
outdir="${indir}/mapping_bias"
te_bed="${workdir}/11_resources/ref_genome/genes_transcripts.bed"

mkdir -p "$outdir"

BAM=$(ls "${indir}"/*Aligned.sortedByCoord.out.bam | sed -n "${SLURM_ARRAY_TASK_ID}p")

if [[ -z "$BAM" || ! -f "$BAM" ]]; then
    echo "ERROR: BAM not found for task ${SLURM_ARRAY_TASK_ID}" >&2
    exit 1
fi

FQBase=$(basename "$BAM" "Aligned.sortedByCoord.out.bam")
output="${outdir}/${FQBase}.gene_NH_summary.tsv"


# bamToBed with -tag NH puts the NH value directly in the score column (col 5)
# -F 0x804 excludes unmapped and supplementary alignments
{
    printf "sample\tTE_id\tTE_strand\tread_strand\torientation\tNH\tnumber_of_reads\n"

    samtools view -b -F 0x804 "$BAM" |
    bedtools bamtobed -i - -tag NH |
    bedtools intersect -a "$te_bed" -b - -wa -wb |
    awk -v sample="$FQBase" 'BEGIN{OFS="\t"}
        {
            te_strand=$6
            read_strand=$12
            nh=$11

            if (te_strand == read_strand) orient="sense"
            else orient="antisense"

            key=$4 OFS te_strand OFS read_strand OFS orient OFS nh
            count[key]++
        }
        END {
            for (k in count) print sample, k, count[k]
        }' |
    sort -k2,2 -k6,6n
} > "$output"
