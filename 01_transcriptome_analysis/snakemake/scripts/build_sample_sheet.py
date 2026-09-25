#!/usr/bin/env python3
import os
import sys
import glob

datadir = sys.argv[1]  # /scratch-cbe/.../01_data
output = sys.argv[2]

with open(output, 'w') as out:
    # Changed header: unique_id instead of sample_id
    out.write("unique_id\tsample_id\trun\tr1_path\tr2_path\n")

    # Find all extracted run directories
    for run_dir in glob.glob(os.path.join(datadir, "*")):
        if not os.path.isdir(run_dir):
            continue

        run = os.path.basename(run_dir)

        # Find all R1 fastq files in demultiplexed subdirectories
        r1_files = glob.glob(os.path.join(run_dir, "**", "demultiplexed", "*", "*_R1_001.fastq.gz"), recursive=True)

        for r1_path in r1_files:
            # Extract unique_id and sample_id from filename
            # Example: 294339_S26_R1_001.fastq.gz -> unique_id=294339_S26, sample_id=294339
            filename = os.path.basename(r1_path)
            unique_id = filename.replace('_R1_001.fastq.gz', '')  # NEW: Keep full prefix
            sample_id = filename.split('_')[0]  # Original biological sample ID

            # Build R2 path
            r2_path = r1_path.replace("_R1_001.fastq.gz", "_R2_001.fastq.gz")

            # Verify R2 exists
            if os.path.exists(r2_path):
                out.write(f"{unique_id}\t{sample_id}\t{run}\t{r1_path}\t{r2_path}\n")
            else:
                print(f"WARNING: R2 not found for {r1_path}", file=sys.stderr)

print(f"Sample sheet written to {output}")
