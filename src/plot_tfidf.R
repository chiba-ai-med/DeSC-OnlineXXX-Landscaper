source("src/Functions.R")

## Args
args <- commandArgs(trailingOnly = TRUE)
freq_path   <- args[1]  # '.../frequency.csv' (TSV: pattern_id\tj\tcount)
name_path   <- args[2]  # 'data/col_id_disease_name_small.txt'（3列目が病名）
finish_path <- args[3]  # '.../frequency/FINISH'
# freq_path <- 'output/exact_ooc_pca_sparse_bincoo/6/frequency.csv'
# name_path <- 'data/col_id_disease_name_small.txt'
# finish_path <- 'plot/exact_ooc_pca_sparse_bincoo/6/frequency/FINISH'

## 出力ディレクトリ
outdir <- dirname(finish_path)
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

## 1) frequency を読む（必ずTSV・3列）
freq <- fread(
  freq_path, sep = "\t", header = FALSE, showProgress = FALSE,
  col.names = c("pid", "j", "cnt")
)

## 2) 疾患名テーブルを堅牢に読む
# まずカンマ区切り・ヘッダ無し（1列に code,id,name）
nm <- tryCatch(
  fread(name_path, header = FALSE, sep = ",", data.table = FALSE,
        quote = "\"", fill = TRUE),
  error = function(e) fread(name_path, header = TRUE, sep = ",",
                            data.table = FALSE, quote = "\"", fill = TRUE)
)
# 列名を揃える（最低3列ある前提）
if (ncol(nm) < 3) {
  stop(sprintf("病名テーブルの列数が足りません: %s (cols=%d)", name_path, ncol(nm)))
}
colnames(nm)[1:3] <- c("code","id","name")

# id を整数化
nm$id <- suppressWarnings(as.integer(nm$id))

## 3) 次元は frequency に合わせる（安全）
m <- max(freq$pid)
n <- max(freq$j)

## 2') nameテーブル：先頭2カンマ分割で安全に読み、完全検証＆正規化（Functions.R内）
nm <- read_name_table_split2(name_path, n_expected = n)   # code,id,name を復元
disease_name <- build_disease_name_or_stop(nm, n, finish_path)  # 欠損/重複/範囲外があれば stop

## 5) 疎行列（pattern × disease）を構築（dgCMatrix）
M <- sparseMatrix(i = freq$pid, j = freq$j, x = freq$cnt,
                  dims = c(m, n), index1 = TRUE)

# スコア差し替え
M <- score_matrix(M, method = "tfidf", alpha = 1)

## 6) 可視化（各パターン行 i の上位20疾患をタグクラウド）
pal <- colorRampPalette(rev(brewer.pal(9, "YlOrRd")))

for (i in seq_len(m)) {
  v <- as.numeric(M[i, ])
  if (!any(v > 0)) next

  ord <- order(v, decreasing = TRUE)
  k <- min(20L, sum(v > 0))
  idx <- ord[seq_len(k)]
  w   <- v[idx]  # ウェイト（出現頻度）

  # 値が大きいほど強い色
  colmap <- pal(k)
  cols   <- colmap[rank(-w, ties.method = "first")]

  # 日本語ラベルを折り返し
  labels <- wrap_jp(disease_name[idx], width = 20)

  # 出力
  fname <- file.path(outdir, sprintf("pattern_%d.png", i))
  png(fname, width = 900, height = 900, type = "cairo")  # Cairo で文字化け回避
  # 可能なら日本語フォント
  op <- par(no.readonly = TRUE)
  on.exit(par(op), add = TRUE)
  if ("jp" %in% names(op$font)) par(family = "jp")
  tagcloud(labels, weights = w, col = cols)
  dev.off()
}

## 7) FINISH ファイル
file.create(finish_path)