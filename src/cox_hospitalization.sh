#!/bin/bash
set -euo pipefail
Rscript --vanilla src/cox_hospitalization.R "$@"
