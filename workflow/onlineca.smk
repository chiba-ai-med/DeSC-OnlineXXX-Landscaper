from snakemake.utils import min_version

#################################
# Setting
#################################
# Minimum Version of Snakemake
min_version("8.11.1")

CA_DIMS = [str(i) for i in range(2, 8)]

rule all:
    input:
        expand('output/bincoo_ca/{ca_dims}/Row_coordinates.csv',
            ca_dims=CA_DIMS),
        expand('output/bincoo_ca/{ca_dims}/Scores.mm',
            ca_dims=CA_DIMS)

rule onlineca_bincoo_ca:
    input:
        'data/coo.txt.zst'
    output:
        'output/bincoo_ca/{ca_dims}/Row_coordinates.csv',
        'output/bincoo_ca/{ca_dims}/Scores.mm'
    container:
        'docker://ghcr.io/chiba-ai-med/onlinecajl:5074df1'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/onlineca_bincoo_ca_{ca_dims}.txt'
    log:
        'logs/onlineca_bincoo_ca_{ca_dims}.log'
    shell:
        'src/onlineca_bincoo_ca.sh {input} {output} {wildcards.ca_dims} >& {log}'
