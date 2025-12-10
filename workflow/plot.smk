from snakemake.utils import min_version

#################################
# Setting
#################################
# Minimum Version of Snakemake
min_version("8.11.1")

PCA_DIMS = [str(i) for i in range(6, 8)]

rule all:
    input:
        'plot/exact_ooc_pca_sparse_bincoo/eigenvalues.png',
        'plot/exact_ooc_pca_sparse_bincoo/eigenvalues_100.png',
        expand('plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/signature_score/FINISH',
               pca_dims=PCA_DIMS),
        expand('plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/frequency/FINISH',
               pca_dims=PCA_DIMS),
        expand('plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/logitdiff/FINISH',
               pca_dims=PCA_DIMS),
        expand('plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/tfidf/FINISH',
               pca_dims=PCA_DIMS),
        expand('plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/pmi/FINISH',
               pca_dims=PCA_DIMS),
        'plot/exact_ooc_pca_sparse_bincoo/pairs.png',
        'plot/exact_ooc_pca_sparse_bincoo/pairs_disease.png',
        'plot/exact_ooc_pca_sparse_bincoo/pairs_sex.png',
        'plot/exact_ooc_pca_sparse_bincoo/pairs_age.png'

rule plot_eigenvalues:
    input:
        'output/ooc_cov/eigenvalues.csv'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/eigenvalues.png',
        'plot/exact_ooc_pca_sparse_bincoo/eigenvalues_100.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_eigenvalues.txt'
    log:
        'logs/plot_eigenvalues.log'
    shell:
        'src/plot_eigenvalues.sh {input} {output} >& {log}'

rule plot_signature_score:
    input:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/signature_score.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/signature_score/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_signature_score_{pca_dims}.txt'
    log:
        'logs/plot_signature_score_{pca_dims}.log'
    shell:
        'src/plot_signature_score.sh {input} {output} >& {log}'

rule plot_frequency:
    input:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/frequency.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/frequency/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_frequency_{pca_dims}.txt'
    log:
        'logs/plot_frequency_{pca_dims}.log'
    shell:
        'src/plot_frequency.sh {input} {output} >& {log}'

rule plot_logitdiff:
    input:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/frequency.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/logitdiff/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_logitdiff_{pca_dims}.txt'
    log:
        'logs/plot_logitdiff_{pca_dims}.log'
    shell:
        'src/plot_logitdiff.sh {input} {output} >& {log}'

rule plot_tfidf:
    input:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/frequency.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/tfidf/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_tfidf_{pca_dims}.txt'
    log:
        'logs/plot_tfidf_{pca_dims}.log'
    shell:
        'src/plot_tfidf.sh {input} {output} >& {log}'

rule plot_pmi:
    input:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/frequency.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/pmi/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pmi_{pca_dims}.txt'
    log:
        'logs/plot_pmi_{pca_dims}.log'
    shell:
        'src/plot_pmi.sh {input} {output} >& {log}'

rule plot_pairs:
    input:
        'output/exact_ooc_pca_sparse_bincoo/10/Scores.csv'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/pairs.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pairs.txt'
    log:
        'logs/plot_pairs.log'
    shell:
        'src/plot_pairs.sh {input} {output} >& {log}'

rule plot_pairs_disease:
    input:
        'output/exact_ooc_pca_sparse_bincoo/10/Scores.csv',
        'data/disease_label.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/pairs_disease.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pairs_disease.txt'
    log:
        'logs/plot_pairs_disease.log'
    shell:
        'src/plot_pairs_w_label_categorical.sh {input} {output} >& {log}'

rule plot_pairs_sex:
    input:
        'output/exact_ooc_pca_sparse_bincoo/10/Scores.csv',
        'data/sex_label.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/pairs_sex.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pairs_sex.txt'
    log:
        'logs/plot_pairs_sex.log'
    shell:
        'src/plot_pairs_w_label_categorical.sh {input} {output} >& {log}'

rule plot_pairs_age:
    input:
        'output/exact_ooc_pca_sparse_bincoo/10/Scores.csv',
        'data/age_label.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/pairs_age.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pairs_age.txt'
    log:
        'logs/plot_pairs_age.log'
    shell:
        'src/plot_pairs_w_label_continuous.sh {input} {output} >& {log}'
