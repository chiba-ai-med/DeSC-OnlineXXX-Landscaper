from snakemake.utils import min_version

#################################
# Setting
#################################
# Minimum Version of Snakemake
min_version("8.11.1")

PCA_DIMS = [str(i) for i in range(6, 8)]

rule all:
    input:
        expand('output/exact_ooc_pca_sparse_bincoo/{pca_dims}/signature_score.csv',
            pca_dims=PCA_DIMS)

rule signature_score:
    input:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/Eigen_vectors.csv',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/Allstates.tsv'
    output:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/signature_score.csv'
    container:
        'docker://ghcr.io/rikenbit/onlinepcajl:98ebff1'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/signature_score_{pca_dims}.txt'
    log:
        'logs/signature_score_{pca_dims}.log'
    shell:
        'src/signature_score.sh {input} {output} >& {log}'    
