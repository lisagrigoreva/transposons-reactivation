#!/usr/bin/env python3
import sys
import gzip

ROOT = "/scratch-cbe/users/elizaveta.grigoreva/ddm1_resilencing/processing/snakemake_run"

if len(sys.argv) < 3:
    print("Usage: python3 script.py input.tsv output.tsv")
    sys.exit(1)

input_tsv = sys.argv[1]
output_tsv = sys.argv[2]

with open(input_tsv) as f:
    header = f.readline().strip()
    lines = f.readlines()

out = open(output_tsv, 'w')
out.write(header + "\treads_umi_extracted\treads_umi_trimmed\treads_uniquely_aligned\n")

for line in lines:
    line = line.strip()
    if not line:
        continue
    
    unique_id = line.split('\t')[0]
    
    # Count FASTQ reads
    try:
        umi_ext = str(sum(1 for _ in gzip.open(f"{ROOT}/umi_extracted/{unique_id}.fastq.gz", 'rt')) // 4)
    except:
        umi_ext = "NA"
    
    try:
        umi_trim = str(sum(1 for _ in gzip.open(f"{ROOT}/umi_trimmed/{unique_id}.fastq.gz", 'rt')) // 4)
    except:
        umi_trim = "NA"
    
    # Parse STAR log
    star = "NA"
    try:
        for l in open(f"{ROOT}/aligned/{unique_id}/Log.final.out"):
            if "Uniquely mapped reads number" in l:
                star = l.split("|")[1].strip()
    except:
        pass
    
    out.write(f"{line}\t{umi_ext}\t{umi_trim}\t{star}\n")

out.close()
print(f"Done: {output_tsv}")
