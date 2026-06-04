from snakemake.utils import min_version

min_version("8.11.1")

# Phase 1: person-level base table
# 1) row_id_number_small.txt から各 kojin_id の最初の row_id を抽出
# 2) Scores.csv + row2pat.bin で baseline 時点の PC1-7 + pattern_id を抽出
# 3) tekiyo.csv + SubGraph/Basin/E と join して person_table.tsv に出力

PCA_DIM  = '7'
PCA_BASE = 'output/exact_ooc_pca_sparse_bincoo'
LSCAPER  = 'plot/exact_ooc_pca_sparse_bincoo/Landscaper'

CONTAINER_JL = 'docker://koki/desc_onlinexxx_landscaper:20260602'
CONTAINER_R  = 'docker://koki/desc_onlinexxx_landscaper:20260602'

rule all:
    input:
        'output/person_table.tsv'

rule extract_baseline_rows:
    input:
        'data/row_id_number_small.txt'
    output:
        'data/baseline_row.tsv'
    container:
        CONTAINER_JL
    resources:
        mem_mb=4000
    benchmark:
        'benchmarks/extract_baseline_rows.txt'
    log:
        'logs/extract_baseline_rows.log'
    shell:
        'bash src/extract_baseline_rows.sh {input} {output} >& {log}'

rule extract_baseline_features:
    input:
        scores  = f'{PCA_BASE}/{PCA_DIM}/Scores.csv',
        rowmap  = 'data/baseline_row.tsv',
        row2pat = f'{PCA_BASE}/{PCA_DIM}/row2pat.bin',
    output:
        'data/baseline_features.tsv'
    container:
        CONTAINER_JL
    resources:
        mem_mb=8000
    benchmark:
        'benchmarks/extract_baseline_features.txt'
    log:
        'logs/extract_baseline_features.log'
    shell:
        'bash src/extract_baseline_features.sh {input.scores} {input.rowmap} '
        '{input.row2pat} {output} >& {log}'

rule build_person_table:
    input:
        feat     = 'data/baseline_features.tsv',
        tekiyo   = 'data/tekiyo.csv',
        subgraph = f'{LSCAPER}/{PCA_DIM}/SubGraph.tsv',
        basin    = f'{LSCAPER}/{PCA_DIM}/Basin.tsv',
        energy   = f'{LSCAPER}/{PCA_DIM}/E.tsv',
    output:
        'output/person_table.tsv'
    container:
        CONTAINER_R
    resources:
        mem_mb=8000
    benchmark:
        'benchmarks/build_person_table.txt'
    log:
        'logs/build_person_table.log'
    shell:
        'src/build_person_table.sh {input.feat} {input.tekiyo} {input.subgraph} '
        '{input.basin} {input.energy} {output} >& {log}'
