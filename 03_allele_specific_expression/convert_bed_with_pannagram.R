library(pannagram)
library(optparse)


option_list <- list(
  make_option(c("-i", "--file.input"),      type = "character", help = "input bed file"),
  make_option(c("-a", "--accession.from"),  type = "character", help = "input bed file"),
  make_option(c(     "--accession.to"),     type = "character", help = "input bed file", default = "pangen"),
  make_option(c("-p", "--path.alignment"),  type = "character", help = "input bed file"),
  make_option(c("-o", "--file.output"),     type = "character", help = "output bed file")
)

# Parse command-line arguments
opt <- invisible(parse_args(OptionParser(option_list = option_list)))

# Short aliases
file.input   <- opt$file.input
acc1         <- opt$accession.from
acc2         <- opt$accession.to
path.alignment <- opt$path.alignment
file.output  <- opt$file.output

# Read input BED (expects no header)
pokaz('Reading the table...')
bed1 <- read.table(file.input, header = F)

pokaz('Bed2bed...')
# Lift over BED from 'accession' to 'pangen' using MSA coordinates
# - s.chr sets chromosome column name
# - exact.match = FALSE allows inexact/closest matches
bed2 <- bed2bed(path.proj = path.alignment,
                bed1 = bed1, acc1 = acc1, acc2 = acc2,
                s.chr = "Chr", exact.match = FALSE
)

# Write tab-delimited output without quotes/headers/row names
write.table(
  bed2, file.output,
  quote = FALSE, sep = '\t', col.names = FALSE, row.names = FALSE
)
