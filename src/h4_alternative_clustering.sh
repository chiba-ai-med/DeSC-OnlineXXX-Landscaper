#!/bin/bash
set -euo pipefail
Rscript --vanilla src/h4_alternative_clustering.R "$@"
