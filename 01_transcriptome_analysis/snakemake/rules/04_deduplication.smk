# =============================================================================
# DEDUPLICATION RULES
# UMI-based deduplication with umi_tools
# =============================================================================

rule umi_dedup:
    """
    Deduplicate genome-aligned BAM using UMIs from read names
    """
    input:
        bam = os.path.join(config["outdir"], "aligned", "{sample}", "Aligned.sortedByCoord.out.bam"),
        bai = os.path.join(config["outdir"], "aligned", "{sample}", "Aligned.sortedByCoord.out.bam.bai")
    output:
        bam = os.path.join(config["outdir"], "dedup", "{sample}.dedup.bam")
    params:
        stats_prefix = lambda w: os.path.join(config["outdir"], "dedup", "stats", w.sample),
        sep = "_"
    log:
        os.path.join(config["outdir"], "logs", "umi_tools", "{sample}_dedup.log")
    threads: 5
    resources:
        mem_mb=64000,
        runtime=1440,
        slurm_partition="m"
    shell:
        """
        ml build-env/f2021
        ml python/3.8.6-gcccore-10.2.0
        ml umi-tools/1.1.2-foss-2020b-python-3.8.6

        mkdir -p $(dirname {output.bam}) $(dirname {params.stats_prefix})

        umi_tools dedup \
            --stdin={input.bam} \
            --stdout={output.bam} \
            --extract-umi-method=read_id \
            --umi-separator={params.sep} \
            --method=directional \
            --output-stats={params.stats_prefix} \
            --log={log} \
            2>> {log}
        """

rule index_dedup_bam:
    """
    Index deduplicated genome BAM
    """
    input:
        os.path.join(config["outdir"], "dedup", "{sample}.dedup.bam")
    output:
        os.path.join(config["outdir"], "dedup", "{sample}.dedup.bam.bai")
    log:
        os.path.join(config["outdir"], "logs", "samtools", "{sample}_dedup_index.log")
    threads: 2
    resources:
        mem_mb=4000,
        time="0:30:00"
    shell:
        """
        ml build-env/f2022
        ml samtools/1.17-gcc-12.2.0

        samtools index -@ {threads} {input} 2> {log}
        """

rule filter_transcriptome_bam:
    """
    Keep only transcriptome alignments of reads that survived genomic dedup:
    read names are taken from the deduplicated genome BAM and used to
    subset Aligned.toTranscriptome.out.bam.
    """
    input:
        genome_dedup = os.path.join(config["outdir"], "dedup", "{sample}.dedup.bam"),
        transcriptome = os.path.join(config["outdir"], "aligned", "{sample}", "Aligned.toTranscriptome.out.bam")
    output:
        bam = os.path.join(config["outdir"], "dedup", "{sample}.transcriptome_dedup.bam")
    params:
        ids = lambda w: os.path.join(config["outdir"], "dedup", w.sample + ".read_ids.tmp")
    log:
        os.path.join(config["outdir"], "logs", "filter_transcriptome", "{sample}.log")
    threads: 4
    resources:
        mem_mb=10000,
        time="1:00:00"
    shell:
        """
        ml build-env/f2022
        ml samtools/1.17-gcc-12.2.0

        mkdir -p $(dirname {output.bam})

        # read names of surviving reads (genome BAM)
        samtools view {input.genome_dedup} | cut -f1 | sort -u > {params.ids} 2> {log}

        # keep only those reads in the transcriptome BAM (header preserved)
        samtools view -@ {threads} -b -N {params.ids} \
            -o {output.bam} {input.transcriptome} 2>> {log}

        echo "reads kept: $(wc -l < {params.ids})" >> {log}
        rm -f {params.ids}
        """
