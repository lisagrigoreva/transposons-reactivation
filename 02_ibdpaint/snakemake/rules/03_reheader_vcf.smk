# rules/reheader_vcf.smk
# Strip path prefixes and .dedup.bam suffixes from VCF sample names

rule reheader_vcf:
    input:
        vcf = f"{OUT}/merge_chromosomes/{PROJECT}.vcf.gz",
    output:
        vcf = f"{OUT}/genotyping/{PROJECT}.vcf.gz",
        tbi = f"{OUT}/genotyping/{PROJECT}.vcf.gz.tbi",
        names = f"{OUT}/genotyping/{PROJECT}.sample_names.txt",
    resources:
        mem_mb = 4000,
        runtime = 120
    log:
        f"{OUT}/logs/ibdpainting/reheader_vcf/{PROJECT}.log",
    shell:
        """
        ml build-env/f2022
        ml bcftools/1.17-gcc-12.2.0
        (
        bcftools query -l {input.vcf} \
            | sed 's|.*/||; s|\\.dedup\\.bam$||; s|\\.bam$||' > {output.names}
        bcftools reheader -s {output.names} {input.vcf} -o {output.vcf}
        tabix -p vcf {output.vcf}
        ) &> {log}
        """