## 解析的 P 行列のヒートマップ
## Basin 1 / Basin 2 内で π_eq 上位 N パターンを抽出、P[i, j] を heatmap で表示
## - タイトルなし
## - Basin 代表パターン (Basin.tsv) には軸ラベルに * を付ける
## - zlim を引数で渡せば 2 枚を共通スケールに揃えられる

args <- commandArgs(trailingOnly = TRUE)
P_path        <- args[1]   # output/analytic/{dim}/P.tsv
pi_path       <- args[2]   # output/analytic/{dim}/pi_eq.tsv
subgraph_path <- args[3]   # plot/.../Landscaper/{dim}/SubGraph.tsv
outfile       <- args[4]
top_n         <- if (length(args) >= 5) as.integer(args[5]) else 12L
target_basin  <- if (length(args) >= 6) as.integer(args[6]) else 1L
basin_path    <- if (length(args) >= 7) args[7] else NA   # Basin.tsv
zlim_max      <- if (length(args) >= 8) as.numeric(args[8]) else NA
sort_by       <- if (length(args) >= 9) args[9] else "pi_eq"   # "pi_eq" or "to_basin_rep"

P   <- as.matrix(read.table(P_path, header = FALSE))
pi  <- as.numeric(scan(pi_path, what = double(), quiet = TRUE))
sub <- as.integer(scan(subgraph_path, what = integer(), quiet = TRUE))

n_pat <- nrow(P)
sub_full <- rep(NA_integer_, n_pat)
sub_full[seq_along(sub)] <- sub

# 対象 basin の pattern を π_eq 降順で並べる
basin_ids <- which(sub_full == target_basin)
ord <- order(pi[basin_ids], decreasing = TRUE)
sel <- basin_ids[ord[seq_len(min(top_n, length(ord)))]]

# Basin 代表 (Basin.tsv) を読み込み、* マーク用
basin_reps <- integer(0)
if (!is.na(basin_path) && file.exists(basin_path)) {
  basin_reps <- as.integer(scan(basin_path, what = integer(), quiet = TRUE))
}

# 並び替え（sort_by="to_basin_rep" なら Basin 代表への遷移確率降順）
if (sort_by == "to_basin_rep" && length(basin_reps) > 0) {
  rep_in_sel <- which(sel %in% basin_reps)
  if (length(rep_in_sel) > 0) {
    rep_pid <- sel[rep_in_sel[1]]   # この heatmap に含まれる Basin 代表（target_basin の方）
    P_to_rep <- P[sel, rep_pid]
    sel <- sel[order(P_to_rep, decreasing = TRUE)]
  }
}

sel_labels <- ifelse(sel %in% basin_reps,
                     paste0(sel, "*"),
                     as.character(sel))

# 部分行列
Psub <- P[sel, sel]

dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)

# メンバー数に応じてキャンバスと文字サイズを調整
n_show <- length(sel)
if (n_show > 40) {
  img_w <- 3200; img_h <- 3000; img_res <- 200
  axis_cex <- 0.45
  lab_cex  <- 1.2
} else if (n_show > 20) {
  img_w <- 2400; img_h <- 2300; img_res <- 220
  axis_cex <- 0.75
  lab_cex  <- 1.4
} else {
  img_w <- 1900; img_h <- 1800; img_res <- 210
  axis_cex <- 1.4
  lab_cex  <- 1.6
}

png(outfile, width = img_w, height = img_h, type = "cairo", res = img_res)
op <- par(no.readonly = TRUE); on.exit(par(op), add = TRUE)
par(mar = c(5.2, 5.2, 1.5, 5.0))

# zlim 決定（指定があれば共通スケール、なければ自動）
if (is.na(zlim_max)) {
  zlim <- range(Psub, na.rm = TRUE)
} else {
  zlim <- c(0, zlim_max)
}

image(seq_along(sel), seq_along(sel), t(Psub[nrow(Psub):1, ]),
      col = hcl.colors(64, "YlOrRd", rev = TRUE),
      xlab = "", ylab = "",
      axes = FALSE,
      zlim = zlim)
axis(1, at = seq_along(sel), labels = sel_labels, las = 2, cex.axis = axis_cex)
axis(2, at = seq_along(sel), labels = rev(sel_labels), las = 1, cex.axis = axis_cex)
mtext("To pattern",   side = 1, line = 3.6, cex = lab_cex)
mtext("From pattern", side = 2, line = 3.6, cex = lab_cex)

# カラーバー
ncols <- 64
xr <- par("usr")
xbar <- xr[2] + (xr[2] - xr[1]) * 0.03
wbar <- (xr[2] - xr[1]) * 0.020
ybr  <- seq(par("usr")[3], par("usr")[4], length.out = ncols + 1)
cols <- hcl.colors(ncols, "YlOrRd", rev = TRUE)
for (k in seq_len(ncols)) {
  rect(xbar, ybr[k], xbar + wbar, ybr[k+1], col = cols[k], border = NA, xpd = NA)
}
text(xbar + wbar + (xr[2]-xr[1]) * 0.008, par("usr")[3], sprintf("%.2f", zlim[1]),
     adj = c(0, 0), xpd = NA, cex = axis_cex * 0.95)
text(xbar + wbar + (xr[2]-xr[1]) * 0.008, par("usr")[4], sprintf("%.2f", zlim[2]),
     adj = c(0, 1), xpd = NA, cex = axis_cex * 0.95)
text(xbar + wbar * 0.5, par("usr")[4] + (par("usr")[4]-par("usr")[3]) * 0.04,
     "P[i,j]", xpd = NA, cex = lab_cex * 0.85)

dev.off()
cat(sprintf("saved: %s  (top_n=%d, basin=%d, zlim=[%g,%g])\n",
            outfile, length(sel), target_basin, zlim[1], zlim[2]))
