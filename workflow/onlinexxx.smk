from snakemake.utils import min_version

#################################
# Setting
#################################
# Minimum Version of Snakemake
min_version("8.11.1")

PCA_DIMS = [str(i) for i in range(2, 8)]

rule all:
    input:
        'output/ooc_cov/cov_mat.csv',
        'output/ooc_cov/colmeanvec.csv',
        'output/ooc_cov/eigenvalues.csv',
        'output/ooc_cov/eigenvectors.csv',
        expand('output/exact_ooc_pca_sparse_bincoo/{pca_dims}/Scores.csv',
            pca_dims=PCA_DIMS),
        expand('output/exact_ooc_pca_sparse_bincoo/{pca_dims}/Scores.mm',
            pca_dims=PCA_DIMS)

rule onlinepca_ooc_cov:
    input:
        'data/coo.txt.zst'
    output:
        'output/ooc_cov/cov_mat.csv',
        'output/ooc_cov/colmeanvec.csv',
    container:
        'docker://ghcr.io/rikenbit/onlinepcajl:df65589'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/onlinepca_ooc_cov.txt'
    log:
        'logs/onlinepca_ooc_cov.log'
    shell:
        'src/onlinepca_ooc_cov.sh {input} {output} >& {log}'

rule eigen:
    input:
        'output/ooc_cov/cov_mat.csv'
    output:
        'output/ooc_cov/eigenvalues.csv',
        'output/ooc_cov/eigenvectors.csv'
    container:
        'docker://koki/desc_investigation:20240508'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/eigen.txt'
    log:
        'logs/eigen.log'
    shell:
        'src/eigen.sh {input} {output} >& {log}'

rule onlinepca_exact_ooc_pca_sparse_bincoo:
    input:
        'data/coo.txt.zst'
    output:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/Scores.csv',
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/Scores.mm'
    container:
        'docker://koki/mmjl:20250725'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/onlinepca_exact_ooc_pca_sparse_bincoo_{pca_dims}.txt'
    log:
        'logs/onlinepca_exact_ooc_pca_sparse_bincoo_{pca_dims}.log'
    shell:
        'src/onlinepca_exact_ooc_pca_sparse_bincoo.sh {input} {output} {wildcards.pca_dims} >& {log}'
