# Argument
args <- commandArgs(trailingOnly = TRUE)
infile1 <- args[1]
outfile1 <- args[2]
outfile2 <- args[3]

# Load
cov_mat <- read.csv(infile1, header=FALSE)

# Eigen decomposition
out <- eigen(cov_mat)
values <- out$values
vectors <- out$vectors

# Save
write.table(values, file=outfile1, row.names=FALSE, col.names=FALSE, sep=",")
write.table(vectors, file=outfile2, row.names=FALSE, col.names=FALSE, sep=",")
