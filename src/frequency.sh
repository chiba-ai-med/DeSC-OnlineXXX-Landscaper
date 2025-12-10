export PATH="/julia_bin/bin:${PATH}"
mkdir -p /tmp/julia_depot /tmp/julia_scratch

# 先頭を /tmp に変更（書き込み可）→ 2番目に /julia_packages（読み取り専用でもOK）
export JULIA_DEPOT_PATH="/tmp/julia_depot:/julia_packages"

export JULIA_PKG_PRECOMPILE_AUTO=0
export JULIA_SCRATCH_SPACE=/tmp/julia_scratch
export JULIA_SCRATCH_TRACK_ACCESS=false
export JULIA_HISTORY=/dev/null

julia --startup-file=no src/frequency.jl "$@"
