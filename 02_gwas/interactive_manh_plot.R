#!/usr/bin/env Rscript

#' Script to create an interactive Manhattan plot from the results of GWAS with
#' GEMMA. This assumes p-values have been calculated with likelihood ratio
#' tests.
#'
#' To make the file smaller, you can set a minimum -log10 p-value.
#'
#' Tom Ellis 21st January 2025.


library('manhattanly', quietly = TRUE)
library("htmlwidgets")
library("optparse")

option_list = list(
  make_option(c("-i", "--input"), type="character", default=NULL,
              help="Results file from GEMMA", metavar="character"),
  make_option(c("-t", "--threshold"), type="numeric", default=2,
              help="Minimum -log10 p-value to draw points", metavar="character")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

cat(paste("\nCreating an interactive Manhattan plot for GEMMA results file:\n", opt$input))

cat("\nLoading the results file.")
gwas <- read.delim(opt$input, sep = "\t")

cat("\nCreating the HTML plot.")
mh <- manhattanly(
  gwas[-log10(gwas$p_lrt) > opt$threshold,],
  chr="chr", bp='ps', p="p_lrt", snp = "ps", annotation1='af',
  title = gsub(".assoc.txt", "", opt$input)
  )

cat(paste("\nSaving to disk as", gsub(".assoc.txt", "_manhattan.html", opt$input)))
htmlwidgets::saveWidget(
  mh,
  file = gsub(".assoc.txt", "_manhattan.html", opt$input)
)

