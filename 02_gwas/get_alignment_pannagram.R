#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(pannagram))
suppressPackageStartupMessages(library(ggplot2))

# Parse arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 4) {
  stop("Usage: Rscript get_alignment.R <beg> <end> <chr> <output_prefix>")
}

beg <- args[1]
end <- args[2]
chr <- args[3]
output_prefix <- args[4]

# Function to get alignment
getalignment <- function(beg, end, chr) {

  aln.seq <- getRegion(
    i.chr     = chr,
    acc       = "100000",
    p.beg     = beg,
    p.end     = end,
    path.proj = "/groups/nordborg/projects/mobilome/05_ufo/alignments/a_thaliana/consortium_458",
    mode      = "seq"
  )

  return(aln.seq)
}

aln.seq <- getalignment(beg, end, chr)

# Save matrix
matrix_path <- paste0(output_prefix, ".matrix.txt")
write.table(aln.seq, file = matrix_path, sep = "\t", row.names = TRUE, col.names = NA)
message("Matrix saved: ", matrix_path)

# Save plot
plot_path <- paste0(output_prefix, ".msa.png")
p <- msadiff(aln.seq)
ggsave(plot_path, p, dpi = 600)

message("Plot saved: ", plot_path)
