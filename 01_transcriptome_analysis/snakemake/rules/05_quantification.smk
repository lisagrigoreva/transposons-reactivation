# =============================================================================
# QUANTIFICATION RULES
# Gene and isoform quantification with RSEM (3' QuantSeq, single-end)
# =============================================================================

rule rsem_quantify:
    """
    Quantify with RSEM from the DEDUPLICATED transcriptome BAM.
    Use expected_count for downstream analysis, not TPM/FPKM.
    """
    input:
        transcriptome_bam = os.path.join(config["outdir"], "dedup", "{sample}.transcriptome_dedup.bam")
    output:
        genes = os.path.join(config["outdir"], "quantification", "{sample}.genes.results"),
        isoforms = os.path.join(config["outdir"], "quantification", "{sample}.isoforms.results"),
        stat = os.path.join(config["outdir"], "quantification", "{sample}.stat", "{sample}.cnt")
    params:
        prefix = lambda w: os.path.join(config["outdir"], "quantification", w.sample)
    log:
        os.path.join(config["outdir"], "logs", "rsem", "{sample}.log")
    threads: 4
    resources:
        mem_mb = 50000,
        runtime = 1040,
        slurm_partition="m",
        qos="m_long",
    shell:
        """
        ml build-env/2020
        ml rsem/1.3.3-foss-2018b

        mkdir -p $(dirname {params.prefix})

        rsem-calculate-expression \
            --bam \
            --no-bam-output \
            --alignments \
            --forward-prob 1 \
            --seed 12345 \
            --num-threads {threads} \
            {input.transcriptome_bam} \
            {config[rsem_index]} \
            {params.prefix} \
            2> {log}
        """
