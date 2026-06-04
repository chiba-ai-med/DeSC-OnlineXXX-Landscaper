#!/bin/bash
set -euo pipefail
Rscript --vanilla src/atc_or_by_basin.R "$@"
