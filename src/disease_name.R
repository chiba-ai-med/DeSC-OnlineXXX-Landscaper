# Argument
args <- commandArgs(trailingOnly = TRUE)
infile <- args[1]
outfile <- args[2]

# Load
disease_name <- read.csv(infile, header=FALSE)

# Save
write.table(values, file=outfile, row.names=FALSE, col.names=FALSE, sep=",")
