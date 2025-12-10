#!/bin/bash

# 書き込み可能な場所にJulia環境を設定
export JULIA_DEPOT_PATH="/tmp/julia_depot:/julia_packages"
export JULIA_HISTORY=/dev/null
export JULIA_SCRATCH_TRACK_ACCESS=false
export JULIA_SCRATCH_SPACE=/tmp/julia_scratch
export TMPDIR=/tmp

# 必要なディレクトリを作成
mkdir -p /tmp/julia_depot /tmp/julia_scratch

# Julia実行
/julia_bin/bin/julia src/plot_pairs_w_label_categorical.jl "$@"
