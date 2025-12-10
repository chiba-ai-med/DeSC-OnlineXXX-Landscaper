using OnlinePCA
using MatrixMarket
using SparseArrays

# Command line arguments
infile = ARGS[1]
outdir = dirname(ARGS[2])
outfile = ARGS[3]
dims = parse(Int, ARGS[4])

# Exact Out-of-Core PCA
out = exact_ooc_pca(
	input=infile,
	scale="raw", dim=dims, chunksize=300000, mode="sparse_bincoo")

# Output
OnlinePCA.output(outdir, out, 0.1f0)

# Save MM file
S = sparse(out[4] .> 0)
mmwrite(outfile, S)
