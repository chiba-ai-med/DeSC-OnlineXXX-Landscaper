from snakemake.utils import min_version

#################################
# Setting
#################################
min_version("8.11.1")

rule all:
    input:
        'data/who_icd10_en.tsv',
        'data/col_id_disease_name_en_small.txt',
        'data/missing_en_codes.tsv'

rule extract_icd10_en:
    output:
        'data/who_icd10_en.tsv'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/extract_icd10_en.txt'
    log:
        'logs/extract_icd10_en.log'
    shell:
        'src/extract_icd10_en.sh {output} >& {log}'

rule merge_disease_name_en:
    input:
        'data/col_id_disease_name_small.txt',
        'data/who_icd10_en.tsv'
    output:
        'data/col_id_disease_name_en_small.txt',
        'data/missing_en_codes.tsv'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/merge_disease_name_en.txt'
    log:
        'logs/merge_disease_name_en.log'
    shell:
        'src/merge_disease_name_en.sh {input} {output} >& {log}'
