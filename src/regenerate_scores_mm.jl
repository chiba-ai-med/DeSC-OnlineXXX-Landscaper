using DelimitedFiles
using SparseArrays

infile = ARGS[1]
outfile = ARGS[2]

# Read Row_coordinates.csv
F = readdlm(infile, ',', Float64)

# Binarize and convert to sparse
S = sparse(F .> 0)

# Write MM file (pattern general, same as OnlinePCA)
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
