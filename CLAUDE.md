# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

大規模疎行列バイナリデータ（COO形式、7,581行 × 347,764,079非ゼロ要素）に対して、OnlinePCA.jl / OnlineCA.jl による次元削減を行い、Landscaperによるエネルギーランドスケープ解析と疾患パターン可視化を行うバイオインフォマティクスパイプライン。

## ワークフロー実行

Snakemake（v8.11.1以上）で管理。各ワークフローは独立した`.smk`ファイル。実行順序に依存があるため下記の順で回す。

### PCA系統（`output/exact_ooc_pca_sparse_bincoo/`）

```bash
# 前処理（COOバイナリ化、disease/sex/age ラベル抽出）
snakemake -s workflow/preprocess.smk --cores <n>

# 英語病名マスタ生成（WHO ICD-10 2011 + ICD-10-CM 2022、tagcloud / Loading 散布図で使用）
snakemake -s workflow/english_label.smk --use-singularity --cores 2

# OnlinePCA（Out-of-core 共分散 → 固有値分解 → PCAスコア）
snakemake -s workflow/onlinexxx.smk --cores <n>

# Landscaper（エネルギーランドスケープ；Allstates.tsv + Basin.tsv 等を生成）
snakemake -s workflow/landscaper.smk --cores <n>

# 以下は landscaper の Allstates.tsv に依存
snakemake -s workflow/signature.smk --cores <n>   # 順列検定スコア
snakemake -s workflow/frequency.smk --cores <n>   # パターン×疾患頻度

# プロット（eigenvalues / signature / frequency / TF-IDF(ja+en) / PMI / LogitDiff / pairs / loading）
snakemake -s workflow/plot.smk --use-singularity --cores <n>

# ELA model から解析的に 1-step 遷移確率行列 P[i,j] を計算し、Basin 別 heatmap を生成（Fig 4 用）
snakemake -s workflow/transition_matrix.smk --use-singularity --cores 2

# 各遷移 (Basin 代表 ↔ Sub-pattern) で変動する疾患を w = L Δ から推定（Fig 5 用）
snakemake -s workflow/transition_diff.smk --use-singularity --cores 4

# 論文用 Figure を plot/Figures/{main,supplementary}/ に配置
snakemake -s workflow/figures.smk --cores <n>
```

### CA系統（`output/bincoo_ca/`、`*_ca.smk`）

PCA系統と並列に存在する Correspondence Analysis 版。`onlineca.smk` 以降は同形の `landscaper_ca → signature_ca / frequency_ca → plot_ca` の流れ。`plot_ca.smk` は固有値プロットの代わりに `plot_inertia`（`Inertia.csv` / `Total_inertia.csv` から）を持つ。

### 補助スクリプト

```bash
bash workflow/dag.sh      # 各 .smk の --rulegraph を plot/*.png に出力
bash workflow/report.sh   # 各 .smk の --report を report/*.html に出力
```

## パイプラインの流れ

```
data/coo.txt(.zst)
  → [preprocess]      バイナリ化・ラベル抽出
  → [english_label]   WHO ICD-10 → 英語病名マスタ
  → [onlinexxx]       Out-of-core PCA、dim 2..7   (CA系統は [onlineca] dim 2..7)
  → [landscaper]      Allstates.tsv + Basin.tsv + 17種PNG/dim
  → [signature]       順列検定（dim 6,7 のみ）
  → [frequency]       パターン-疾患頻度 (dim 6,7)
  → [plot]            eigenvalues/inertia, tagcloud(ja/en), heatmap, pairs, loading 等
  → [figures]         論文用 Figure を plot/Figures/{main,supplementary}/ に配置
```

- **PCA次元の使い分け**：onlinexxx / landscaper は dim 2..7 を生成。signature / frequency / plot は dim 6,7 のみ。`plot_pairs` 系のみ別途 `output/exact_ooc_pca_sparse_bincoo/10/` を参照する点に注意（`onlinexxx.smk` では生成されない）。
- **Scores.mm**：Matrix Market 形式の PCA/CAスコア。Landscaper・frequency・pairs 等の下流が読むのは `Scores.mm`（CA は `Row_coordinates.csv` も併用）。`Scores.csv` と中身は同じだが下流入力としては `.mm` を使う。
- **Eigen_vectors.csv vs Loadings.csv**：`Eigen_vectors.csv` (7,581 × k) が **ICD-10側の Loading**（`signature_score.jl` の `D x k` の D = ICD-10 数 = 7,581）。`Loadings.csv` (347M × k) は OnlinePCA.jl が出力する COO 非ゼロ要素ごとの値で、ICD-10 集約には Loadings.csv ではなく `Eigen_vectors.csv` を使う。

## アーキテクチャ

- **Julia**: 数値計算の中核。OnlinePCA / OnlineCA、疎行列I/O、パターンエンコーディング（UInt64ビットパッキングのため **k ≤ 64 次元が上限**、`Functions.jl` の assert 参照）
- **R**: 可視化。`data.table`でCSV処理、`tagcloud`でタグクラウド、スコアリング（LogitDiff, TF-IDF, PMI）、ICD-10英語名取得（`comorbidity` パッケージの `icd10_2011` / `icd10cm_2022`）
- **Shell**: Julia/Rスクリプトのラッパー。Dockerコンテナ経由で実行（Snakemake 全ルールに `container:` 指定あり）
- **Snakemake**: ワークフローオーケストレーション。多くのルールで `mem_mb=1000000`（≒1TB）を要求するため大規模ノード前提。Singularity 経由で実行（`--use-singularity`）

### 主要ソースファイル

- `src/Functions.jl` — Julia共通ユーティリティ（pattern⇔UInt64エンコード、Scores.mm→row2pat、COO.zst のテキスト/バイナリ自動判別、pairs プロット）
- `src/Functions.R` — R共通ユーティリティ（CSV読込、ID-名前マッピング、LogitDiff/TF-IDF/PMI、日本語テキスト折り返し、英語マスタ reader `read_name_table_en`）
- `src/onlinepca_*.jl` / `src/onlineca_bincoo_ca.jl` — PCA / CA 計算本体
- `src/onlinenmf_bincoo_dnmf.{jl,sh}` — DNMF版（対応する `.smk` は未作成；実験用）
- `src/frequency.jl` — Allstates.tsv + Scores.mm + COO.zst から「pattern_id × col」頻度を生成
- `src/extract_icd10_en.R` / `src/merge_disease_name_en.R` — WHO ICD-10 + CM 英語マスタ生成と既存マスタとの突合（`english_label.smk` から呼ばれる）
- `src/plot_tfidf.R` — TF-IDFタグクラウド（**ja / en 両方を `tfidf/{ja,en}/pattern_*.png` に並列出力**）
- `src/plot_loading.R` — Eigen_vectors.csv から PC1 vs PC2 の Loading 散布図（上位寄与 N=20 件に英語ラベル）
- `src/build_transition_matrix.jl` / `src/plot_transition_matrix.R` — h,J から解析的に Metropolis-Hastings 遷移確率行列 P[i,j] を計算し、Basin 別 heatmap を描画（Fig 4 / Fig S2 用）。並び替え（`sort_by`）、共通スケール（`zlim`）、Basin 代表マーク（`*` + 点線枠）対応
- `src/transition_diff_analyze.R` / `src/transition_diff_panel.R` — 各遷移 i→j について `w = L Δ ∈ R^D` (D=7,581) を計算し、変動疾患を符号付き bar で出力（Fig 5 用）。Δ は Ising 表記の状態差分 ∈ {-2, 0, +2}^k。TSV には軸内 z-score (A) と相関係数 t 検定 (B) を併記。`workflow/transition_diff.smk` で 8 pair (Basin1 5 + Basin2 3) を expand。
- `src/plot_*.R` / `src/plot_*.jl` — 各種プロット

## Dockerコンテナ

依存関係はDockerコンテナで管理。主なイメージ:
- `ghcr.io/rikenbit/onlinepcajl` — OnlinePCA.jl 環境
- `ghcr.io/chiba-ai-med/onlinecajl` — OnlineCA.jl 環境
- `ghcr.io/chiba-ai-med/landscaper:main` — Landscaper ツール
- `docker://koki/desc_onlinexxx_landscaper:20260602` — メイン解析環境（Julia + R, R可視化はこれ。`comorbidity` パッケージ含む）
- `docker://koki/mmjl` — Matrix Market 出力用 Julia 環境

## 出力構造

- `output/ooc_cov/` — 共分散・固有値・固有ベクトル（PCA系統の中間生成物）
- `output/exact_ooc_pca_sparse_bincoo/{dim}/` — PCAスコア、frequency、signature 等
  - `Eigen_vectors.csv` (ICD-10 × k Loading), `Loadings.csv` (COO非ゼロ要素 × k), `Scores.{csv,mm}`
- `output/bincoo_ca/{dim}/` — CA系統の同等出力（`Row_coordinates.csv`, `Inertia.csv` 等を含む）
- `data/who_icd10_en.tsv` — WHO+CM 英語マスタ（26,784コード）
- `data/col_id_disease_name_en_small.txt` — 既存マスタ + 英語名（被覆 88.8% = 6,729/7,581）
- `data/missing_en_codes.tsv` — 英語名未取得コード一覧（852件）
- `plot/exact_ooc_pca_sparse_bincoo/{dim}/tfidf/{ja,en}/` — 言語別 TF-IDF タグクラウド
- `plot/exact_ooc_pca_sparse_bincoo/loading_pc1_pc2.png` — Loading 散布図（FigS1C）
- `output/analytic/{dim}/` — 解析的に計算した P 行列と π_eq（Fig 4 元データ）
- `output/analytic/{dim}/transition_diff/pair_{i}_{j}.tsv` — 各遷移 i→j の変動疾患スコア（Fig 5 元データ）
- `plot/analytic/{dim}/transition_matrix_basin{1,2}.png` — Fig 4 用 heatmap
- `plot/analytic/{dim}/transition_diff_basin{1,2}.png` — Fig 5 用 panel
- `plot/Figures/{main,supplementary}/` — 論文用 Figure（`workflow/figures.smk` で集約。`figure_index.md` 参照）
- `data/`, `output/`, `plot/exact_ooc_pca_sparse_bincoo/`, `logs/`, `benchmarks/`, `.snakemake/` は gitignore（大容量データ）
