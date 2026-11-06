# =============================================================================
# PREPROCESSING RULES
# Extraction and sample sheet generation
# =============================================================================
import os

# One entry per tarball: {"22T3LYLT3_3_R17613_20241017": "/groups/.../17613/22T3LYLT3_3_R17613_20241017.tar.gz", ...}
with open("scripts/tarballs_to_extract.txt") as f:
    TARBALLS = {os.path.basename(p).replace(".tar.gz", ""): p
                for p in (line.strip() for line in f) if p}


def tarball_dest(wc):
    """extraction_dir/<run>, where <run> is the tarball's parent folder (e.g. 17613)."""
    run = os.path.basename(os.path.dirname(TARBALLS[wc.tar]))
    return os.path.join(config["extraction_dir"], run)


rule extract_tarball:
    """
    Extract ONE tarball as its own SLURM job.
    tar's exit status guarantees every file was written completely.
    """
    input:
        lambda wc: TARBALLS[wc.tar]
    output:
        touch("logs/extraction/done/{tar}.done")
    params:
        dest = tarball_dest
    log:
        "logs/extraction/{tar}.log"
    threads: 4
    resources:
        mem_mb          = 4000,
        runtime         = lambda wc, attempt: 600 if attempt == 1 else 2840,
        slurm_partition = lambda wc, attempt: "c" if attempt == 1 else "m",
        qos             = lambda wc, attempt: "c_long" if attempt == 1 else "m_long",
    shell:
        r"""
        ml pigz 2>/dev/null || true
        mkdir -p {params.dest}
        echo "START $(date)  {input}" > {log}
        if command -v pigz >/dev/null; then
            tar -I "pigz -p {threads}" -xf {input} -C {params.dest} 2>> {log}
        else
            tar -xzf {input} -C {params.dest} 2>> {log}
        fi
        echo "SUCCESS $(date)" >> {log}
        """


rule extract_tarballs:
    """All tarballs extracted."""
    input:
        expand("logs/extraction/done/{tar}.done", tar=TARBALLS)
    output:
        touch("extraction_done.flag")


# Use checkpoint so Snakemake re-reads sample sheet after this completes
checkpoint build_sample_sheet:
    """
    Scan extracted data and build sample sheet with R1/R2 paths
    """
    input:
        flag = "extraction_done.flag"
    output:
        config["sample_sheet"]
    params:
        datadir = config["extraction_dir"]
    log:
        "logs/preprocessing/build_sample_sheet.log"
    shell:
        """
        python scripts/build_sample_sheet.py {params.datadir} {output} 2> {log}
        
        # Verify sample sheet was created
        if [ ! -s {output} ]; then
            echo "ERROR: Sample sheet is empty or missing!" >> {log}
            exit 1
        fi
        
        echo "Sample sheet created with $(wc -l < {output}) entries" >> {log}
        """