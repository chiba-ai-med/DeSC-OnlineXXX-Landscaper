#!/bin/bash
set -euo pipefail
Rscript --vanilla src/build_person_table.R "$@"
