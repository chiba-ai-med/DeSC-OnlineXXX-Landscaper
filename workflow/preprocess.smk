from snakemake.utils import min_version

#################################
# Setting
#################################
# Minimum Version of Snakemake
min_version("8.11.1")

rule all:
    input:
        'data/coo.txt.zst',
        'data/dummy_coo.txt.zst',
        'data/disease_label.txt',
        'data/sex_label.txt',
        'data/age_label.txt'

rule bincoo2bin:
    input:
        'data/coo.txt'
    output:
        'data/coo.txt.zst'
    container:
        'docker://ghcr.io/rikenbit/onlinepcajl:98ebff1'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/bincoo2bin.txt'
    log:
        'logs/bincoo2bin.log'
    shell:
        'src/bincoo2bin.sh {input} {output} >& {log}'

rule dummy_bincoo2bin:
    input:
        'data/coo.txt'
    output:
        'data/dummy_coo.txt.zst'
    container:
        'docker://ghcr.io/rikenbit/onlinepcajl:98ebff1'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/dummy_bincoo2bin.txt'
    log:
        'logs/dummy_bincoo2bin.log'
    shell:
        'src/dummy_bincoo2bin.sh {input} {output} >& {log}'

rule disease_label:
    input:
        'data/col_id_disease_name_small.txt',
        'data/coo.txt'
    output:
        'data/disease_label.txt'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250811'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/disease_label.txt'
    log:
        'logs/disease_label.log'
    shell:
        'src/disease_label.sh {input} {output} >& {log}'

rule sex_label:
    input:
        'data/tekiyo.csv',
        'data/row_id_number_small.txt'
    output:
        'data/sex_label.txt'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250811'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/sex_label.txt'
    log:
        'logs/sex_label.log'
    shell:
        'src/sex_label.sh >& {log}'

rule age_label:
    input:
        'data/tekiyo.csv',
        'data/row_id_number_small.txt'
    output:
        'data/age_label.txt'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250811'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/age_label.txt'
    log:
        'logs/age_label.log'
    shell:
        'src/age_label.sh >& {log}'

# 実データの方は手作業でコピー
# Rows: 7581
# Cols: 347,764,079
# cp ../DeSC-investigation/data/small/coo.txt data/

## 行ラベル
# cp ../DeSC-investigation/data/row_id_number_small.txt data/

## 列ラベル
# cp ../DeSC-investigation/data/col_id_number_small.txt data/
