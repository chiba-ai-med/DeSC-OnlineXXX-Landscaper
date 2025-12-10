using OnlineNMF

# Command line arguments
infile = ARGS[1]
outdir = dirname(ARGS[2])

# BinCOO DNMF
println("BinCOO DNMF")
out = bincoo_dnmf(
    input=infile,
    graphv = 0, teru = 0, terv = 0,
    l1u = eps(Float32), l1v = 0, l2u = 0, l2v = 0,
    dim=10, beta=2, numepoch=1, binu=10^2, chunksize=10000)
# numepochを10に直す

# Output
println("Output")
OnlineNMF.output(outdir, out, 0)