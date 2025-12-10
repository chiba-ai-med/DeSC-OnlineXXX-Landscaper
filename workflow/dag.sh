# DAG graph
mkdir -p plot
snakemake -s workflow/preprocess.smk --rulegraph | dot -Tpng > plot/preprocess.png
snakemake -s workflow/onlinexxx.smk --rulegraph | dot -Tpng > plot/onlinexxx.png
snakemake -s workflow/landscaper.smk --rulegraph | dot -Tpng > plot/landscaper.png
snakemake -s workflow/signature.smk --rulegraph | dot -Tpng > plot/signature.png
snakemake -s workflow/frequency.smk --rulegraph | dot -Tpng > plot/frequency.png
snakemake -s workflow/plot.smk --rulegraph | dot -Tpng > plot/plot.png
