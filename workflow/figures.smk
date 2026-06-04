from snakemake.utils import min_version

min_version("8.11.1")

# 論文用 Figure ファイルを plot/Figures/ に集約する。
#
# Main figures (final):
#   Fig 2  : PCA pairs × age (pairs_age.png)
#   Fig 3A : Energy landscape
#   Fig 3B : TF-IDF tagclouds × 10
#   Fig 4A/B : Disease decomposition (w = L Δ) for Basin 1 / 2
#   Fig 5A/B/C : Survival Cox (KM basin, KM energy, forest PC)
#   Fig 6  : Hospitalization cumulative incidence
#   Fig 7A/B : Treatment engagement (ATC OR + lipid biomarker)
#
# Supplementary figures:
#   FigS1 A-G : PCA details (eigenvalues, loading pairs, score pairs)
#   FigS2 A-B : Transition matrix heatmap (full basin)
#   FigS3     : H3 PC sign × age (age axis decomposition)
#   FigS4 A/B : H4 robustness (dim sensitivity + bootstrap ARI)
#   FigS5 A/B/C : H2 basin demographics (sex / age / sub-pattern)

PCA_BASE = 'plot/exact_ooc_pca_sparse_bincoo'

BASIN1_TAGCLOUD_PATTERNS = ['32', '24', '64', '96', '28', '30']
BASIN2_TAGCLOUD_PATTERNS = ['75', '107', '73', '67']

rule all:
    input:
        # Main
        'plot/Figures/main/Fig2_pairs_age.png',
        'plot/Figures/main/Fig3A_landscape_dim7.png',
        expand('plot/Figures/main/Fig3B_tagcloud_basin1_pattern{p}.png',
               p=BASIN1_TAGCLOUD_PATTERNS),
        expand('plot/Figures/main/Fig3B_tagcloud_basin2_pattern{p}.png',
               p=BASIN2_TAGCLOUD_PATTERNS),
        'plot/Figures/main/Fig4A_disease_diff_basin1.png',
        'plot/Figures/main/Fig4B_disease_diff_basin2.png',
        'plot/Figures/main/Fig5A_km_basin.png',
        'plot/Figures/main/Fig5B_km_energy.png',
        'plot/Figures/main/Fig5C_forest_pc.png',
        'plot/Figures/main/Fig6_km_hospitalization.png',
        'plot/Figures/main/Fig7A_atc_or.png',
        'plot/Figures/main/Fig7B_lipid_violin.png',
        # Supplementary
        'plot/Figures/supplementary/FigS1A_eigenvalues.png',
        'plot/Figures/supplementary/FigS1B_eigenvalues_100.png',
        'plot/Figures/supplementary/FigS1C_loading_pairs.png',
        'plot/Figures/supplementary/FigS1D_pairs.png',
        'plot/Figures/supplementary/FigS1E_pairs_disease.png',
        'plot/Figures/supplementary/FigS1F_pairs_sex.png',
        'plot/Figures/supplementary/FigS2A_transition_matrix_basin1.png',
        'plot/Figures/supplementary/FigS2B_transition_matrix_basin2.png',
        'plot/Figures/supplementary/FigS2C_transition_matrix_basin1_full.png',
        'plot/Figures/supplementary/FigS2D_transition_matrix_basin2_full.png',
        'plot/Figures/supplementary/FigS3_age_pc_sign.png',
        'plot/Figures/supplementary/FigS4A_dim_sensitivity.png',
        'plot/Figures/supplementary/FigS4B_bootstrap_ari.png',
        'plot/Figures/supplementary/FigS5A_basin_sex.png',
        'plot/Figures/supplementary/FigS5B_basin_age_density.png',
        'plot/Figures/supplementary/FigS5C_basin_top_subpatterns.png',

# ---------- Main ----------

rule copy_fig2_pairs_age:
    input:  f'{PCA_BASE}/pairs_age.png'
    output: 'plot/Figures/main/Fig2_pairs_age.png'
    shell:  'cp {input} {output}'

rule copy_fig3a_landscape:
    input:  f'{PCA_BASE}/Landscaper/7/plot/Landscape.png'
    output: 'plot/Figures/main/Fig3A_landscape_dim7.png'
    shell:  'cp {input} {output}'

rule copy_fig3b_tagcloud_basin1:
    input:  PCA_BASE + '/7/tfidf/en/pattern_{p}.png'
    output: 'plot/Figures/main/Fig3B_tagcloud_basin1_pattern{p}.png'
    wildcard_constraints:
        p = '|'.join(BASIN1_TAGCLOUD_PATTERNS)
    shell:  'cp {input} {output}'

rule copy_fig3b_tagcloud_basin2:
    input:  PCA_BASE + '/7/tfidf/en/pattern_{p}.png'
    output: 'plot/Figures/main/Fig3B_tagcloud_basin2_pattern{p}.png'
    wildcard_constraints:
        p = '|'.join(BASIN2_TAGCLOUD_PATTERNS)
    shell:  'cp {input} {output}'

# Fig 4: Disease decomposition (旧 Fig 5)
rule copy_fig4a_disease_diff_basin1:
    input:  'plot/analytic/7/transition_diff_basin1.png'
    output: 'plot/Figures/main/Fig4A_disease_diff_basin1.png'
    shell:  'cp {input} {output}'

rule copy_fig4b_disease_diff_basin2:
    input:  'plot/analytic/7/transition_diff_basin2.png'
    output: 'plot/Figures/main/Fig4B_disease_diff_basin2.png'
    shell:  'cp {input} {output}'

# Fig 5: Survival Cox (death outcome)
rule copy_fig5a_km_basin:
    input:  'plot/cox/km_basin.png'
    output: 'plot/Figures/main/Fig5A_km_basin.png'
    shell:  'cp {input} {output}'

rule copy_fig5b_km_energy:
    input:  'plot/cox/km_energy.png'
    output: 'plot/Figures/main/Fig5B_km_energy.png'
    shell:  'cp {input} {output}'

rule copy_fig5c_forest_pc:
    input:  'plot/cox/forest_pc.png'
    output: 'plot/Figures/main/Fig5C_forest_pc.png'
    shell:  'cp {input} {output}'

# Fig 6: Hospitalization (Cox B)
rule copy_fig6_km_hospitalization:
    input:  'output/cox_hosp/km_hospitalization_basin.png'
    output: 'plot/Figures/main/Fig6_km_hospitalization.png'
    shell:  'cp {input} {output}'

# Fig 7: Treatment engagement (ATC OR + lipid biomarker)
rule copy_fig7a_atc_or:
    input:  'output/atc_or/atc_or_basin2vs1.png'
    output: 'plot/Figures/main/Fig7A_atc_or.png'
    shell:  'cp {input} {output}'

rule copy_fig7b_lipid_violin:
    input:  'output/h1/lipid_violin.png'
    output: 'plot/Figures/main/Fig7B_lipid_violin.png'
    shell:  'cp {input} {output}'

# ---------- Supplementary ----------

rule copy_figs1a_eigenvalues:
    input:  f'{PCA_BASE}/eigenvalues.png'
    output: 'plot/Figures/supplementary/FigS1A_eigenvalues.png'
    shell:  'cp {input} {output}'

rule copy_figs1b_eigenvalues_100:
    input:  f'{PCA_BASE}/eigenvalues_100.png'
    output: 'plot/Figures/supplementary/FigS1B_eigenvalues_100.png'
    shell:  'cp {input} {output}'

rule copy_figs1c_loading:
    input:  f'{PCA_BASE}/loading_pairs_pc1_pc7.png'
    output: 'plot/Figures/supplementary/FigS1C_loading_pairs.png'
    shell:  'cp {input} {output}'

rule copy_figs1d_pairs:
    input:  f'{PCA_BASE}/pairs.png'
    output: 'plot/Figures/supplementary/FigS1D_pairs.png'
    shell:  'cp {input} {output}'

rule copy_figs1e_pairs_disease:
    input:  f'{PCA_BASE}/pairs_disease.png'
    output: 'plot/Figures/supplementary/FigS1E_pairs_disease.png'
    shell:  'cp {input} {output}'

rule copy_figs1f_pairs_sex:
    input:  f'{PCA_BASE}/pairs_sex.png'
    output: 'plot/Figures/supplementary/FigS1F_pairs_sex.png'
    shell:  'cp {input} {output}'

# FigS2: Transition matrix heatmap (旧 Fig 4)
rule copy_figs2a_transition_basin1:
    input:  'plot/analytic/7/transition_matrix_basin1.png'
    output: 'plot/Figures/supplementary/FigS2A_transition_matrix_basin1.png'
    shell:  'cp {input} {output}'

rule copy_figs2b_transition_basin2:
    input:  'plot/analytic/7/transition_matrix_basin2.png'
    output: 'plot/Figures/supplementary/FigS2B_transition_matrix_basin2.png'
    shell:  'cp {input} {output}'

rule copy_figs2c_transition_basin1_full:
    input:  'plot/analytic/7/transition_matrix_basin1_full.png'
    output: 'plot/Figures/supplementary/FigS2C_transition_matrix_basin1_full.png'
    shell:  'cp {input} {output}'

rule copy_figs2d_transition_basin2_full:
    input:  'plot/analytic/7/transition_matrix_basin2_full.png'
    output: 'plot/Figures/supplementary/FigS2D_transition_matrix_basin2_full.png'
    shell:  'cp {input} {output}'

# FigS3: H3 PC sign × age (age axis decomposition)
rule copy_figs3_age_pc_sign:
    input:  'plot/h3/age_pc_sign.png'
    output: 'plot/Figures/supplementary/FigS3_age_pc_sign.png'
    shell:  'cp {input} {output}'

# FigS4: H4 robustness
rule copy_figs4a_dim_sensitivity:
    input:  'plot/h4/dim_sensitivity.png'
    output: 'plot/Figures/supplementary/FigS4A_dim_sensitivity.png'
    shell:  'cp {input} {output}'

rule copy_figs4b_bootstrap_ari:
    input:  'plot/h4/bootstrap_ari.png'
    output: 'plot/Figures/supplementary/FigS4B_bootstrap_ari.png'
    shell:  'cp {input} {output}'

# FigS5: H2 basin demographics
rule copy_figs5a_basin_sex:
    input:  'output/h2/basin_sex.png'
    output: 'plot/Figures/supplementary/FigS5A_basin_sex.png'
    shell:  'cp {input} {output}'

rule copy_figs5b_basin_age_density:
    input:  'output/h2/basin_age_density.png'
    output: 'plot/Figures/supplementary/FigS5B_basin_age_density.png'
    shell:  'cp {input} {output}'

rule copy_figs5c_basin_top_subpatterns:
    input:  'output/h2/basin_top_subpatterns.png'
    output: 'plot/Figures/supplementary/FigS5C_basin_top_subpatterns.png'
    shell:  'cp {input} {output}'
