# rules/ibdpainting.smk
# Run ibdpainting once per sample against the parental panel.

def progeny_h5(wildcards):
    # Use a pre-made progeny h5 if given in config, else the one built by vcf_to_hdf5
    return config.get("progeny_h5") or f"{OUT}/hdf5/{PROJECT}.h5"

def parents_h5(wildcards):
    # Use a pre-made parents h5 if given in config, else the one built by convert_reference_to_hdf5
    return config.get("parents_h5") or f"{OUT}/hdf5/parents_reference.h5"

rule ibdpainting:
    input:
        progeny = progeny_h5,
        parents = parents_h5,
    output:
        done = f"{OUT}/ibdpainting/{{sample}}.done",
    params:
        expected = lambda wc: IBDPAINT_SAMPLES[wc.sample],
        outdir = lambda wc: f"{OUT}/ibdpainting/{wc.sample}",
        window = config.get("ibd_window_size", 500000),
        env_cmd = config.get("ibdpainting_env_cmd", "true"),
    log:
        f"{OUT}/logs/ibdpainting/{{sample}}.log",
    benchmark:
        f"{OUT}/benchmarks/ibdpainting/{{sample}}.tsv",
    resources:
        mem_mb = 50000,
        runtime = 1040,
        slurm_partition="m",
        qos="m_long",
    shell:
        """
        {params.env_cmd}
        mkdir -p {params.outdir}
        ibdpainting \
            -i {input.progeny} \
            -r {input.parents} \
            --window_size {params.window} \
            --sample_name {wildcards.sample} \
            --expected_match {params.expected} \
            --outdir {params.outdir} \
            --plot_heterozygosity \
            --interactive > {log} 2>&1
        touch {output.done}
        """