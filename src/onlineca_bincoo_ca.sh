mkdir -p /tmp/julia_depot
export JULIA_DEPOT_PATH="/tmp/julia_depot:/usr/local/julia"
export JULIA_HISTORY="/dev/null"

/usr/local/julia/bin/julia src/onlineca_bincoo_ca.jl $@
