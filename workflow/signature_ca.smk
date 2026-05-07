from snakemake.utils import min_version

#################################
# Setting
#################################
min_version("8.11.1")

CA_DIMS = [str(i) for i in range(6, 8)]

rule all:
    input:
        expand('output/bincoo_ca/{ca_dims}/signature_score.csv',
            ca_dims=CA_DIMS)

rule signature_score_ca:
    input:
        'output/bincoo_ca/{ca_dims}/Col_coordinates.csv',
        'plot/bincoo_ca/Landscaper/{ca_dims}/Allstates.tsv'
    output:
        'output/bincoo_ca/{ca_dims}/signature_score.csv'
    container:
        'docker://ghcr.io/rikenbit/onlinepcajl:98ebff1'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/signature_score_ca_{ca_dims}.txt'
    log:
        'logs/signature_score_ca_{ca_dims}.log'
    shell:
        'src/signature_score.sh {input} {output} >& {log}'
