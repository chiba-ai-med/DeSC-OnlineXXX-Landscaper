#!/bin/bash
set -euo pipefail
Rscript --vanilla src/cox_models.R "$@"
