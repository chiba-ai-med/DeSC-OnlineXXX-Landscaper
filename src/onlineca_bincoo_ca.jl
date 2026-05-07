using OnlineCA
using SparseArrays

# Command line arguments
infile = ARGS[1]
outdir = dirname(ARGS[2])
outfile = ARGS[3]
dims = parse(Int, ARGS[4])

# Correspondence Analysis (Binary COO)
out = bincoo_ca(
	input=infile,
	dim=dims, chunksize=300000)

# Output
OnlineCA.output(outdir, out)

# Save MM file
S = sparse(out[1] .> 0)
open(outfile, "w") do io
	m, n = size(S)
	println(io, "%%MatrixMarket matrix coordinate pattern general")
	println(io, m, " ", n, " ", nnz(S))
	rows = rowvals(S)
	for j in 1:n
		for idx in nzrange(S, j)
			println(io, rows[idx], " ", j)
		end
	end
end
