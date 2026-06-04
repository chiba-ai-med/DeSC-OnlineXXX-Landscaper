# Data Availability — Post-ELA 解析向け

論文 Section 4 (Outcome) および仮説検証 H1〜H6 に必要なデータの所在と structure。

## DeSC primary CSV (`/home/desc/utf8/all/`)

| File | Size | 主要列 (本解析で使う) | 用途 |
|---|---|---|---|
| `tekiyo.csv` | 1.3 GB (= ローカル `data/tekiyo.csv`) | `kojin_id`, `birth_ym`, `sex_code`, `observable_start_ym`, `observable_end_ym`, `shibou_flg`, `kenshin_data_ari`, `shika_receipt_ari` | **Person 単位 base + 死亡フラグ + 観察期間**。11,303,290 ユニーク person (1 行=1 person)。|
| `receipt.csv` | 25 GB | `kojin_id`, `receipt_ym`, `nyugai_kbn_code` (1=入院/2=外来?), `nyuin_ymd`, `taiin_ymd` | **入院 outcome** (Phase 5)。Cox B/G。|
| `receipt_drug.csv` | 92 GB | `kojin_id`, `receipt_ym`, `drug_code` | 薬剤レセプト。ATC コード化に `m_drug_who_atc.csv` 併用。H1/H2/H5 |
| `m_drug_who_atc.csv` | 5 MB | `drug_code → atc_code, atc_*_name` | WHO ATC マスタ。スタチン (C10AA), メトホルミン (A10BA02), ビスホスホネート (M05BA), NSAIDs (M01A), ステロイド (H02), 抗ヒスタミン (R06) を抽出 |
| `exam_interview.csv` | 1.4 GB | `kojin_id`, `exam_ymd`, `ldl_*`, `hdl_*`, `chusei_shibou_*` (TG), `got_*`, `gpt_*`, `hba1c_*`, `bmi`, `systolic_blood_pressure*`, `e_gfr` | **健診データ** (H1 lipid phenotype)。`kenshin_data_ari=1` の subset でのみ利用可。 |
| `m_dental_treat.csv` | 94 KB | 歯科処置マスタ | H6 |
| `receipt_dental_practice*.csv` | (確認要) | 歯科レセプト | H6 |

## ローカル既存ファイル

| File | 内容 |
|---|---|
| `data/tekiyo.csv` | DeSC primary のローカル copy (1 行=1 person、11.3M rows) |
| `data/row_id_number_small.txt` | 347M 行 × 列 (kojin_id, month) で各 row が person × time-window を指す |
| `data/age_label.txt` | 347M 行 × `YYYY/MM` 生年 |
| `data/sex_label.txt` | 347M 行 × sex |
| `data/disease_label.txt` | 347M 行 × disease label (代表病名?) |
| `output/exact_ooc_pca_sparse_bincoo/7/Scores.csv` | 347M × 7 PC score |
| `output/exact_ooc_pca_sparse_bincoo/7/row2pat.bin` | UInt32 × 347M、row → pattern_id |
| `plot/exact_ooc_pca_sparse_bincoo/Landscaper/7/Allstates.tsv` | 128 × 7 Ising 状態 |
| `plot/exact_ooc_pca_sparse_bincoo/Landscaper/7/SubGraph.tsv` | pattern_id → basin assignment |
| `plot/exact_ooc_pca_sparse_bincoo/Landscaper/7/Basin.tsv` | basin 代表 pattern_id (2 行: 32, 75) |
| `plot/exact_ooc_pca_sparse_bincoo/Landscaper/7/E.tsv` | 128 × energy |

## Scope 判定 (仮説別)

| 仮説 / outcome | 必要データ | 取得可否 | 備考 |
|---|---|---|---|
| H1 lipid sub-phenotype | exam_interview.csv | ◯ | `kenshin_data_ari=1` で subset |
| H2 Locomo + メタボ | tekiyo + COO + drug (M05BA) | ◯ | drug 部分は ATC join |
| H3 加齢の二分 | row2pat + Scores + age | ◯ | DeSC primary 不要 |
| H4 ELA robustness | 既存 ELA workflow を parameterize | ◯ | 計算 heavy |
| H5 inflammation | drug (M01A, H02, R06) | ◯ | drug ATC join |
| H6 dental | 歯科レセプト | △ | `shika_receipt_ari=1` 確認 + dental practice ファイル parse 要 |
| Outcome A: Cox death + Basin | tekiyo + person_table | ◯ | Phase 1 完了後即実装 |
| Outcome B: Cox 入院 + Basin | receipt.csv の入院 flag | ◯ | Phase 5 |
| Outcome D: Cox death + Energy E | tekiyo + E.tsv | ◯ | 新規性高 |

## 結論

全 6 仮説 + 4 Cox model + 入院 outcome すべて DeSC 内データで実装可能。H6 dental のみ歯科レセプトの parse 構造を後で確認すれば全 scope 達成。
