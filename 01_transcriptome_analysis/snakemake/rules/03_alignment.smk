rule star_align:
    """
    Align trimmed reads with STAR using custom TE annotation
    """
    input:
        fastq = os.path.join(config["outdir"], "umi_trimmed", "{sample}.fastq.gz")
    output:
        bam = os.path.join(config["outdir"], "aligned", "{sample}", "Aligned.sortedByCoord.out.bam"),
        transcriptome = os.path.join(config["outdir"], "aligned", "{sample}", "Aligned.toTranscriptome.out.bam"),
        log_final = os.path.join(config["outdir"], "aligned", "{sample}", "Log.final.out")
    params:
        prefix = lambda w: os.path.join(config["outdir"], "aligned", w.sample) + "/"
    log:
        os.path.join(config["outdir"], "logs", "star", "{sample}.log")
    threads: 8
    resources:
        mem_mb=16000,
        time="1:00:00"
    shell:
        """
        ml build-env/f2022
        ml star/2.7.11a-gcc-12.3.0

        mkdir -p {params.prefix}
        rm -rf {params.prefix}_STARtmp

        STAR \
            --runMode alignReads \
            --runThreadN {threads} \
            --genomeDir {config[star_index]} \
            --readFilesIn {input.fastq} \
            --readFilesCommand zcat \
            --outFileNamePrefix {params.prefix} \
            --alignEndsType EndToEnd \
            --alignIntronMin 20 \
            --alignIntronMax 1000000 \
            --alignSJoverhangMin 8 \
            --alignSJDBoverhangMin 5 \
            --outFilterType BySJout \
            --outFilterIntronMotifs RemoveNoncanonicalUnannotated \
            --outFilterMismatchNoverLmax 0.1 \
            --outFilterScoreMinOverLread 0.4 \
            --outFilterMatchNminOverLread 0.4 \
            --outFilterMultimapNmax 100 \
            --winAnchorMultimapNmax 200 \
            --outSAMattributes NH HI AS nM NM MD jM jI XS \
            --outSAMtype BAM SortedByCoordinate \
            --outBAMsortingThreadN {threads} \
            --limitBAMsortRAM 8000000000 \
            --quantMode TranscriptomeSAM \
            --quantTranscriptomeBan IndelSoftclipSingleend \
            2> {log}
        """
rule index_bam:
    """
    Index sorted BAM files
    """
    input:
        os.path.join(config["outdir"], "aligned", "{sample}", "Aligned.sortedByCoord.out.bam")
    output:
        os.path.join(config["outdir"], "aligned", "{sample}", "Aligned.sortedByCoord.out.bam.bai")
    log:
        os.path.join(config["outdir"], "logs", "samtools", "{sample}_index.log")
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
