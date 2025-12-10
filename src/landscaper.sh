#!/bin/bash
#$ -l nc=4
#$ -p -50
#$ -r yes
#$ -q node.q

#SBATCH -n 4
#SBATCH --nice=50
#SBATCH --requeue
#SBATCH -p node03-06
SLURM_RESTART_COUNT=2

outdir=`echo $2 | sed -e 's|/plot/ratio_group.png||'`

tmpdir=$(mktemp -d "./landscaper_tmp.XXXXXX")
mkdir -p "$tmpdir"
cd "$tmpdir"
cp /landscaper .
cp /Snakefile .
cp -rf /src .

# ./landscaper -i ../$1 -o ../$outdir --input_sparse=TRUE -g ../$2 --cores=1 --memgb=100
./landscaper -i ../"$1" -o ../"$outdir" --input_sparse=TRUE --cores=1 --memgb=100

rm -rf "$tmpdir"