from snakemake.utils import min_version

#################################
# Setting
#################################
min_version("8.11.1")

PCA_DIMS = ['7']

# Random walk パラメータ
RW_TEMP     = 1.0          # 温度（Landscaper は T=1 想定で h,J をフィット）
RW_NSTEPS   = 1_000_000    # 本サンプリング step 数
RW_BURNIN   = 100_000
RW_INIT_PID = 32           # Basin 1 底（dim 7）
RW_SEED     = 1234

LSCAPER = 'plot/exact_ooc_pca_sparse_bincoo/Landscaper'
RW_OUT  = 'output/random_walk'
RW_PLT  = 'plot/random_walk'

rule all:
    input:
        expand(f'{RW_OUT}/{{d}}/trajectory.tsv',  d=PCA_DIMS),
        expand(f'{RW_OUT}/{{d}}/visit_count.tsv', d=PCA_DIMS),
        expand(f'{RW_OUT}/{{d}}/transition.tsv',  d=PCA_DIMS),
        expand(f'{RW_PLT}/{{d}}/trajectory.png',           d=PCA_DIMS),
        expand(f'{RW_PLT}/{{d}}/subpattern_transition.png', d=PCA_DIMS),

rule random_walk_ela:
    input:
        h         = f'{LSCAPER}/{{d}}/h.tsv',
        J         = f'{LSCAPER}/{{d}}/J.tsv',
        allstates = f'{LSCAPER}/{{d}}/Allstates.tsv',
    output:
        traj  = f'{RW_OUT}/{{d}}/trajectory.tsv',
        visit = f'{RW_OUT}/{{d}}/visit_count.tsv',
        trans = f'{RW_OUT}/{{d}}/transition.tsv',
    params:
        T        = RW_TEMP,
        n_steps  = RW_NSTEPS,
        burn_in  = RW_BURNIN,
        init_pid = RW_INIT_PID,
        seed     = RW_SEED,
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=4000
    benchmark:
        'benchmarks/random_walk_ela_{d}.txt'
    log:
        'logs/random_walk_ela_{d}.log'
    shell:
        'src/random_walk_ela.sh {input.h} {input.J} {input.allstates} '
        '{output.traj} {output.visit} {output.trans} '
        '{params.T} {params.n_steps} {params.init_pid} {params.burn_in} {params.seed} '
        '>& {log}'

rule plot_walk_trajectory:
    input:
        traj     = f'{RW_OUT}/{{d}}/trajectory.tsv',
        subgraph = f'{LSCAPER}/{{d}}/SubGraph.tsv',
        E        = f'{LSCAPER}/{{d}}/E.tsv',
    output:
        f'{RW_PLT}/{{d}}/trajectory.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    benchmark:
        'benchmarks/plot_walk_trajectory_{d}.txt'
    log:
        'logs/plot_walk_trajectory_{d}.log'
    shell:
        'src/plot_walk_trajectory.sh {input.traj} {input.subgraph} {input.E} {output} >& {log}'

rule plot_subpattern_transition:
    input:
        trans    = f'{RW_OUT}/{{d}}/transition.tsv',
        visit    = f'{RW_OUT}/{{d}}/visit_count.tsv',
        subgraph = f'{LSCAPER}/{{d}}/SubGraph.tsv',
    output:
        f'{RW_PLT}/{{d}}/subpattern_transition.png'
    container:
        'docker://koki/desc_onlinexxx_landscaper:20260602'
    resources:
        mem_mb=2000
    benchmark:
        'benchmarks/plot_subpattern_transition_{d}.txt'
    log:
        'logs/plot_subpattern_transition_{d}.log'
    shell:
        'src/plot_subpattern_transition.sh {input.trans} {input.visit} {input.subgraph} {output} >& {log}'
