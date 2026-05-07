from snakemake.utils import min_version

#################################
# Setting
#################################
min_version("8.11.1")

CA_DIMS = [str(i) for i in range(6, 8)]

rule all:
    input:
        expand('output/bincoo_ca/{ca_dims}/frequency.csv',
            ca_dims=CA_DIMS)

rule frequency_ca:
    input:
        'data/coo.txt.zst',
        'output/bincoo_ca/{ca_dims}/Scores.mm',
        'plot/bincoo_ca/Landscaper/{ca_dims}/Allstates.tsv'
    output:
        'output/bincoo_ca/{ca_dims}/frequency.csv'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20251031'
    resources:
        mem_mb=1000000000
    benchmark:
        'benchmarks/frequency_ca_{ca_dims}.txt'
    log:
        'logs/frequency_ca_{ca_dims}.log'
    shell:
        'src/frequency.sh {input} {output} >& {log}'
