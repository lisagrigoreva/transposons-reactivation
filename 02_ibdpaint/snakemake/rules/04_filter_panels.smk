# rules/filter_panels.smk
# Filter reference and target panels to genic regions only

# rules/filter_panels.smk
# Filter reference and target panels to genic regions only

rule filter_target_panel:
    """
    Filter the target VCF (RNA-seq samples) to biallelic SNPs in genic regions.
    """
    input:
        vcf = f"{OUT}/genotyping/{PROJECT}.vcf.gz",
        tbi = f"{OUT}/genotyping/{PROJECT}.vcf.gz.tbi",
    output:
        vcf = f"{OUT}/filtered/{PROJECT}_target_filtered.vcf.gz",
        tbi = f"{OUT}/filtered/{PROJECT}_target_filtered.vcf.gz.tbi",
    params:
        bed = config["genic_regions_bed"],
    resources:
        mem_mb = 50000,
        runtime = 1440,
        slurm_partition="m",
        qos="m_long",
    threads: 1
    log:
        f"{OUT}/logs/ibdpainting/filter_target_panel.log",
    shell:
        r"""
        ml build-env/f2022
        ml bcftools/1.17-gcc-12.2.0
        (
        bcftools view \
            --regions-file {params.bed} \
            --types snps \
            --min-alleles 2 \
            --max-alleles 2 \
            --threads {threads} \
            -Oz -o {output.vcf} \
            {input.vcf}
        
        tabix -p vcf {output.vcf}
        ) > {log} 2>&1
        """


rule filter_reference_panel:
    """
    Filter the reference panel (1001 Genomes) to biallelic SNPs with MAF >= 0.1 in genic regions.
    """
    input:
        vcf = config["parental_snp_vcf"],
    output:
        vcf = f"{OUT}/filtered/reference_panel_filtered.vcf.gz",
        tbi = f"{OUT}/filtered/reference_panel_filtered.vcf.gz.tbi",
    params:
        bed = config["genic_regions_bed"],
    resources:
        mem_mb = 50000,
        runtime = 1440,
        slurm_partition="m",
        qos="m_long",
    threads: 1
    log:
        f"{OUT}/logs/ibdpainting/filter_reference_panel.log",
    shell:
        r"""
        ml build-env/f2022
        ml bcftools/1.17-gcc-12.2.0
        (
        bcftools view \
            --regions-file {params.bed} \
            --min-af 0.1:minor \
            --types snps \
            --min-alleles 2 \
            --max-alleles 2 \
            --threads {threads} \
            -Oz -o {output.vcf} \
            {input.vcf}
        
        tabix -p vcf {output.vcf}
        ) > {log} 2>&1
        """