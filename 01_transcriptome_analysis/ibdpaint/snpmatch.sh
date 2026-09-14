#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10G
#SBATCH --time=08:00:00
#SBATCH --array=1-1969
#SBATCH --wait-all-nodes=1 #wait till nodes is finish job
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/snp_match_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/snp_match_%A_%a.err

#Upload module
ml build-env/2020
ml snpmatch/3.0.1-foss-2018b-python-2.7.15
#Label directories
workdir="/groups/nordborg/projects/ddm1_resilencing/03_processing/006_snp_call/all_plates_96w/snpmatch"
outdir="/groups/nordborg/projects/ddm1_resilencing/03_processing/006_snp_call/all_plates_96w/snpmatch/results"
i=$SLURM_ARRAY_TASK_ID
sample_file="${workdir}/sample_names.txt"
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$sample_file")

#Do for each accession separately (separator of VCF file)
#IFS=$'\n';for LINE in $(cat acc_sample.txt); do sample=$(echo ${LINE} | awk '{ print $1}'); acc=$(echo ${LINE} | awk '{ print $2 }'); vcftools --vcf 10M.samples.SNPs.filtered_Chr1to5.vcf.recode.vcf --indv $sample --recode --out $acc; done
#Run SNPmatch
snpmatch cross -v -d /groups/nordborg/projects/the1001genomes/scratch/rahul/101.VCF_1001G_1135/1001genomes_snp-short-indel_only_ACGTN.BIALLELIC.hdf5 -e  /groups/nordborg/projects/the1001genomes/scratch/rahul/101.VCF_1001G_1135/1001genomes_snp-short-indel_only_ACGTN.BIALLELIC.acc.hdf5 -i ${workdir}/${sample}.filtered.biall.vcf -b 5000 -o ${outdir}/${sample}.out  --genome /groups/nordborg/projects/ddm1_resilencing/11_resources/snpmatch/athaliana_tair10.json
