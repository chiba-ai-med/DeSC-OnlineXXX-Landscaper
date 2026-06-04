#!/bin/bash
set -euo pipefail
Rscript --vanilla src/transition_diff_analyze.R "$@"
