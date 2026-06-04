#!/bin/bash
set -euo pipefail
Rscript --vanilla src/h1_lipid_phenotype.R "$@"
