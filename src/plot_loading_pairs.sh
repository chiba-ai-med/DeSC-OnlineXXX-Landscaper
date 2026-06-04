#!/bin/bash
set -euo pipefail
Rscript --vanilla src/plot_loading_pairs.R "$@"
