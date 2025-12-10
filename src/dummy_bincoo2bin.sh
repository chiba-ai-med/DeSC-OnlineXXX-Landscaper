export JULIA_DEPOT_PATH=/usr/local/julia
export JULIA_HISTORY=/dev/null

head -10000 $1 > data/dummy_coo.txt

julia src/bincoo2bin.jl data/dummy_coo.txt data/dummy_coo.txt.zst
