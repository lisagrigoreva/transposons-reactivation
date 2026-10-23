# rules/merge_chromosomes.smk
# Concatenate per-chromosome VCFs into a single multi-chromosome VCF

rule merge_chromosomes:
    input:
        vcfs = expand(f"{OUT}/call_snps/{PROJECT}_snp_matrix_{{chrom}}.vcf.gz", chrom=CHROMOSOMES),
    output:
        vcf = f"{OUT}/merge_chromosomes/{PROJECT}.vcf.gz",
        tbi = f"{OUT}/merge_chromosomes/{PROJECT}.vcf.gz.tbi",
    resources:
        mem_mb = 50000,
        runtime = 1440,
        slurm_partition="m",
        qos="m_long",
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