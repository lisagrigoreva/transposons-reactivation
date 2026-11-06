#!/usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5G
#SBATCH --time=08:00:00
#SBATCH --array=1-10
#SBATCH --output=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/gemma_%A_%a.out
#SBATCH --error=/groups/nordborg/projects/ddm1_resilencing/09_slurm_logs/gemma_%A_%a.err

#conda activate umitools
ml gemma/0.98.1-foss-2018b

#Label directories
workdir='/groups/nordborg/projects/ddm1_resilencing/03_processing/006_gwas/all_plates_96w/gemma_gwas/221_acc_superfamilies_blups_per_te'
i=$SLURM_ARRAY_TASK_ID
FQ=${workdir}/dir.txt
FS=$(sed "${i}q;d" $FQ)

gemma -bfile ${workdir}/${FS}/1163g.179kB.prior15.gauss4.ts99.5.BIALLELIC.selected  -k ${workdir}/${FS}/1163g.179kB.prior15.gauss4.ts99.5.BIALLELIC.selected.cXX.txt -o ${FS}.col_blups_maf005  -lmm 4 -n 1 -maf 0.05 &&
gemma -bfile ${workdir}/${FS}/1163g.179kB.prior15.gauss4.ts99.5.BIALLELIC.selected  -k ${workdir}/${FS}/1163g.179kB.prior15.gauss4.ts99.5.BIALLELIC.selected.cXX.txt -o ${FS}.ddm1_blups_maf005 -lmm 4 -n 2 -maf 0.05 &&
gemma -bfile ${workdir}/${FS}/1163g.179kB.prior15.gauss4.ts99.5.BIALLELIC.selected  -k ${workdir}/${FS}/1163g.179kB.prior15.gauss4.ts99.5.BIALLELIC.selected.cXX.txt -o ${FS}.ddm1_minus_col_blup_maf_005 -lmm 4 -n 3 -maf 0.05
