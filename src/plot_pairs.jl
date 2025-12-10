# Arguments
infile = ARGS[1]
outfile = ARGS[2]
# infile = "output/exact_ooc_pca_sparse_bincoo/10/dummy_Scores.csv"
# outfile = "hoge.png"

include(joinpath(@__DIR__, "Functions.jl"))

pair_density_plots(infile;
    cols = 1:7,
    nbins = (100,100),
    outfile = outfile,
    print_every = 2_000_000
)
