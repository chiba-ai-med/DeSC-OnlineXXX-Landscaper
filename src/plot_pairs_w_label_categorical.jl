# Arguments
infile1 = ARGS[1]
infile2 = ARGS[2]
outfile = ARGS[3]
# infile1 = "output/exact_ooc_pca_sparse_bincoo/10/dummy_Scores.csv"
# infile2 = "data/dummy_disease_label.txt"
# outfile = "hoge.png"

include(joinpath(@__DIR__, "Functions.jl"))

pair_density_plots(infile1;
    cols = 1:7,
    nbins = (100,100),
    outfile = outfile,
    labels_path = infile2,
    label_kind = :categorical,        # ←カテゴリカル
    print_every = 2_000_000
)