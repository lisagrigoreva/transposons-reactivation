# =============================================================================
# QC RULES
# Pre-alignment QC (trimmed reads) and post-alignment QC (BAMs, dedup, RSEM)
# =============================================================================

# ========== PRE-ALIGNMENT QC ==========

rule fastqc_trimmed:
    """
    Run FastQC on trimmed reads to assess quality
    """
    input:
        os.path.join(config["outdir"], "umi_trimmed", "{sample}.fastq.gz")
    output:
        html = os.path.join(config["outdir"], "qc", "fastqc_trimmed", "{sample}_fastqc.html"),
        zip = os.path.join(config["outdir"], "qc", "fastqc_trimmed", "{sample}_fastqc.zip")
    log:
        os.path.join(config["outdir"], "logs", "fastqc", "{sample}_trimmed.log")
    threads: 2
    resources:
        mem_mb=10000,
        time="03:00:00"
    shell:
        """
        ml build-env/f2022
        ml fastqc/0.11.9-java-11

        mkdir -p $(dirname {output.html})

        fastqc \
            --outdir $(dirname {output.html}) \
            --threads {threads} \
            {input} \
            2> {log}
        """

rule multiqc_trimming:
    """
    Pre-alignment QC only: FastQC on trimmed reads + fastp.
    Does not need alignment. Output sits outside qc/ so multiqc_all
    does not ingest it.
    """
    input:
        fastqc = lambda w: expand(
            os.path.join(config["outdir"], "qc", "fastqc_trimmed", "{sample}_fastqc.zip"),
            sample=get_all_samples()
        ),
        fastp = lambda w: expand(
            os.path.join(config["outdir"], "logs", "fastp", "{sample}_trim.json"),
            sample=get_all_samples()
        )
    output:
        os.path.join(config["outdir"], "multiqc_trimming", "multiqc_trimming_report.html")
    log:
        os.path.join(config["outdir"], "logs", "multiqc", "trimming_report.log")
    resources:
        mem_mb=16000,
        time="2:00:00"
    shell:
        """
        ml build-env/f2021
        ml multiqc/1.11-foss-2020b-python-3.8.6

        mkdir -p $(dirname {output})

        multiqc \
            --outdir $(dirname {output}) \
            --filename $(basename {output}) \
            --force --flat \
            {config[outdir]}/qc/fastqc_trimmed/ \
            {config[outdir]}/logs/fastp/ \
            2> {log}
        """

# ========== POST-ALIGNMENT QC ==========

rule samtools_flagstat:
    """
    Count mapped/unmapped reads
    """
    input:
        bam = os.path.join(config["outdir"], "aligned", "{sample}", "Aligned.sortedByCoord.out.bam"),
        bai = os.path.join(config["outdir"], "aligned", "{sample}", "Aligned.sortedByCoord.out.bam.bai")
    output:
        os.path.join(config["outdir"], "qc", "samtools_flagstat", "{sample}.flagstat.txt")
    log:
        os.path.join(config["outdir"], "logs", "samtools_flagstat", "{sample}.log")
    threads: 2
    resources:
        mem_mb=2000,
        time="0:20:00"
    shell:
        """
        ml build-env/f2022
        ml samtools/1.17-gcc-12.2.0

        mkdir -p $(dirname {output})

        samtools flagstat --threads {threads} {input.bam} > {output} 2> {log}
        """

# ========== MULTIQC AGGREGATION (FULL, needs alignment + quantification) ==========

rule multiqc_all:
    """
    Full report: FastQC, fastp, STAR, flagstat, umi_tools dedup, RSEM.
    Depends on RSEM outputs so it runs last.
    """
    input:
        fastqc = lambda w: expand(
            os.path.join(config["outdir"], "qc", "fastqc_trimmed", "{sample}_fastqc.zip"),
            sample=get_all_samples()
        ),
        flagstat = lambda w: expand(
            os.path.join(config["outdir"], "qc", "samtools_flagstat", "{sample}.flagstat.txt"),
            sample=get_all_samples()
        ),
        quant = lambda w: expand(
            os.path.join(config["outdir"], "quantification", "{sample}.genes.results"),
            sample=get_all_samples()
        )
    output:
        os.path.join(config["outdir"], "qc", "multiqc_report.html")
    log:
        os.path.join(config["outdir"], "logs", "multiqc", "report.log")
    resources:
        mem_mb=16000,
        time="2:00:00"
    shell:
        """
        ml build-env/f2022
        ml multiqc/1.14-foss-2021b

        multiqc \
            --outdir $(dirname {output}) \
            --filename $(basename {output}) \
            --force --flat \
            {config[outdir]}/qc/fastqc_trimmed/ \
            {config[outdir]}/qc/samtools_flagstat/ \
            {config[outdir]}/logs/fastp/ \
            {config[outdir]}/aligned/ \
            {config[outdir]}/dedup/stats/ \
            {config[outdir]}/quantification/ \
            2> {log}
        """
