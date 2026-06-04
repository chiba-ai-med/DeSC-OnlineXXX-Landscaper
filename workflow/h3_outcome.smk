from snakemake.utils import min_version

min_version("8.11.1")

# Phase 2: H3 (age-PC sign decomposition) + Cox Models 1-4
# 入力: output/person_table.tsv (Phase 1 で生成済み)

LSCAPER  = 'plot/exact_ooc_pca_sparse_bincoo/Landscaper'
PCA_DIM  = '7'

CONTAINER = 'docker://koki/desc_onlinexxx_landscaper:20260602'

rule all:
    input:
        'output/h3/age_pc_sign.tsv',
        'plot/h3/age_pc_sign.png',
        'output/cox/cox_model3_basin.tsv',
        'output/cox/cox_model4_energy.tsv',
        'output/cox/cox_model1_univariate_pc.tsv',
        'output/cox/cox_model2_multivariate_pc.tsv',
        'plot/cox/km_basin.png',
        'plot/cox/km_energy.png',
        'plot/cox/forest_pc.png',

rule h3_age_pc_sign:
    input:
        pt        = 'output/person_table.tsv',
        allstates = f'{LSCAPER}/{PCA_DIM}/Allstates.tsv',
    output:
        tsv = 'output/h3/age_pc_sign.tsv',
        png = 'plot/h3/age_pc_sign.png',
    container: CONTAINER
    resources:
        mem_mb=8000
    benchmark:
        'benchmarks/h3_age_pc_sign.txt'
    log:
        'logs/h3_age_pc_sign.log'
    shell:
        'src/h3_age_pc_sign.sh {input.pt} {input.allstates} {output.tsv} {output.png} '
        '>& {log}'

rule cox_models:
    input:
        pt = 'output/person_table.tsv',
    output:
        m1 = 'output/cox/cox_model1_univariate_pc.tsv',
        m2 = 'output/cox/cox_model2_multivariate_pc.tsv',
        m3 = 'output/cox/cox_model3_basin.tsv',
        m4 = 'output/cox/cox_model4_energy.tsv',
        km_basin = 'plot/cox/km_basin.png',
        km_energy = 'plot/cox/km_energy.png',
        forest   = 'plot/cox/forest_pc.png',
    params:
        out_dir = 'output/cox',
    container: CONTAINER
    resources:
        mem_mb=24000
    benchmark:
        'benchmarks/cox_models.txt'
    log:
        'logs/cox_models.log'
    shell:
        # cox の出力は output/cox/ と plot/cox/ に分散したいので、
        # 1つの out_dir に出して後で move する
        'mkdir -p plot/cox && '
        'src/cox_models.sh {input.pt} {params.out_dir} >& {log} && '
        'mv {params.out_dir}/km_basin.png  {output.km_basin} && '
        'mv {params.out_dir}/km_energy.png {output.km_energy} && '
        'mv {params.out_dir}/forest_pc.png {output.forest}'
