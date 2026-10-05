# =============================================================================
# PREPROCESSING RULES
# Extraction and sample sheet generation
# =============================================================================

rule extract_tarballs:
    """
    Extract tar.gz archives in parallel to scratch storage
    Files are kept permanently (no auto-deletion)
    """
    input:
        "scripts/tarballs_to_extract.txt"
    output:
        flag = "extraction_done.flag"
    params:
        extract_dir = config["extraction_dir"]
    log:
        "logs/extraction/extract_tarballs.log"
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
                echo "Extracting $tarball to $dest" >> {log}
                mkdir -p "$dest"
                
                # Extract and verify
                if tar -xzf "$tarball" -C "$dest"; then
                    # Count extracted files
                    file_count=$(find "$dest" -name "*.fastq.gz" | wc -l)
                    echo "SUCCESS: Extracted $file_count FASTQ files from $run" >> {log}
                    # Create marker to prevent cleanup
                    touch "$dest/.keep"
                else
                    echo "ERROR: Failed to extract $tarball" >> {log}
                    exit 1
                fi
            else
                echo "WARNING: Tarball not found: $tarball" >> {log}
            fi
        }}
        export -f extract_one
        
        # Clear log
        > {log}
        
        # Extract in parallel
        if command -v parallel &> /dev/null; then
            cat {input} | parallel -j {threads} extract_one
        else
            cat {input} | xargs -P {threads} -I {{}} bash -c 'extract_one "{{}}"'
        fi
        
        # Verify extraction
        total_fastq=$(find {params.extract_dir} -name "*.fastq.gz" | wc -l)
        echo "TOTAL: Extracted $total_fastq FASTQ files across all runs" >> {log}
        
        if [ "$total_fastq" -eq 0 ]; then
            echo "ERROR: No FASTQ files found after extraction!" >> {log}
            exit 1
        fi
        
        touch {output.flag}
        """

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
