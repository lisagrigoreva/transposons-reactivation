cd /groups/nordborg/projects/ddm1_resilencing/01_data/96_plates_tm3_rnaseq

# Build sample sheet from all runs
for run_dir in */; do
  run=$(basename "$run_dir")
  
  # Find the sample_map.tsv in this run
  tsv=$(find "$run_dir" -name "*_sample_map.tsv" -type f | head -n1)
  
  if [[ -f "$tsv" ]]; then
    # Extract sample info (skip header, only R1 rows)
    awk -F'\t' -v run="$run" -v base_path="$PWD/$run_dir" '
      NR>1 && $4=="R1" {
        sample=$1
        r1_rel_path=$2  # relative path from tsv
        
        # Build full paths
        r1_full=base_path r1_rel_path
        r2_full=r1_full
        sub(/_R1_001\.fastq\.gz/, "_R2_001.fastq.gz", r2_full)
        
        print sample "\t" run "\t" r1_full "\t" r2_full
      }
    ' "$tsv"
  fi
done > /groups/nordborg/projects/ddm1_resilencing/02_scripts/transposons-reactivation/01_transcriptome_analysis/samples.tsv

# Check how many samples
wc -l /groups/nordborg/projects/ddm1_resilencing/02_scripts/transposons-reactivation/01_transcriptome_analysis/samples.tsv
head /groups/nordborg/projects/ddm1_resilencing/02_scripts/transposons-reactivation/01_transcriptome_analysis/samples.tsv
