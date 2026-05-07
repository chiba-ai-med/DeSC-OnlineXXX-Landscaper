# Argument
args <- commandArgs(trailingOnly = TRUE)
infile1 <- args[1]   # Inertia.csv
infile2 <- args[2]   # Total_inertia.csv
outfile <- args[3]

# Load
inertia <- unlist(read.csv(infile1, header=FALSE))
total   <- unlist(read.csv(infile2, header=FALSE))

# Plot
png(outfile, width=800, height=600)
plot(seq_along(inertia),
    cumsum(inertia) / total,
    type="b", pch=19, col="blue",
    xlab="Dimension", ylab="Cumulative Proportion of Inertia",
    main="Cumulative Proportion of Inertia (CA)")
dev.off()
