# Argument
args <- commandArgs(trailingOnly = TRUE)
infile <- args[1]
outfile1 <- args[2]
outfile2 <- args[3]

# Load
values <- unlist(read.csv(infile, header=FALSE))

# Plot
png(outfile1, width=800, height=600)
plot(seq_along(values),
    cumsum(values) / sum(values),
    type="b", pch=19, col="blue",
    xlab="Index", ylab="Cumulative Sum of Eigenvalues",
    main="Cumulative Sum of Eigenvalues")
dev.off()

png(outfile2, width=800, height=600)
plot(seq(100),
    (cumsum(values) / sum(values))[seq(100)],
    type="b", pch=19, col="blue",
    xlab="Index", ylab="Cumulative Sum of Eigenvalues",
    main="Cumulative Sum of Eigenvalues")
dev.off()
