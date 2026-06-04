#!/bin/bash
set -euo pipefail
Rscript --vanilla src/h3_age_pc_sign.R "$@"
