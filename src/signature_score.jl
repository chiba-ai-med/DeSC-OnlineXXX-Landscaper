using DelimitedFiles
using LinearAlgebra
using Random
using Statistics

# Command line arguments
infile1 = ARGS[1]
infile2 = ARGS[2]
outfile = ARGS[3]
# infile1 = "output/exact_ooc_pca_sparse_bincoo/6/Eigen_vectors.csv"
# infile2 = "plot/exact_ooc_pca_sparse_bincoo/Landscaper/6/Allstates.tsv"
# outfile = "output/exact_ooc_pca_sparse_bincoo/6/signature_score.csv"
B      = 1000
seed   = 1234
Random.seed!(seed)

# Load (no headers, no row names)
V = Float32.(readdlm(infile1, ','))   # D x k
S = Float32.(readdlm(infile2, '\t'))  # P x k

# Sanity
size(V,2) == size(S,2) || error("列数 k が一致していません: size(V,2)=$(size(V,2)), size(S,2)=$(size(S,2))")
D, k = size(V)
P, _ = size(S)
@info "Loaded" D=D P=P k=k B=B

# Observed scores (D x P)
Obs = S * transpose(V)

# Permutation test
ge_count = zeros(Int32, size(Obs))
Sperm = similar(S)
perm_idx = collect(1:P)

for b in 1:B
    # 列ごとに独立に行シャッフル
    @inbounds for j in 1:k
        shuffle!(perm_idx)
        @views Sperm[:, j] .= S[perm_idx, j]
    end
    Sc = Sperm * transpose(V)
    @inbounds ge_count .+= (Sc .>= Obs)  # 片側（右裾）
    # 進捗表示（上書き）
    print("\rProcessing permutation $b / $B")
    flush(stdout)
end

# p-values with +1 correction
pval = (ge_count .+ 1.0f0) ./ (B + 1.0f0)   # Float32, D x P

# Save (comma-delimited)
writedlm(outfile, pval, ',')

@info "Done" outfile size=size(pval)
