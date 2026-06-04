from snakemake.utils import min_version

min_version("8.11.1")

PCA_DIM     = '7'
N_PATTERNS  = 128       # 2^7
GAP_MONTHS  = 6         # 独立スナップショット（半年離れ、重複なし）

rule all:
    input:
        f'output/calibrate/{PCA_DIM}/summary_gap{GAP_MONTHS}.tsv',
        f'output/calibrate/{PCA_DIM}/pair_counts_gap{GAP_MONTHS}.tsv',
        f'output/calibrate/{PCA_DIM}/step_time_exact.tsv',

rule calibrate_step_time:
    input:
        row_id   = 'data/row_id_number_small.txt',
        row2pat  = f'output/exact_ooc_pca_sparse_bincoo/{PCA_DIM}/row2pat.bin',
        subgraph = f'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{PCA_DIM}/SubGraph.tsv',
    output:
        summary = f'output/calibrate/{PCA_DIM}/summary_gap{GAP_MONTHS}.tsv',
        pairs   = f'output/calibrate/{PCA_DIM}/pair_counts_gap{GAP_MONTHS}.tsv',
    params:
        n_patterns = N_PATTERNS,
        gap_months = GAP_MONTHS,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=16000
    benchmark:
        f'benchmarks/calibrate_step_time_gap{GAP_MONTHS}.txt'
    log:
        f'logs/calibrate_step_time_gap{GAP_MONTHS}.log'
    shell:
        'src/calibrate_step_time.sh {input.row_id} {input.row2pat} '
        '{params.n_patterns} {output.summary} {output.pairs} {params.gap_months} '
        '{input.subgraph} >& {log}'

rule calibrate_step_time_exact:
    input:
        h         = f'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{PCA_DIM}/h.tsv',
        J         = f'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{PCA_DIM}/J.tsv',
        allstates = f'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{PCA_DIM}/Allstates.tsv',
        summary   = f'output/calibrate/{PCA_DIM}/summary_gap{GAP_MONTHS}.tsv',
        subgraph  = f'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{PCA_DIM}/SubGraph.tsv',
    output:
        f'output/calibrate/{PCA_DIM}/step_time_exact.tsv',
    params:
        T = 1.0,
        N_max = 500,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    benchmark:
        f'benchmarks/calibrate_step_time_exact.txt'
    log:
        f'logs/calibrate_step_time_exact.log'
    shell:
        'src/calibrate_step_time_exact.sh {input.h} {input.J} {input.allstates} '
        '{input.summary} {params.T} {output} {input.subgraph} {params.N_max} >& {log}'
