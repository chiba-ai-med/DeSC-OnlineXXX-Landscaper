# Figure Index

論文用 Figure の構成と生成元。Main 12 枚 (Fig 2〜Fig 7) + Supplementary 16 枚 (FigS1〜FigS5)。

## Main Figures

| File | Source | 説明 |
|---|---|---|
| `main/Fig2_pairs_age.png` | `plot/exact_ooc_pca_sparse_bincoo/pairs_age.png` | PC1-10 ペアプロット (年齢ラベル付き)。対角に各 PC × age の Pearson r 注釈 (Keynote 上で手入力予定): PC1=+0.59, PC2=−0.02, PC3=+0.22, PC4=−0.17, PC5=−0.10, PC6=+0.04, PC7=−0.08 |
| `main/Fig3A_landscape_dim7.png` | `Landscaper/7/plot/Landscape.png` | エネルギーランドスケープ (dim 7、SubGraph で色分け) |
| `main/Fig3B_tagcloud_basin{1,2}_pattern{p}.png` | `7/tfidf/en/pattern_{p}.png` | TF-IDF タグクラウド (英語、上位 10 件、`(NA)` 除外)。Basin 1: pat 32 (rep, Freq=15.5M), 24, 64, 96, 28, 30 / Basin 2: pat 75 (rep, Freq=4.0M), 107, 73, 67 |
| `main/Fig4A_disease_diff_basin1.png` | `plot/analytic/7/transition_diff_basin1.png` | Sub-pattern → Basin 1 流入で変動する疾患 (w = L Δ ∈ R^D)、Basin 1 で 5 pair facet (24/64/96/28/30 → 32)、top 10 |
| `main/Fig4B_disease_diff_basin2.png` | `plot/analytic/7/transition_diff_basin2.png` | 同上、Basin 2 で 3 pair (107/73/67 → 75) |
| `main/Fig5A_km_basin.png` | `plot/cox/km_basin.png` | Kaplan-Meier survival by baseline Basin (Cox Model 3)。**Basin 2 vs Basin 1 HR = 0.66 (0.65-0.67), p≪0.001** (age, sex 調整) |
| `main/Fig5B_km_energy.png` | `plot/cox/km_energy.png` | Kaplan-Meier by baseline energy E tertile (Cox Model 4)。**HR 1.066 per +1 SD of E, p≪0.001**。ELA energy を clinical risk metric として |
| `main/Fig5C_forest_pc.png` | `plot/cox/forest_pc.png` | Per-PC HR forest plot (Model 1 univariate + Model 2 multivariate)。PC2/5/6 が +方向 risk、PC1/3/4/7 が protective |
| `main/Fig6_km_hospitalization.png` | `output/cox_hosp/km_hospitalization_basin.png` | Cumulative incidence of hospitalization by baseline Basin。**Basin 2 vs Basin 1 HR = 1.10 (1.10-1.11)** — 死亡 HR (0.66) と逆向き。Basin 2 = treated chronic disease phenotype |
| `main/Fig7A_atc_or.png` | `output/atc_or/atc_or_basin2vs1.png` | Prescription OR (Basin 2 vs Basin 1, age/sex 調整)。全 6 ATC group で OR > 1: Antihistamine 2.32, Statin 2.22, Steroid 1.68, Diabetes 1.57, Osteoporosis 1.38, NSAIDs 1.31 |
| `main/Fig7B_lipid_violin.png` | `output/h1/lipid_violin.png` | 健診 biomarker (BMI, TG, HDL, LDL, GOT, GPT, GGT, FBS, HbA1c, SBP, DBP, eGFR) の violin × 3 群 (pat 32, pat 96, Basin 2 全体)。Basin 2 = TG/HbA1c/SBP 高、eGFR 低 = メタボ+CKD 表現型 |

## Supplementary Figures

### Fig. S1 — PCA 詳細

| File | Source | 説明 |
|---|---|---|
| `FigS1A_eigenvalues.png` | `eigenvalues.png` | 全固有値の累積寄与率 |
| `FigS1B_eigenvalues_100.png` | `eigenvalues_100.png` | 上位 100 固有値 |
| `FigS1C_loading_pairs.png` | `loading_pairs_pc1_pc7.png` | ICD-10 側 Loading の 7×7 下三角ペアプロット。各セルで軸内 z-score (BH q<0.05) 有意 ICD-10 を赤、上位 8 件にコードラベル |
| `FigS1D_pairs.png` | `pairs.png` | PCA score ペアプロット (無ラベル) |
| `FigS1E_pairs_disease.png` | `pairs_disease.png` | 同 (疾患カテゴリ色分け) |
| `FigS1F_pairs_sex.png` | `pairs_sex.png` | 同 (性別色分け) |

### Fig. S2 — Analytical transition probabilities (旧 Fig 4)

ELA model h, J から解析計算した Metropolis-Hastings P[i,j] heatmap (`P_est.tsv` の long-time limit と整合)。`sort_by='to_basin_rep'`、共通 zlim=0.45、`*` で basin 代表マーク。

| File | Source | 説明 |
|---|---|---|
| `FigS2A_transition_matrix_basin1.png` | `plot/analytic/7/transition_matrix_basin1.png` | Basin 1 内 π_eq 上位 12 パターン (To pat 32 への流入順) |
| `FigS2B_transition_matrix_basin2.png` | `plot/analytic/7/transition_matrix_basin2.png` | Basin 2 内 π_eq 上位 12 (To pat 75 への流入順) |
| `FigS2C_transition_matrix_basin1_full.png` | `…_basin1_full.png` | Basin 1 全 98 パターン |
| `FigS2D_transition_matrix_basin2_full.png` | `…_basin2_full.png` | Basin 2 全 27 パターン |

### Fig. S3 — H3: PC sign × age decomposition

| File | Source | 説明 |
|---|---|---|
| `FigS3_age_pc_sign.png` | `plot/h3/age_pc_sign.png` | 5 歳年齢層別に各 PC の +1 比率。**Basin を分ける PC1/3/5/7 が強い age 依存性、共通の PC2/4/6 が比較的 flat** |

### Fig. S4 — H4: ELA robustness

| File | Source | 説明 |
|---|---|---|
| `FigS4A_dim_sensitivity.png` | `plot/h4/dim_sensitivity.png` | PCA dim 2-7 での ELA basin 数。**dim ≤ 5 で 1 basin、dim ≥ 6 で 2 basin が出現・安定** |
| `FigS4B_bootstrap_ari.png` | `plot/h4/bootstrap_ari.png` | 50 回 bootstrap × 30k subsample で k-means(k=2) と ELA basin の ARI/NMI 分布。**ARI 0.161 ± 0.005** (IQR 0.159-0.163) — ELA basin は k-means cluster と独立な構造 |

### Fig. S5 — H2: Basin demographics

| File | Source | 説明 |
|---|---|---|
| `FigS5A_basin_sex.png` | `output/h2/basin_sex.png` | Basin 別性別比率 (Basin 1: 55% F、Basin 2: 56% F — ほぼ同等) |
| `FigS5B_basin_age_density.png` | `output/h2/basin_age_density.png` | Basin 別年齢分布 (Basin 1 中央値 63.9、Basin 2 中央値 71.5、+7.6 歳) |
| `FigS5C_basin_top_subpatterns.png` | `output/h2/basin_top_subpatterns.png` | Basin 内 top 10 sub-pattern 頻度。Basin 2 で pat 72 が 25% で最大 (代表 pat 75 は 3 位 9.9%) |

---

## 主要な数値結果 (論文文中で引用)

### Cohort
- 全 person: 9,765,864 (tekiyo.csv 11.3M のうち COO データに行のある人)
- Baseline Basin 1: 8.33M (86%)、Basin 2: 1.36M (14%)、unassigned: 68k (0.7%)
- 死亡イベント: 307,995 (3.15%)
- 入院イベント (観察期間中 1 回以上): ~30% (Basin 1) / ~35% (Basin 2)

### Cox 死亡 (Section 5)
| Model | Variable | HR | 95% CI | p |
|---|---|---|---|---|
| 3 | basin: Basin 2 vs Basin 1 | **0.66** | 0.65-0.67 | <1e-300 |
| 4 | energy E (per +1 SD) | **1.07** | 1.06-1.07 | 5e-194 |

### Cox 入院 (Section 6)
| Model | Variable | HR | 95% CI | p |
|---|---|---|---|---|
| H1 | basin: Basin 2 vs Basin 1 | **1.10** | 1.10-1.11 | <1e-300 |
| H2 | energy E (per +1 SD) | **1.12** | 1.11-1.12 | <1e-300 |

### ATC prescription OR (Basin 2 vs Basin 1, age/sex 調整) — Section 6
| ATC | OR | 95% CI |
|---|---|---|
| Antihistamine (R06) | 2.32 | 2.32-2.33 |
| Statin (C10) | 2.22 | 2.21-2.23 |
| Steroid (H02) | 1.68 | 1.67-1.68 |
| Diabetes (A10) | 1.57 | 1.56-1.58 |
| Osteoporosis (M05) | 1.38 | 1.38-1.39 |
| NSAIDs (M01) | 1.31 | 1.30-1.31 |

### 健診 biomarker (Section 6) — n × 100k 程度
| | pat 32 | pat 96 | Basin 2 |
|---|---|---|---|
| BMI | 22.1 | 22.4 | 23.2 |
| TG (mg/dL) | 88 | 92 | 100 |
| HDL | 63 | 63 | 60 |
| LDL | 122 | 125 | 115 |
| HbA1c (%) | 5.5 | 5.5 | 5.7 |
| SBP | 120 | 123 | 128 |
| eGFR | 74.3 | 72.0 | 65.4 |

---

## 生成手順

```bash
# 0. 英語マスタの生成
snakemake -s workflow/english_label.smk --use-singularity --cores 2

# 1. PCA / Landscaper / frequency / TF-IDF / pairs / loading
snakemake -s workflow/plot.smk --use-singularity --cores 4

# 2. Fig 4 (旧 5) 用 disease decomposition
snakemake -s workflow/transition_diff.smk --use-singularity --cores 4

# 3. Fig S2 用 解析的 P 行列
snakemake -s workflow/transition_matrix.smk --use-singularity --cores 2

# 4. Phase 1: person-level table 構築
snakemake -s workflow/person_table.smk --use-singularity --cores 2

# 5. Phase 2: H3 + Cox 死亡 (Fig 5A/B/C, Fig S3)
snakemake -s workflow/h3_outcome.smk --use-singularity --cores 4

# 6. Fig 6 用 Cox 入院 + Fig 7 用 ATC OR + Fig 7B 用 lipid + Fig S4/S5 は個別スクリプト

# 7. Figure ディレクトリにコピー
snakemake -s workflow/figures.smk --cores 4
```

## 章立て (論文)

- **Section 1** Cohort + data overview (Table 1 想定、Figure なし)
- **Section 2** PCA reveals an age-dominated PC1 (Fig 2 + Fig S1)
- **Section 3** ELA reveals two major basins (Fig 3A, 3B)
- **Section 4** Disease decomposition of basin transitions (Fig 4A/B)
- **Section 5** Mortality risk stratification by basin and Energy E (Fig 5A/B/C)
- **Section 6** Hospitalization patterns and treatment engagement (Fig 6 + Fig 7A/B)
- **Discussion** "Basin 2 = treated metabolic phenotype" の解釈、ELA energy の臨床応用、ELA basin の独自性 (Fig S4) + PC × age limitation (Fig S3, S1C)
