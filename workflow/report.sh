# HTML
mkdir -p report
snakemake -s workflow/preprocess.smk --report report/preprocess.html
snakemake -s workflow/onlinexxx.smk --report report/onlinexxx.html
snakemake -s workflow/landscaper.smk --report report/landscaper.html
snakemake -s workflow/signature.smk --report report/signature.html
snakemake -s workflow/frequency.smk --report report/frequency.html
snakemake -s workflow/plot.smk --report report/plot.html
