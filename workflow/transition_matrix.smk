from snakemake.utils import min_version

#################################
# Setting
#################################
min_version("8.11.1")

PCA_DIM = '7'
T_TEMP  = 1.0
TOP_N   = 12
ZLIM    = 0.45     # Fig 4A/B 共通スケール（Basin 1 対角 max ≒ 0.40 を含む値）
SORT_BY = 'to_basin_rep'   # 並び替え: 'pi_eq' or 'to_basin_rep'（Basin 代表への流入確率降順）

LSCAPER = 'plot/exact_ooc_pca_sparse_bincoo/Landscaper'
ANA_OUT = 'output/analytic'
ANA_PLT = 'plot/analytic'

rule all:
    input:
        f'{ANA_OUT}/{PCA_DIM}/P.tsv',
        f'{ANA_OUT}/{PCA_DIM}/pi_eq.tsv',
        f'{ANA_PLT}/{PCA_DIM}/transition_matrix_basin1.png',
        f'{ANA_PLT}/{PCA_DIM}/transition_matrix_basin2.png',
        f'{ANA_PLT}/{PCA_DIM}/transition_matrix_basin1_full.png',
        f'{ANA_PLT}/{PCA_DIM}/transition_matrix_basin2_full.png',

rule build_transition_matrix:
    input:
        h         = f'{LSCAPER}/{{d}}/h.tsv',
        J         = f'{LSCAPER}/{{d}}/J.tsv',
        allstates = f'{LSCAPER}/{{d}}/Allstates.tsv',
    output:
        P  = f'{ANA_OUT}/{{d}}/P.tsv',
        pi = f'{ANA_OUT}/{{d}}/pi_eq.tsv',
    params:
        T = T_TEMP,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    benchmark:
        'benchmarks/build_transition_matrix_{d}.txt'
    log:
        'logs/build_transition_matrix_{d}.log'
    shell:
        'src/build_transition_matrix.sh {input.h} {input.J} {input.allstates} '
        '{params.T} {output.P} {output.pi} >& {log}'

rule plot_transition_matrix_basin1:
    input:
        P        = f'{ANA_OUT}/{{d}}/P.tsv',
        pi       = f'{ANA_OUT}/{{d}}/pi_eq.tsv',
        subgraph = f'{LSCAPER}/{{d}}/SubGraph.tsv',
        basin    = f'{LSCAPER}/{{d}}/Basin.tsv',
    output:
        f'{ANA_PLT}/{{d}}/transition_matrix_basin1.png',
    params:
        top_n   = TOP_N,
        basin   = 1,
        zlim    = ZLIM,
        sort_by = SORT_BY,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    benchmark:
        'benchmarks/plot_transition_matrix_basin1_{d}.txt'
    log:
        'logs/plot_transition_matrix_basin1_{d}.log'
    shell:
        'src/plot_transition_matrix.sh {input.P} {input.pi} {input.subgraph} '
        '{output} {params.top_n} {params.basin} {input.basin} {params.zlim} {params.sort_by} >& {log}'

rule plot_transition_matrix_basin2:
    input:
        P        = f'{ANA_OUT}/{{d}}/P.tsv',
        pi       = f'{ANA_OUT}/{{d}}/pi_eq.tsv',
        subgraph = f'{LSCAPER}/{{d}}/SubGraph.tsv',
        basin    = f'{LSCAPER}/{{d}}/Basin.tsv',
    output:
        f'{ANA_PLT}/{{d}}/transition_matrix_basin2.png',
    params:
        top_n   = TOP_N,
        basin   = 2,
        zlim    = ZLIM,
        sort_by = SORT_BY,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    benchmark:
        'benchmarks/plot_transition_matrix_basin2_{d}.txt'
    log:
        'logs/plot_transition_matrix_basin2_{d}.log'
    shell:
        'src/plot_transition_matrix.sh {input.P} {input.pi} {input.subgraph} '
        '{output} {params.top_n} {params.basin} {input.basin} {params.zlim} {params.sort_by} >& {log}'


# Full 版（basin 内 全メンバー、Supplementary 用）：top_n を 9999 にすれば自動的に basin サイズで打ち切られる
rule plot_transition_matrix_basin1_full:
    input:
        P        = f'{ANA_OUT}/{{d}}/P.tsv',
        pi       = f'{ANA_OUT}/{{d}}/pi_eq.tsv',
        subgraph = f'{LSCAPER}/{{d}}/SubGraph.tsv',
        basin    = f'{LSCAPER}/{{d}}/Basin.tsv',
    output:
        f'{ANA_PLT}/{{d}}/transition_matrix_basin1_full.png',
    params:
        top_n   = 9999,
        basin   = 1,
        zlim    = ZLIM,
        sort_by = SORT_BY,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    benchmark:
        'benchmarks/plot_transition_matrix_basin1_full_{d}.txt'
    log:
        'logs/plot_transition_matrix_basin1_full_{d}.log'
    shell:
        'src/plot_transition_matrix.sh {input.P} {input.pi} {input.subgraph} '
        '{output} {params.top_n} {params.basin} {input.basin} {params.zlim} {params.sort_by} >& {log}'

rule plot_transition_matrix_basin2_full:
    input:
        P        = f'{ANA_OUT}/{{d}}/P.tsv',
        pi       = f'{ANA_OUT}/{{d}}/pi_eq.tsv',
        subgraph = f'{LSCAPER}/{{d}}/SubGraph.tsv',
        basin    = f'{LSCAPER}/{{d}}/Basin.tsv',
    output:
        f'{ANA_PLT}/{{d}}/transition_matrix_basin2_full.png',
    params:
        top_n   = 9999,
        basin   = 2,
        zlim    = ZLIM,
        sort_by = SORT_BY,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    benchmark:
        'benchmarks/plot_transition_matrix_basin2_full_{d}.txt'
    log:
        'logs/plot_transition_matrix_basin2_full_{d}.log'
    shell:
        'src/plot_transition_matrix.sh {input.P} {input.pi} {input.subgraph} '
        '{output} {params.top_n} {params.basin} {input.basin} {params.zlim} {params.sort_by} >& {log}'
