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
        expand('plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/tfidf/{lang}/FINISH',
               pca_dims=PCA_DIMS, lang=['ja', 'en']),
        expand('plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/pmi/FINISH',
               pca_dims=PCA_DIMS),
        'plot/exact_ooc_pca_sparse_bincoo/pairs.png',
        'plot/exact_ooc_pca_sparse_bincoo/pairs_disease.png',
        'plot/exact_ooc_pca_sparse_bincoo/pairs_sex.png',
        'plot/exact_ooc_pca_sparse_bincoo/pairs_age.png',
        'plot/exact_ooc_pca_sparse_bincoo/loading_pc1_pc2.png',
        'plot/exact_ooc_pca_sparse_bincoo/loading_pairs_pc1_pc7.png'

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
        freq    = 'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/frequency.csv',
        name_ja = 'data/col_id_disease_name_small.txt',
        name_en = 'data/col_id_disease_name_en_small.txt'
    output:
        ja = 'plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/tfidf/ja/FINISH',
        en = 'plot/exact_ooc_pca_sparse_bincoo/{pca_dims}/tfidf/en/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_tfidf_{pca_dims}.txt'
    log:
        'logs/plot_tfidf_{pca_dims}.log'
    shell:
        'src/plot_tfidf.sh {input.freq} {input.name_ja} {input.name_en} {output.ja} {output.en} >& {log}'

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
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pairs_age.txt'
    log:
        'logs/plot_pairs_age.log'
    shell:
        'src/plot_pairs_w_label_continuous.sh {input} {output} >& {log}'

rule plot_loading:
    input:
        eigen = 'output/exact_ooc_pca_sparse_bincoo/7/Eigen_vectors.csv',
        name  = 'data/col_id_disease_name_en_small.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/loading_pc1_pc2.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_loading.txt'
    log:
        'logs/plot_loading.log'
    shell:
        'src/plot_loading.sh {input.eigen} {input.name} {output} >& {log}'

rule plot_loading_pairs:
    input:
        eigen = 'output/exact_ooc_pca_sparse_bincoo/7/Eigen_vectors.csv',
        name  = 'data/col_id_disease_name_en_small.txt'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/loading_pairs_pc1_pc7.png'
    params:
        top_n_label = 8,
        q_thresh    = 0.05,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    benchmark:
        'benchmarks/plot_loading_pairs.txt'
    log:
        'logs/plot_loading_pairs.log'
    shell:
        'src/plot_loading_pairs.sh {input.eigen} {input.name} {output} '
        '{params.top_n_label} {params.q_thresh} >& {log}'
