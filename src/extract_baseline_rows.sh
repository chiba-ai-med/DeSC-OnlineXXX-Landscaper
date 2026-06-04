#!/bin/bash
# Julia 環境 (CodecZstd 等は不要、ただし JULIA_DEPOT_PATH を設定する)
export JULIA_DEPOT_PATH="/tmp/julia_depot:/julia_packages"
export JULIA_HISTORY=/dev/null
export JULIA_SCRATCH_TRACK_ACCESS=false
export JULIA_SCRATCH_SPACE=/tmp/julia_scratch
export TMPDIR=/tmp
mkdir -p /tmp/julia_depot /tmp/julia_scratch
/julia_bin/bin/julia src/extract_baseline_rows.jl "$@"
