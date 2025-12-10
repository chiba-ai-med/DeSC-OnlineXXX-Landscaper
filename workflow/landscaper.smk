import pandas as pd
from snakemake.utils import min_version

#################################
# Setting
#################################
min_version("8.11.1")

PCA_DIMS = [str(i) for i in range(2, 8)]
PLOTFILES = ['ratio_group.png', 'Allstates.png', 'Freq_Prob_Energy.png', 'h.png', 'J.png', 'Basin.png', 'StatusNetwork_Subgraph.png', 'StatusNetwork_Subgraph_legend.png', 'StatusNetwork_Energy.png', 'StatusNetwork_Energy_legend.png', 'StatusNetwork_Ratio.png', 'StatusNetwork_Ratio_legend.png', 'StatusNetwork_State.png', 'StatusNetwork_State_legend.png', 'Landscape.png', 'discon_graph_1.png', 'discon_graph_2.png']

rule all:
    input:
        expand('plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/{plotfile}', pca_dims=PCA_DIMS, plotfile=PLOTFILES),
        expand('plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/Coordinate.tsv', pca_dims=PCA_DIMS)

rule landscaper:
    input:
        'output/exact_ooc_pca_sparse_bincoo/{pca_dims}/Scores.mm'
    output:
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/ratio_group.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/Allstates.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/Freq_Prob_Energy.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/h.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/J.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/Basin.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/StatusNetwork_Subgraph.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/StatusNetwork_Subgraph_legend.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/StatusNetwork_Energy.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/StatusNetwork_Energy_legend.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/StatusNetwork_Ratio.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/StatusNetwork_Ratio_legend.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/StatusNetwork_State.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/StatusNetwork_State_legend.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/Landscape.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/discon_graph_1.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/plot/discon_graph_2.png',
        'plot/exact_ooc_pca_sparse_bincoo/Landscaper/{pca_dims}/Coordinate.tsv'
    container:
        'docker://ghcr.io/chiba-ai-med/landscaper:main'
    resources:
        mem_mb=1000000
    benchmark:
        'benchmarks/landscaper_{pca_dims}.txt'
    log:
        'logs/landscaper_{pca_dims}.log'
    shell:
        'src/landscaper.sh {input} {output} >& {log}'
