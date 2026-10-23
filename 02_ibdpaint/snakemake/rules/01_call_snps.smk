# This rule generates BAM list, create targets, and call SNPs at known positions (scattered by chunk)

NCHUNK = 50
CHUNKS = [f"{i:02d}" for i in range(NCHUNK)]


rule make_bam_list:
    output:
        bam_list = temp(f"{OUT}/call_snps/bam_list.txt"),
    params:
        dedup_dir = os.path.join(config["outdir"], "dedup"),
    run:
        with open(output.bam_list, "w") as f:
            for sample in SAMPLES:
                f.write(f"{params.dedup_dir}/{sample}.dedup.bam\n")


rule make_targets:
    input:
        vcf = config["parental_snp_vcf"],
    output:
        tsv = f"{OUT}/call_snps/targets_{{chrom}}.tsv.gz",
        tbi = f"{OUT}/call_snps/targets_{{chrom}}.tsv.gz.tbi",
    log:
        f"{OUT}/logs/ibdpainting/make_targets_{{chrom}}.log",
    resources:
        mem_mb = 50000,
        runtime = 1000,
        slurm_partition = "m",
        qos = "m_long",
    shell:
        r"""
        ml build-env/f2022
        ml bcftools/1.17-gcc-12.2.0
        ml htslib 2>/dev/null || true
        (
        bcftools query -r {wildcards.chrom} -f '%CHROM\t%POS\t%REF,%ALT\n' {input.vcf} \
            | bgzip -c > {output.tsv}
        tabix -s1 -b2 -e2 {output.tsv}
        ) > {log} 2>&1
        """


rule split_targets:
    input:
        targets = f"{OUT}/call_snps/targets_{{chrom}}.tsv.gz",
    output:
        tsv = temp(expand(f"{OUT}/call_snps/chunks/targets_{{{{chrom}}}}.{{chunk}}.tsv.gz", chunk=CHUNKS)),
        tbi = temp(expand(f"{OUT}/call_snps/chunks/targets_{{{{chrom}}}}.{{chunk}}.tsv.gz.tbi", chunk=CHUNKS)),
    params:
        n = NCHUNK,
        prefix = f"{OUT}/call_snps/chunks/targets_{{chrom}}.",
    resources:
        mem_mb = 50000,
        runtime = 1000,
        slurm_partition = "m",
        qos = "m_long",
    shell:
        r"""
        ml build-env/f2022
        ml bcftools/1.17-gcc-12.2.0
        ml htslib 2>/dev/null || true
        mkdir -p $(dirname {params.prefix})

        tmp=$(mktemp)
        gzip -cd {input.targets} > $tmp
        total=$(wc -l < $tmp)
        per=$(( (total + {params.n} - 1) / {params.n} )) # Calculate total lines per chunk 

        # contiguous, order-preserving split
        awk -v per=$per -v p={params.prefix} \
            '{{ f = sprintf("%s%02d.tsv", p, int((NR-1)/per)); print > f }}' $tmp

        for i in $(seq -f "%02g" 0 $(({params.n} - 1))); do
            f={params.prefix}$i.tsv
            [ -f $f ] || touch $f          # in case a chunk ends up empty
            bgzip -f $f
            tabix -f -s1 -b2 -e2 $f.gz
        done
        rm -f $tmp
        """


rule call_snps_chunk:
    input:
        bams = expand(os.path.join(config["outdir"], "dedup", "{sample}.dedup.bam"), sample=SAMPLES),
        bais = expand(os.path.join(config["outdir"], "dedup", "{sample}.dedup.bam.bai"), sample=SAMPLES),
        bam_list = f"{OUT}/call_snps/bam_list.txt",
        targets = f"{OUT}/call_snps/chunks/targets_{{chrom}}.{{chunk}}.tsv.gz",
        tbi = f"{OUT}/call_snps/chunks/targets_{{chrom}}.{{chunk}}.tsv.gz.tbi",
    output:
        vcf = temp(f"{OUT}/call_snps/chunks/{PROJECT}_{{chrom}}.{{chunk}}.vcf.gz"),
    params:
        fasta = config["fasta"],
        min_mq = config.get("min_MQ", 20),
    log:
        f"{OUT}/logs/ibdpainting/call_snps_{{chrom}}.{{chunk}}.log",
    threads: 2
    resources:
        mem_mb = 50000,
        runtime = 1000,
        slurm_partition = "m",
        qos = "m_long",   # adjust to a QoS that exists on your cluster
    shell:
        r"""
        ml build-env/f2022
        ml bcftools/1.17-gcc-12.2.0
        ulimit -n $(ulimit -Hn)
        (
        # Compute the genomic range covered by this chunk (first pos .. last pos)
        region=$(gzip -cd {input.targets} | awk 'NR==1{{c=$1; s=$2}} END{{print c":"s"-"$2}}')
        echo "Chunk region: $region"

        bcftools mpileup \
            --min-MQ {params.min_mq} \
            -a FORMAT/DP,FORMAT/AD \
            --skip-indels \
            -f {params.fasta} \
            -r $region \
            -T <(gzip -cd {input.targets} | cut -f1,2) \
            -b {input.bam_list} \
            --threads {threads} \
            -Ou \
        | bcftools call \
            -m \
            --constrain alleles \
            --targets-file {input.targets} \
            --variants-only \
            -Ou \
        | bcftools norm \
            -m -both \
            -f {params.fasta} \
            -Oz \
            --output {output.vcf}
        ) > {log} 2>&1
        """


rule call_snps:
    input:
        expand(f"{OUT}/call_snps/chunks/{PROJECT}_{{{{chrom}}}}.{{chunk}}.vcf.gz", chunk=CHUNKS),
    output:
        vcf = f"{OUT}/call_snps/{PROJECT}_snp_matrix_{{chrom}}.vcf.gz",
        tbi = f"{OUT}/call_snps/{PROJECT}_snp_matrix_{{chrom}}.vcf.gz.tbi",
    log:
        f"{OUT}/logs/ibdpainting/concat_{{chrom}}.log",
    threads: 4
    resources:
        mem_mb = 50000,
        runtime = 1000,
        slurm_partition = "m",
        qos = "m_long",
    shell:
        r"""
        ml build-env/f2022
        ml bcftools/1.17-gcc-12.2.0
        (
        bcftools concat {input} -Oz --threads {threads} -o {output.vcf}
        bcftools index -t {output.vcf}
        ) > {log} 2>&1
        """