library("showtext")
library("sysfonts")
library("stringi")
library("RColorBrewer")
library("tagcloud")
library("Matrix")
library("data.table")

# 完全検証 & disease_name ベクトル生成
build_disease_name_or_stop <- function(nm, n, finish_path) {
  # 0始まり → 1始まり補正（確証ある場合のみ）
  if (!all(is.na(nm$id))) {
    id_min <- min(nm$id, na.rm = TRUE)
    id_max <- max(nm$id, na.rm = TRUE)
    if (id_min == 0L && id_max == (n - 1L)) {
      message("0始まりIDを検出。+1 補正を適用。")
      nm$id <- nm$id + 1L
    }
  }

  # 異常チェック
  if (any(is.na(nm$id))) {
    bad_na <- which(is.na(nm$id))
    stop(sprintf(
      "名前テーブルに NA ID があります（例: 行 %s）。",
      paste(head(bad_na, 5), collapse = ", ")
    ))
  }
  if (any(nm$id < 1L | nm$id > n, na.rm = TRUE)) {
    bad_range <- which(nm$id < 1L | nm$id > n)
    stop(sprintf(
      "IDが範囲外（1..%d）。例: 行 %s。",
      n, paste(head(bad_range, 5), collapse = ", ")
    ))
  }
  if (any(duplicated(nm$id))) {
    dup_ids <- nm$id[duplicated(nm$id)]
    dup_df <- subset(nm, id %in% head(unique(dup_ids), 5))
    print(dup_df)
    stop("同じIDに複数のnameが紐付いています。上記を修正してください。")
  }

  # 被覆率チェック（1..nをすべてカバー）
  covered <- logical(n)
  covered[nm$id] <- TRUE
  missing_ids <- which(!covered)
  if (length(missing_ids)) {
    miss_file <- file.path(dirname(finish_path), "missing_name_ids.tsv")
    data.table::fwrite(
      data.table::data.table(j = missing_ids),
      miss_file, sep = "\t"
    )
    stop(sprintf(
      "名前テーブルが不完全です（被覆 %d/%d）。例: %s\n→ 完全な id→name 表（1..%d を全て含む）に差し替えてください。\n欠損リスト: %s",
      sum(covered), n, paste(head(missing_ids, 10), collapse = ", "),
      n, miss_file
    ))
  }

  # ここまで通れば完全
  disease_name <- character(n)
  disease_name[nm$id] <- nm$name
  return(disease_name)
}

# ---- 壊れCSVに強い読み込み：先頭2カンマで code,id とり、残りは name ----
read_name_table_split2 <- function(path, n_expected) {
  lines <- readLines(path, encoding = "UTF-8")
  # BOM除去 & 前後空白除去 & 空行除外
  lines <- sub("^\ufeff", "", lines, perl = TRUE)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]

  split2 <- function(s) {
    pos <- gregexpr(",", s, fixed = TRUE)[[1]]  # 半角カンマの位置
    if (identical(pos, -1) || length(pos) < 2L) {
      stop(sprintf("CSV壊れ：カンマ<2の行があります -> %s", s))
    }
    p1 <- pos[1]; p2 <- pos[2]
    code <- substr(s, 1, p1 - 1)
    id   <- substr(s, p1 + 1, p2 - 1)
    name <- substr(s, p2 + 1, nchar(s))  # 3個目以降のカンマはすべて名前に含める
    c(code, id, name)
  }

  mat <- do.call(rbind, lapply(lines, split2))
  nm  <- data.frame(code = trimws(mat[,1]),
                    id   = suppressWarnings(as.integer(trimws(mat[,2]))),
                    name = trimws(mat[,3]),
                    stringsAsFactors = FALSE)

  # 0始まり→1始まり補正（確証がある場合のみ）
  if (!all(is.na(nm$id))) {
    id_min <- min(nm$id, na.rm = TRUE); id_max <- max(nm$id, na.rm = TRUE)
    if (id_min == 0L && id_max == (n_expected - 1L)) nm$id <- nm$id + 1L
  }
  nm
}

# M をスコア化して返す（logitdiff / tfidf / pmi）
score_matrix <- function(M, method = c("logitdiff", "tfidf", "pmi"),
  alpha = 1) {
  method <- match.arg(method)
  rs <- Matrix::rowSums(M)          # 各パターンの総数 n_s
  cs <- Matrix::colSums(M)          # 各疾患の総数 colsum_j

  if (method == "tfidf") {
    # tf = c_ij / rowsum_i,  idf = log((S+1)/(df_j+1)) + 1,  S=nrow(M)
    df  <- Matrix::colSums(sign(M))                     # その疾患が出たパターン数
    idf <- log((nrow(M) + 1) / (df + 1)) + 1
    S <- M
    S@x <- S@x / rs[S@i + 1]                            # tf を非ゼロのみで
    return(S %*% Matrix::Diagonal(x = as.numeric(idf))) # 列に idf を掛ける
  }

  if (method == "pmi") {  # = PMI（相互情報量）に対応
    # w_ij = log( (c_ij + α) * Nc / ((rowsum_i + α)*(colsum_j + α)) )
    Nc <- sum(cs)
    S  <- M
    i_idx  <- S@i + 1
    j_ptr  <- rep.int(seq_len(ncol(S)), diff(S@p))
    S@x <- log( (S@x + alpha) * Nc /
                ( (rs[i_idx] + alpha) * (cs[j_ptr] + alpha) ) )
    return(S)
  }

  # method == "logitdiff"
  # A_ij = logit( (c_ij+α)/(rowsum_i+2α) ) - logit( (colsum_j+α)/(N+2α) )
  N <- sum(rs)
  logit <- function(p) log(p) - log1p(-p)
  base_logit <- logit( (cs + alpha) / (N + 2*alpha) )
  S <- M
  i_idx <- S@i + 1
  j_ptr <- rep.int(seq_len(ncol(S)), diff(S@p))
  p_ij  <- (S@x + alpha) / (rs[i_idx] + 2*alpha)
  S@x   <- logit(p_ij) - base_logit[j_ptr]
  return(S)
}

# Google フォントを使う場合（ネット接続必要）
if (!"jp" %in% sysfonts::font_families()) {
  sysfonts::font_add_google("Noto Sans JP", "jp")
}
showtext_auto(enable = TRUE)

wrap_jp <- function(x, width = 10) {
  vapply(
    x,
    function(s) {
      n <- nchar(s, type = "width")  # 幅ベース
      if (n <= width) return(s)
      # code point ベースで幅が width を超えないように切る
      chars <- stringi::stri_split_boundaries(s, type = "character")[[1]]
      out <- character(0)
      buf <- ""
      w <- 0
      for (ch in chars) {
        w <- w + nchar(ch, type = "width")
        buf <- paste0(buf, ch)
        if (w >= width) {
          out <- c(out, buf); buf <- ""; w <- 0
        }
      }
      if (nzchar(buf)) out <- c(out, buf)
      paste(out, collapse = "\n")
    },
    character(1)
  )
}
