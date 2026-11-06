# rules/merge_chromosomes.smk
# Concatenate per-chromosome VCFs into a single multi-chromosome VCF

rule merge_chromosomes:
    input:
        vcfs = expand(f"{OUT}/call_snps/{PROJECT}_snp_matrix_{{chrom}}.vcf.gz", chrom=CHROMOSOMES),
    output:
        vcf = f"{OUT}/merge_chromosomes/{PROJECT}.vcf.gz",
        tbi = f"{OUT}/merge_chromosomes/{PROJECT}.vcf.gz.tbi",
    resources:
        mem_mb          = lambda wc, attempt: 50000 if attempt == 1 else 50000,
        runtime         = lambda wc, attempt: 220   if attempt == 1 else 1040,
        slurm_partition = lambda wc, attempt: "c"   if attempt == 1 else "m",
        qos             = lambda wc, attempt: "c_short" if attempt == 1 else "m_long",
    log:
        f"{OUT}/logs/ibdpainting/merge_chromosomes/{PROJECT}.log",
    shell:
        """
        ml build-env/f2022
        ml bcftools/1.17-gcc-12.2.0
        (
        bcftools concat -Oz -o {output.vcf} {input.vcfs}
        tabix -p vcf {output.vcf}
        ) &> {log}
        """