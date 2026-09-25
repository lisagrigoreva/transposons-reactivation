# =============================================================================
# PREPROCESSING RULES
# Extraction and sample sheet generation
# =============================================================================

rule extract_tarballs:
    """
    Extract tar.gz archives in parallel to scratch storage
    """
    input:
        "scripts/tarballs_to_extract.txt"
    output:
        "extraction_done.flag"
    params:
        extract_dir = config["extraction_dir"]
    threads: 30
    shell:
        """
        mkdir -p {params.extract_dir}
        
        # Function to extract one tarball
        extract_one() {{
            tarball=$1
            if [ -f "$tarball" ]; then
                run=$(basename $(dirname "$tarball"))
                dest="{params.extract_dir}/$run"
                echo "Extracting $tarball to $dest"
                mkdir -p "$dest"
                tar -xzf "$tarball" -C "$dest"
            fi
        }}
        export -f extract_one
        
        # Extract in parallel (use GNU parallel if available, otherwise xargs)
        if command -v parallel &> /dev/null; then
            cat {input} | parallel -j {threads} extract_one
        else
            cat {input} | xargs -P {threads} -I {{}} bash -c 'extract_one "{{}}"'
        fi
        
        touch {output}
        """

rule build_sample_sheet:
    """
    Scan extracted data and build sample sheet with R1/R2 paths
    """
    input:
        "extraction_done.flag"
    output:
        config["sample_sheet"]
    params:
        datadir = config["extraction_dir"]
    shell:
        """
        python scripts/build_sample_sheet.py {params.datadir} {output}
        """
