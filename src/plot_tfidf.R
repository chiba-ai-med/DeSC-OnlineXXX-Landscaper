source("src/Functions.R")

## Args
args <- commandArgs(trailingOnly = TRUE)
freq_path      <- args[1]  # '.../frequency.csv' (TSV: pattern_id\tj\tcount)
name_path_ja   <- args[2]  # 'data/col_id_disease_name_small.txt'（CSV 3列、3列目が日本語病名）
name_path_en   <- args[3]  # 'data/col_id_disease_name_en_small.txt'（TSV 5列、4列目が英語名）
finish_path_ja <- args[4]  # '.../{dim}/tfidf/ja/FINISH'
finish_path_en <- args[5]  # '.../{dim}/tfidf/en/FINISH'

## 1) frequency を読む（必ずTSV・3列）
freq <- fread(
  freq_path, sep = "\t", header = FALSE, showProgress = FALSE,
  col.names = c("pid", "j", "cnt")
)

m <- max(freq$pid)
n <- max(freq$j)

## 2) 疎行列（pattern × disease） + TF-IDFスコア化
M <- sparseMatrix(i = freq$pid, j = freq$j, x = freq$cnt,
                  dims = c(m, n), index1 = TRUE)
M <- score_matrix(M, method = "tfidf", alpha = 1)

## 3) 病名ラベル（ja / en）を作成
# ja: 既存と完全に同じ流れ（read_name_table_split2 → build_disease_name_or_stop）
nm_ja <- read_name_table_split2(name_path_ja, n_expected = n)
disease_name_ja <- build_disease_name_or_stop(nm_ja, n, finish_path_ja)

# en: Phase 1 出力の5列TSVから取得。id を rowname とした文字ベクトル化。
nm_en <- read_name_table_en(name_path_en)
disease_name_en <- rep("(NA)", n)
en_name <- nm_en$en_name
ok <- !is.na(en_name) & nzchar(en_name) & en_name != "NA"
disease_name_en[nm_en$id[ok]] <- en_name[ok]

## 4) タグクラウド描画（言語ごとに同じロジックで生成）
pal <- colorRampPalette(rev(brewer.pal(9, "YlOrRd")))

plot_tagclouds <- function(disease_name, finish_path, lang) {
  outdir <- dirname(finish_path)
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

  # "(NA)" 列はタグクラウドから除外
  valid_col <- disease_name != "(NA)"

  for (i in seq_len(m)) {
    v <- as.numeric(M[i, ])
    v[!valid_col] <- 0
    if (!any(v > 0)) next

    ord <- order(v, decreasing = TRUE)
    k <- min(10L, sum(v > 0))
    idx <- ord[seq_len(k)]
    w   <- v[idx]

    colmap <- pal(k)
    cols   <- colmap[rank(-w, ties.method = "first")]

    # 言語別の折り返し（長いラベルが切れないように）
    if (lang == "ja") {
      labels <- wrap_jp(disease_name[idx], width = 20)
    } else {
      # 英語は単語境界で折り返し
      labels <- vapply(
        disease_name[idx],
        function(s) paste(strwrap(s, width = 25), collapse = "\n"),
        character(1)
      )
    }

    fname <- file.path(outdir, sprintf("pattern_%d.png", i))
    png(fname, width = 900, height = 900, type = "cairo")
    op <- par(no.readonly = TRUE)
    on.exit(par(op), add = TRUE)
    if (lang == "ja" && "jp" %in% names(op$font)) par(family = "jp")
    tagcloud(labels, weights = w, col = cols)
    dev.off()
  }

  file.create(finish_path)
}

plot_tagclouds(disease_name_ja, finish_path_ja, "ja")
plot_tagclouds(disease_name_en, finish_path_en, "en")
