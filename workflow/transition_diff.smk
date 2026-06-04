from snakemake.utils import min_version

min_version("8.11.1")

PCA_DIM   = '7'
TOP_N     = 10
N_ROWS    = 347764079        # COO の行数
PCA_BASE  = 'output/exact_ooc_pca_sparse_bincoo'
COV_BASE  = 'output/ooc_cov'
LSCAPER   = 'plot/exact_ooc_pca_sparse_bincoo/Landscaper'
NAME_EN   = 'data/col_id_disease_name_en_small.txt'

ANA_OUT   = 'output/analytic'
ANA_PLT   = 'plot/analytic'

# Sub-pattern → Basin 代表 (Basin に吸収される向き、ELA で energy 降下方向)
# Δ = s_basin - s_sub、w = L Δ で「Basin に近づくとき増減する疾患」が出る
PAIRS_BASIN1 = [(24, 32), (64, 32), (96, 32), (28, 32), (30, 32)]
PAIRS_BASIN2 = [(107, 75), (73, 75), (67, 75)]
ALL_PAIRS    = PAIRS_BASIN1 + PAIRS_BASIN2

rule all:
    input:
        expand(f'{ANA_OUT}/{PCA_DIM}/transition_diff/pair_{{i}}_{{j}}.tsv',
               zip,
               i=[p[0] for p in ALL_PAIRS],
               j=[p[1] for p in ALL_PAIRS]),
        expand(f'{ANA_PLT}/{PCA_DIM}/transition_diff/pair_{{i}}_{{j}}.png',
               zip,
               i=[p[0] for p in ALL_PAIRS],
               j=[p[1] for p in ALL_PAIRS]),
        f'{ANA_PLT}/{PCA_DIM}/transition_diff_basin1.png',
        f'{ANA_PLT}/{PCA_DIM}/transition_diff_basin2.png',

rule analyze_pair:
    input:
        L         = f'{PCA_BASE}/{{d}}/Eigen_vectors.csv',
        allstates = f'{LSCAPER}/{{d}}/Allstates.tsv',
        colmean   = f'{COV_BASE}/colmeanvec.csv',
        eigval    = f'{PCA_BASE}/{{d}}/Eigen_values.csv',
        name_en   = NAME_EN,
    output:
        tsv = f'{ANA_OUT}/{{d}}/transition_diff/pair_{{i}}_{{j}}.tsv',
        png = f'{ANA_PLT}/{{d}}/transition_diff/pair_{{i}}_{{j}}.png',
    params:
        n_rows = N_ROWS,
        top_n  = TOP_N,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    log:
        'logs/transition_diff_pair_{d}_{i}_{j}.log'
    benchmark:
        'benchmarks/transition_diff_pair_{d}_{i}_{j}.txt'
    shell:
        'src/transition_diff_analyze.sh {input.L} {input.allstates} {input.colmean} '
        '{input.eigval} {input.name_en} {wildcards.i} {wildcards.j} {params.n_rows} '
        '{params.top_n} {output.tsv} {output.png} >& {log}'

rule plot_basin_panel_1:
    input:
        tsvs = [f'{ANA_OUT}/{PCA_DIM}/transition_diff/pair_{i}_{j}.tsv'
                for (i, j) in PAIRS_BASIN1],
    output:
        f'{ANA_PLT}/{PCA_DIM}/transition_diff_basin1.png',
    params:
        top_n = TOP_N,
        label = 'Basin 1 (rep = pattern 32): transitions to sub-patterns',
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    log:
        'logs/transition_diff_panel_basin1.log'
    shell:
        'src/transition_diff_panel.sh {output} {params.top_n} "{params.label}" {input.tsvs} >& {log}'

rule plot_basin_panel_2:
    input:
        tsvs = [f'{ANA_OUT}/{PCA_DIM}/transition_diff/pair_{i}_{j}.tsv'
                for (i, j) in PAIRS_BASIN2],
    output:
        f'{ANA_PLT}/{PCA_DIM}/transition_diff_basin2.png',
    params:
        top_n = TOP_N,
        label = 'Basin 2 (rep = pattern 75): transitions to sub-patterns',
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    log:
        'logs/transition_diff_panel_basin2.log'
    shell:
        'src/transition_diff_panel.sh {output} {params.top_n} "{params.label}" {input.tsvs} >& {log}'
