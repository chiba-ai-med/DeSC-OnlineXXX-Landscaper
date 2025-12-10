from snakemake.utils import min_version

#################################
# Setting
#################################
# Minimum Version of Snakemake
min_version("8.11.1")

PCA_DIMS = [str(i) for i in range(6, 8)]

rule all:
    input:
        expand('output/exact_ooc_pca_sparse_bincoo/{pca_dims}/frequency.csv',
            pca_dims=PCA_DIMS)

rule frequency:
    input:
        'data/coo.txt.zst',
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/Scores.mm',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/Allstates.tsv'
    output:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/frequency.csv'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20251031'
    resources:
        mem_mb=1000000000
    benchmark:
        'benchmarks/frequency_{pca_dims}.txt'
    log:
        'logs/frequency_{pca_dims}.log'
    shell:
        'src/frequency.sh {input} {output} >& {log}'    
