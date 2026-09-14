#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=80G
#SBATCH --time=04:00:00
# IMPORTANT: set this to the number of lines in sample_id_doesntexist.txt
#SBATCH --array=1-25
#SBATCH --wait-all-nodes=1
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/gatk_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/gatk_%A_%a.err

set -euo pipefail

# Load modules
ml build-env/f2022 bcftools/1.17-gcc-12.2.0

# Paths
workdir="/groups/nordborg/projects/ddm1_resilencing"
al_dir="${workdir}/03_processing/004_alignment/all_plates_96w"
outdir="${workdir}/03_processing/006_snp_call/bcftools"
ref="${workdir}/11_resources/ref_genome/TAIR10_chr_all.fas"
ids_file="${workdir}/03_processing/006_snp_call/bcftools/sample_id_doesntexist.txt"

mkdir -p "${outdir}"

# Map array index to sample ID (line number == SLURM_ARRAY_TASK_ID)
i=${SLURM_ARRAY_TASK_ID}
sample_id=$(sed -n "${i}p" "${ids_file}" | tr -d '[:space:]')

if [ -z "${sample_id}" ]; then
  echo "No sample ID at line ${i} in ${ids_file}. Exiting."
  exit 0
fi

# Build BAM path. Your BAMs end with this suffix:
suffix="Aligned.sortedByCoord.out.bam"

# Many pipelines name BAMs like "<sample_id>_...Aligned.sortedByCoord.out.bam".
# Try exact match first, then a glob that allows extra parts after the sample_id.
bam_exact="${al_dir}/${sample_id}${suffix}"
bam=""

if [ -f "${bam_exact}" ]; then
  bam="${bam_exact}"
else
  # Allow extra bits between sample_id and suffix (e.g., 299100_S1_L002_Aligned.sortedByCoord.out.bam)
  pattern="${al_dir}/${sample_id}"*"${suffix}"
  shopt -s nullglob
  matches=( ${pattern} )
  shopt -u nullglob

  if [ ${#matches[@]} -eq 0 ]; then
    echo "BAM not found for ${sample_id} (patterns tried: ${bam_exact} and ${pattern}). Skipping."
    exit 0
  elif [ ${#matches[@]} -gt 1 ]; then
    echo "Multiple BAMs found for ${sample_id}:"
    printf ' - %s\n' "${matches[@]}"
    # To avoid ambiguity, exit. If you prefer, pick the first match by uncommenting:
    # bam="${matches[0]}"
    exit 1
  else
    bam="${matches[0]}"
  fi
fi

if [ ! -f "${bam}" ]; then
  echo "Resolved BAM path is not a file: ${bam}"
  exit 1
fi

# Base name for outputs
FQBase=$(basename -s "${suffix}" "${bam}")

echo "Processing ${sample_id} -> ${bam}"

# bcftools pipeline
bcftools mpileup --min-MQ 20 -a FORMAT/DP,FORMAT/AD --skip-indels -f "${ref}" "${bam}" -d 1000 \
| bcftools call -m \
| bcftools norm -m -both -f "${ref}" -Oz -o "${outdir}/${FQBase}.temp.vcf.gz" && \
bcftools index "${outdir}/${FQBase}.temp.vcf.gz" && \
bcftools view -m1 -M2 -r Chr1,Chr2,Chr3,Chr4,Chr5 "${outdir}/${FQBase}.temp.vcf.gz" -Oz -o "${outdir}/${FQBase}.vcf.gz" && \
rm -f "${outdir}/${FQBase}.temp.vcf.gz" "${outdir}/${FQBase}.temp.vcf.gz.tbi"
