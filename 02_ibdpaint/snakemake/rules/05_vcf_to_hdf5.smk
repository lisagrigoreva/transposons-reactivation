# rules/vcf_to_hdf5.smk
# Convert filtered VCFs to HDF5 format using scikit-allel

rule convert_reference_to_hdf5:
    """Convert the filtered 1001 Genomes reference panel to HDF5 (parents)"""
    input:
        vcf = f"{OUT}/filtered/reference_panel_filtered.vcf.gz",
        tbi = f"{OUT}/filtered/reference_panel_filtered.vcf.gz.tbi",
    output:
        h5 = f"{OUT}/hdf5/parents_reference.h5",
    params:
        env_cmd = config.get("hdf5_env_cmd", "true"),
    log:
        f"{OUT}/logs/ibdpainting/convert_reference_to_hdf5.log",
    benchmark:
        f"{OUT}/benchmarks/convert_reference_to_hdf5.tsv",
    resources:
        mem_mb = 50000,
        runtime = 1440,
        slurm_partition="m",
        qos="m_long",
    shell:
        """
        {params.env_cmd}
        python -c "
import allel
print('Converting {input.vcf} to {output.h5}')
allel.vcf_to_hdf5('{input.vcf}', '{output.h5}', fields='*', overwrite=True)
print('Conversion complete!')
" > {log} 2>&1
        """


rule vcf_to_hdf5:
    """Convert YOUR filtered target panel to HDF5 (progeny samples)"""
    input:
        vcf = f"{OUT}/filtered/{PROJECT}_target_filtered.vcf.gz",
        tbi = f"{OUT}/filtered/{PROJECT}_target_filtered.vcf.gz.tbi",
    output:
        h5 = f"{OUT}/hdf5/{PROJECT}.h5",
    params:
        env_cmd = config.get("hdf5_env_cmd", "true"),
    log:
        f"{OUT}/logs/ibdpainting/vcf_to_hdf5.log",
    benchmark:
        f"{OUT}/benchmarks/vcf_to_hdf5.tsv",
    resources:
        mem_mb = 50000,
        runtime = 1440,
        slurm_partition="m",
        qos="m_long",
    shell:
        """
        {params.env_cmd}
        python -c "
import allel
print('Converting {input.vcf} to {output.h5}')
allel.vcf_to_hdf5('{input.vcf}', '{output.h5}', fields='*', overwrite=True)
print('Conversion complete!')
" > {log} 2>&1
        """