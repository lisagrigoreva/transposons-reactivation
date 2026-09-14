#!/usr/bin/env Rscript

## Get a GFF file for one accession using a GFF file from another accession
options(scipen = 999)
library(pannagram) # make sure conda activate pannagram
# library(data.table)
library(rhdf5)

path.cons = "/groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression/pannagram_tair10_based"  # the result of pannagram
path.out = "/groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression/converted_gff2_tair10_based"

n.chr = 5
ref.acc = '0'

gr.accs.e <- "accs/"
gr.accs.b <- "/accs"

# Read the list of accessions
accession_list_file = "/groups/nordborg/projects/ddm1_resilencing/03_processing/007_allele_specific_expression/longread_genomes/names.txt"
accession_names = readLines(accession_list_file)

# Extract accession names (remove .Chr_scaffolds.fa extension)
#accession_names = gsub("\\.Chr_scaffolds\\.fa$", "", accession_names)

# Create accessions list with TAIR10 as reference
accs = c("TAIR10" = 'TAIR10')
for(acc_name in accession_names) {
    accs[acc_name] = paste0(acc_name, ".Chr_scaffolds")
}

print("Processing accessions:")
print(names(accs))

# Read GFF
file.gff.acc1 = "/groups/nordborg/projects/ddm1_resilencing/11_resources/ref_genome/TAIR10_GFF3_genes_transposons.gff"
gff1 = read.table(file.gff.acc1, stringsAsFactors = F, fill=T)
#gff1$V9 <- paste0(gff1$V9, ";panidentifier=panidentifier.", 1:nrow(gff1)) # This you can skip if you want, just a secondary annotation identifier

# Chromosome IDs
# Filter unwanted chromosomes
gff1 = gff1[grepl("^Chr[1-5]$", gff1$V1), ]
gff1 = gff1[!gff1$V3 %in% c('chromosome'), ] # Filter chromosome feature
gff1$V4 = as.numeric(gff1$V4)
gff1$V5 = as.numeric(gff1$V5)  # remove wrong names

head(gff1)
acc1 <- accs[1]  # TAIR10 as reference

# Loop through all accessions (skip TAIR10 which is index 1)
for(i in 2:length(accs)) {
    acc2 <- accs[i]
    acc2_name <- names(accs)[i]
    
    cat("Processing accession:", acc2_name, "->", acc2, "\n")
    
    # Convert GFF Annotations from acc1 to acc2
    tryCatch({
        gff2 = gff2gff(path.cons, acc1 = acc1, acc2 = acc2, gff1 = gff1, s.chr = 'Chr', 
                       exact.match = T, n.chr = 5, aln.type = "ref_", ref.acc="TAIR10")
        
        # Add chromosome prefix
        gff2$V1 <- paste0(acc2_name, "_", gff2$V1)
        gff2 <- gff2[! is.na(gff2$V4) & ! is.na(gff2$V5), ]
        
        # Save
        output_file = paste(path.out, "/", acc2_name, '_based_on_', names(accs)[1], '.gff', sep = '')
        write.table(gff2[,1:9], output_file,
                    quote = F, col.names = F, row.names = F, sep = '\t')
        
        cat("Successfully processed and saved:", output_file, "\n")
        
    }, error = function(e) {
        cat("Error processing accession", acc2_name, ":", e$message, "\n")
    })
}

cat("Processing complete!\n")

