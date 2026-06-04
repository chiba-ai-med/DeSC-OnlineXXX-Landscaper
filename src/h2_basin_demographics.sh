#!/bin/bash
set -euo pipefail
Rscript --vanilla src/h2_basin_demographics.R "$@"
