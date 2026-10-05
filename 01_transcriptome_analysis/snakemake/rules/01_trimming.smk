# =============================================================================
# TRIMMING RULES (TWO-STEP PROCESS)
# Step 1: UMI extraction from R2 with quality filtering (umi_tools)
# Step 2: Adapter trimming, polyX removal, quality filtering (fastp)
# =============================================================================

def get_r1_path(wildcards):
    """Lookup R1 path for this unique_id"""
    checkpoints.build_sample_sheet.get()
    samples = pd.read_csv(config["sample_sheet"], sep="\t", dtype=str, index_col="unique_id")
    return samples.loc[wildcards.sample, "r1_path"]

def get_r2_path(wildcards):
    """Lookup R2 path for this unique_id"""
    checkpoints.build_sample_sheet.get()
    samples = pd.read_csv(config["sample_sheet"], sep="\t", dtype=str, index_col="unique_id")
    return samples.loc[wildcards.sample, "r2_path"]


rule umi_extract:
    """
    STEP 1: Extract 12bp UMI from R2 and embed in R1 header
    Uses umi_tools extract with quality filtering (Q20 threshold)
    Filters out reads where UMI has bases < Q20
    """
    input:
        r1 = get_r1_path,
        r2 = get_r2_path
    output:
        r1_umi = os.path.join(config["outdir"], "umi_extracted", "{sample}.fastq.gz")
    log:
        os.path.join(config["outdir"], "logs", "umi_tools", "{sample}_extract.log")
    threads: 2
    resources:
        mem_mb=8000,
        time="4:00:00"
    shell:
        """
	ml build-env/f2021
	ml python/3.8.6-gcccore-10.2.0
        ml umi-tools/1.1.2-foss-2020b-python-3.8.6
        mkdir -p $(dirname {output.r1_umi}) $(dirname {log})
        # Extract UMI from R2, filter by quality, output R1 with UMI in header
        umi_tools extract \
            --extract-method=string \
            --bc-pattern=NNNNNNNNNNNN \
            --stdin={input.r2} \
            --read2-in={input.r1} \
            --stdout=/dev/null \
            --read2-out={output.r1_umi} \
            --quality-filter-threshold=20 \
            --quality-encoding=phred33 \
            --log={log}
        """


rule umi_trim:
    """
    STEP 2: Adapter trimming, polyX removal, and quality filtering
    Input: UMI-tagged R1 from step 1 (single-end)
    For 3' QuantSeq: trim polyA/polyG from 3' end (right side)
    """
    input:
        os.path.join(config["outdir"], "umi_extracted", "{sample}.fastq.gz")
    output:
        os.path.join(config["outdir"], "umi_trimmed", "{sample}.fastq.gz")
    log:
        os.path.join(config["outdir"], "logs", "fastp", "{sample}_trim.log")
    threads: 4
    resources:
        mem_mb=12000,
        time="6:00:00"
    shell:
        """
        ml build-env/f2022
        ml fastp/0.23.4-gcc-12.2.0

        mkdir -p $(dirname {output}) $(dirname {log})

        # Single-end trimming on UMI-tagged R1
        fastp \
            -i {input} -o {output} \
            --trim_poly_x \
            --cut_right \
            --cut_right_mean_quality 20 \
            --length_required {config[length_required]} \
            --adapter_fasta {config[adapter_fasta]} \
            --thread {threads} \
            --html $(dirname {log})/{wildcards.sample}_trim.html \
            --json $(dirname {log})/{wildcards.sample}_trim.json \
            2> {log}
        """
