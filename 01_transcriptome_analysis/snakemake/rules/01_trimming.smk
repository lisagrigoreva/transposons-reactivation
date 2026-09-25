
# UMI extraction and quality trimming with fastp

rule umi_trim:
    """
    Extract 12bp UMI from R2, embed in R1 header, trim adapters and poly-X
    Output: UMI-tagged single-end R1 reads. Unique id is generated from the repeated deepsequencing of controls with suffix _1,2,3 etc.
    """
    input:
        r1 = lambda w: samples[samples["unique_id"]==w.sample]["r1_path"].values[0],
        r2 = lambda w: samples[samples["unique_id"]==w.sample]["r2_path"].values[0]
    output:
        os.path.join(config["outdir"], "umi_trimmed", "{sample}.fastq.gz")
    log:
        os.path.join(config["outdir"], "logs", "fastp", "{sample}.log")
    threads: 4
    resources:
        mem_mb=10000,
        time="8:00:00"
    shell:
        """
        # Load required modules
        ml build-env/f2022
        ml fastp/0.23.4-gcc-12.2.0
        mkdir -p $(dirname {output}) $(dirname {log})
        fastp \
            -i {input.r1} -o {output} \
            -I {input.r2} -O /dev/null \
            --umi --umi_loc=read2 --umi_len={config[umi_len]} --umi_prefix=UMI \
            --trim_poly_x --length_required {config[length_required]} \
            --adapter_fasta {config[adapter_fasta]} \
	    --qualified_quality_phred {config[qualified_quality_phred]} \
            --unqualified_percent_limit {config[unqualified_percent_limit]} \
            --cut_right_mean_quality {config[cut_quality]} \
            --cut_right \
            --thread {threads} \
            2> {log}
        """
