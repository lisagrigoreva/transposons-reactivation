#!/usr/bin/env python3
import os
import sys
import glob
from collections import defaultdict

datadir = sys.argv[1]  # /scratch-cbe/.../01_data
output = sys.argv[2]

# Track occurrences of each base_id
counter = defaultdict(int)
rows = []

# First pass: collect all rows
for run_dir in glob.glob(os.path.join(datadir, "*")):
    if not os.path.isdir(run_dir):
        continue

    run = os.path.basename(run_dir)

    # Find all R1 fastq files in demultiplexed subdirectories
    r1_files = glob.glob(os.path.join(run_dir, "**", "demultiplexed", "*", "*_R1_001.fastq.gz"), recursive=True)

    for r1_path in r1_files:
        # Extract base_id and sample_id from filename
        # Example: 294339_S26_R1_001.fastq.gz -> base_id=294339_S26, sample_id=294339
        filename = os.path.basename(r1_path)
        base_id = filename.replace('_R1_001.fastq.gz', '')  # 294339_S26
        sample_id = filename.split('_')[0]  # 294339

        # Build R2 path
        r2_path = r1_path.replace("_R1_001.fastq.gz", "_R2_001.fastq.gz")

        # Verify R2 exists
        if os.path.exists(r2_path):
            # Increment counter for this base_id
            counter[base_id] += 1
            # Create unique_id with counter: 294339_S26_1, 294339_S26_2, etc.
            unique_id = f"{base_id}_{counter[base_id]}"
            
            rows.append({
                'unique_id': unique_id,
                'sample_id': sample_id,
                'run': run,
                'r1_path': r1_path,
                'r2_path': r2_path
            })
        else:
            print(f"WARNING: R2 not found for {r1_path}", file=sys.stderr)

# Write output
with open(output, 'w') as out:
    # Header
    out.write("unique_id\tsample_id\trun\tr1_path\tr2_path\n")
    
    # Write all rows
    for row in rows:
        out.write(f"{row['unique_id']}\t{row['sample_id']}\t{row['run']}\t{row['r1_path']}\t{row['r2_path']}\n")

print(f"Sample sheet written to {output}")
print(f"Total samples: {len(rows)}")
