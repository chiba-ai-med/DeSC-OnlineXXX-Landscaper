# Command line arguments
COO_PATH  = ARGS[1]
BINSCORES = ARGS[2]   # Scores.mm (Matrix Market: x y of positive entries)
ALLSTATES = ARGS[3]
OUTFILE   = ARGS[4]
OUTDIR    = dirname(OUTFILE)
COLS      = 7581
BLOCK     = 512

include(joinpath(@__DIR__, "Functions.jl"))

pat2id = load_pattern_dict(ALLSTATES)
row2pat_bin = build_row2pat_from_mm(BINSCORES, pat2id, OUTDIR)
row2pat = mmap_row2pat(row2pat_bin)
build_frequency(COO_PATH, row2pat, OUTDIR, OUTFILE, COLS, BLOCK)
@info "DONE" OUTFILE