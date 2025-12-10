using OnlinePCA
using DelimitedFiles

# Command line arguments
infile = ARGS[1]
outfile1 = ARGS[2]
outfile2 = ARGS[3]

# Exact Out-of-Core PCA
cov_mat, colmeanvec = OnlinePCA.ooc_cov(infile, "raw", 1.0f0, 300000, "sparse_bincoo")

# Output
writedlm(outfile1, cov_mat, ',')
writedlm(outfile2, colmeanvec, ',')
