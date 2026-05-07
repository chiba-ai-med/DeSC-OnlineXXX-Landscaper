# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

大規模疎行列バイナリデータ（COO形式、7,581行 × 347,764,079列）に対して、OnlinePCA.jl / OnlineCA.jl による次元削減を行い、Landscaperによるエネルギーランドスケープ解析と疾患パターン可視化を行うバイオインフォマティクスパイプライン。

## ワークフロー実行

Snakemake（v8.11.1以上）で管理。各ワークフローは独立した`.smk`ファイル。実行順序に依存があるため下記の順で回す。

### PCA系統（`output/exact_ooc_pca_sparse_bincoo/`）

```bash
# 前処理（COOバイナリ化、disease/sex/age ラベル抽出）
snakemake -s workflow/preprocess.smk --cores <n>

# OnlinePCA（Out-of-core 共分散 → 固有値分解 → PCAスコア）
snakemake -s workflow/onlinexxx.smk --cores <n>

# Landscaper（エネルギーランドスケープ；Allstates.tsv を生成）
snakemake -s workflow/landscaper.smk --cores <n>

# 以下は landscaper の Allstates.tsv に依存
snakemake -s workflow/signature.smk --cores <n>   # 順列検定スコア
snakemake -s workflow/frequency.smk --cores <n>   # パターン×疾患頻度

# プロット（eigenvalues / signature / frequency / TF-IDF / PMI / LogitDiff / pairs）
snakemake -s workflow/plot.smk --cores <n>
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
  → [preprocess]   バイナリ化・ラベル抽出
  → [onlinexxx]    Out-of-core PCA、dim 2..7   (CA系統は [onlineca] dim 2..7)
  → [landscaper]   Allstates.tsv + 17種PNG/dim
  → [signature]    順列検定（dim 6,7 のみ）
  → [frequency]    パターン-疾患頻度 (dim 6,7)
  → [plot]         eigenvalues/inertia, tagcloud, heatmap, pairs 等
```

- **PCA次元の使い分け**：onlinexxx / landscaper は dim 2..7 を生成。signature / frequency / plot は dim 6,7 のみ。`plot_pairs` 系のみ別途 `output/exact_ooc_pca_sparse_bincoo/10/` を参照する点に注意（`onlinexxx.smk` では生成されない）。
- **Scores.mm**：Matrix Market 形式の PCA/CAスコア。Landscaper・frequency・pairs 等の下流が読むのは `Scores.mm`（CA は `Row_coordinates.csv` も併用）。`Scores.csv` と中身は同じだが下流入力としては `.mm` を使う。

## アーキテクチャ

- **Julia**: 数値計算の中核。OnlinePCA / OnlineCA、疎行列I/O、パターンエンコーディング（UInt64ビットパッキングのため **k ≤ 64 次元が上限**、`Functions.jl` の assert 参照）
- **R**: 可視化。`data.table`でCSV処理、`tagcloud`でタグクラウド、スコアリング（LogitDiff, TF-IDF, PMI）
- **Shell**: Julia/Rスクリプトのラッパー。Dockerコンテナ経由で実行（Snakemake 全ルールに `container:` 指定あり）
- **Snakemake**: ワークフローオーケストレーション。多くのルールで `mem_mb=1000000`（≒1TB）を要求するため大規模ノード前提

### 主要ソースファイル

- `src/Functions.jl` — Julia共通ユーティリティ（pattern⇔UInt64エンコード、Scores.mm→row2pat、COO.zst のテキスト/バイナリ自動判別、pairs プロット）
- `src/Functions.R` — R共通ユーティリティ（CSV読込、ID-名前マッピング、LogitDiff/TF-IDF/PMI、日本語テキスト折り返し）
- `src/onlinepca_*.jl` / `src/onlineca_bincoo_ca.jl` — PCA / CA 計算本体
- `src/onlinenmf_bincoo_dnmf.{jl,sh}` — DNMF版（対応する `.smk` は未作成；実験用）
- `src/frequency.jl` — Allstates.tsv + Scores.mm + COO.zst から「pattern_id × col」頻度を生成
- `src/plot_*.R` / `src/plot_*.jl` — 各種プロット

## Dockerコンテナ

依存関係はDockerコンテナで管理。主なイメージ:
- `ghcr.io/rikenbit/onlinepcajl` — OnlinePCA.jl 環境
- `ghcr.io/chiba-ai-med/onlinecajl` — OnlineCA.jl 環境
- `ghcr.io/chiba-ai-med/landscaper:main` — Landscaper ツール
- `docker://koki/desc_onlinexxx_landscaper` — メイン解析環境（Julia + R, R可視化はこれ）
- `docker://koki/mmjl` — Matrix Market 出力用 Julia 環境

## 出力構造

- `output/ooc_cov/` — 共分散・固有値・固有ベクトル（PCA系統の中間生成物）
- `output/exact_ooc_pca_sparse_bincoo/{dim}/` — PCAスコア、frequency、signature 等
- `output/bincoo_ca/{dim}/` — CA系統の同等出力（`Row_coordinates.csv`, `Inertia.csv` 等を含む）
- `plot/exact_ooc_pca_sparse_bincoo/`, `plot/bincoo_ca/` — 全可視化結果
- `data/`, `output/`, `plot/exact_ooc_pca_sparse_bincoo/`, `logs/`, `benchmarks/`, `.snakemake/` は gitignore（大容量データ）
