from snakemake.utils import min_version

#################################
# Setting
#################################
min_version("8.11.1")

CA_DIMS = [str(i) for i in range(6, 8)]

rule all:
    input:
        'plot/bincoo_ca/inertia.png',
        expand('plot/bincoo_ca/{ca_dims}/signature_score/FINISH',
               ca_dims=CA_DIMS),
        expand('plot/bincoo_ca/{ca_dims}/frequency/FINISH',
               ca_dims=CA_DIMS),
        expand('plot/bincoo_ca/{ca_dims}/logitdiff/FINISH',
               ca_dims=CA_DIMS),
        expand('plot/bincoo_ca/{ca_dims}/tfidf/FINISH',
               ca_dims=CA_DIMS),
        expand('plot/bincoo_ca/{ca_dims}/pmi/FINISH',
               ca_dims=CA_DIMS),
        'plot/bincoo_ca/pairs.png',
        'plot/bincoo_ca/pairs_disease.png',
        'plot/bincoo_ca/pairs_sex.png',
        'plot/bincoo_ca/pairs_age.png'

rule plot_inertia:
    input:
        'output/bincoo_ca/7/Inertia.csv',
        'output/bincoo_ca/7/Total_inertia.csv'
    output:
        'plot/bincoo_ca/inertia.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_inertia.txt'
    log:
        'logs/plot_inertia.log'
    shell:
        'src/plot_inertia.sh {input} {output} >& {log}'

rule plot_signature_score_ca:
    input:
        'output/bincoo_ca/{ca_dims}/signature_score.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/bincoo_ca/{ca_dims}/signature_score/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_signature_score_ca_{ca_dims}.txt'
    log:
        'logs/plot_signature_score_ca_{ca_dims}.log'
    shell:
        'src/plot_signature_score.sh {input} {output} >& {log}'

rule plot_frequency_ca:
    input:
        'output/bincoo_ca/{ca_dims}/frequency.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/bincoo_ca/{ca_dims}/frequency/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_frequency_ca_{ca_dims}.txt'
    log:
        'logs/plot_frequency_ca_{ca_dims}.log'
    shell:
        'src/plot_frequency.sh {input} {output} >& {log}'

rule plot_logitdiff_ca:
    input:
        'output/bincoo_ca/{ca_dims}/frequency.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/bincoo_ca/{ca_dims}/logitdiff/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_logitdiff_ca_{ca_dims}.txt'
    log:
        'logs/plot_logitdiff_ca_{ca_dims}.log'
    shell:
        'src/plot_logitdiff.sh {input} {output} >& {log}'

rule plot_tfidf_ca:
    input:
        'output/bincoo_ca/{ca_dims}/frequency.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/bincoo_ca/{ca_dims}/tfidf/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_tfidf_ca_{ca_dims}.txt'
    log:
        'logs/plot_tfidf_ca_{ca_dims}.log'
    shell:
        'src/plot_tfidf.sh {input} {output} >& {log}'

rule plot_pmi_ca:
    input:
        'output/bincoo_ca/{ca_dims}/frequency.csv',
        'data/col_id_disease_name_small.txt'
    output:
        'plot/bincoo_ca/{ca_dims}/pmi/FINISH'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20250812'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pmi_ca_{ca_dims}.txt'
    log:
        'logs/plot_pmi_ca_{ca_dims}.log'
    shell:
        'src/plot_pmi.sh {input} {output} >& {log}'

rule plot_pairs_ca:
    input:
        'output/bincoo_ca/7/Row_coordinates.csv'
    output:
        'plot/bincoo_ca/pairs.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20251031'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pairs_ca.txt'
    log:
        'logs/plot_pairs_ca.log'
    shell:
        'src/plot_pairs.sh {input} {output} >& {log}'

rule plot_pairs_disease_ca:
    input:
        'output/bincoo_ca/7/Row_coordinates.csv',
        'data/disease_label.txt'
    output:
        'plot/bincoo_ca/pairs_disease.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20251031'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pairs_disease_ca.txt'
    log:
        'logs/plot_pairs_disease_ca.log'
    shell:
        'src/plot_pairs_w_label_categorical.sh {input} {output} >& {log}'

rule plot_pairs_sex_ca:
    input:
        'output/bincoo_ca/7/Row_coordinates.csv',
        'data/sex_label.txt'
    output:
        'plot/bincoo_ca/pairs_sex.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20251031'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pairs_sex_ca.txt'
    log:
        'logs/plot_pairs_sex_ca.log'
    shell:
        'src/plot_pairs_w_label_categorical.sh {input} {output} >& {log}'

rule plot_pairs_age_ca:
    input:
        'output/bincoo_ca/7/Row_coordinates.csv',
        'data/age_label.txt'
    output:
        'plot/bincoo_ca/pairs_age.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20251031'
    resources:
        mem_mb=1000
    benchmark:
        'benchmarks/plot_pairs_age_ca.txt'
    log:
        'logs/plot_pairs_age_ca.log'
    shell:
        'src/plot_pairs_w_label_continuous.sh {input} {output} >& {log}'
