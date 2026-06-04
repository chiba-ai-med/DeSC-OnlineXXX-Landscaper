from snakemake.utils import min_version

min_version("8.11.1")

# COO データ構造調査用（calibration 設計のため）。確定後は削除可。

rule all:
    input:
        'data/coo_structure_check.log'

rule check_coo_structure:
    input:
        'data/coo.txt.zst'
    output:
        'data/coo_structure_check.log'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=4000
    benchmark:
        'benchmarks/check_coo_structure.txt'
    log:
        'logs/check_coo_structure.log'
    shell:
        'src/check_coo_structure.sh {input} {output} 200000000 2> {log}'
