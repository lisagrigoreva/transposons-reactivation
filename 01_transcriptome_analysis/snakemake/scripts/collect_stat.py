#!/usr/bin/env python3
import sys

if len(sys.argv) != 4:
    sys.exit("Usage: python3 collect_stat.py run_dir input.tsv output.tsv")

root, input_tsv, output_tsv = sys.argv[1:]

def grab(path, key):
    """Return the values on lines starting with `key`, in order."""
    try:
        return [l.split(":")[-1].split("|")[-1].strip()
                for l in open(path) if l.strip().startswith(key)]
    except OSError:
        return []

fin, fout = open(input_tsv), open(output_tsv, "w")
fout.write(fin.readline().rstrip("\n") + "\treads_umi_extracted\treads_umi_trimmed\treads_uniquely_aligned\n")

for line in fin:
    line = line.rstrip("\n")
    if not line:
        continue
    uid = line.split("\t")[0]
    fastp = grab(f"{root}/logs/fastp/{uid}_trim.log", "total reads") + ["NA", "NA"]
    star = grab(f"{root}/aligned/{uid}/Log.final.out", "Uniquely mapped reads number") + ["NA"]
    fout.write(f"{line}\t{fastp[0]}\t{fastp[1]}\t{star[0]}\n")
