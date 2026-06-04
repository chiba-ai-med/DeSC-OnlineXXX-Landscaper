## sub-pattern 遷移行列の可視化（Basin 1 内に限定）
## - 訪問頻度上位 N パターンに絞る
## - 行: from pattern, 列: to pattern、色: 経験遷移確率 P(to | from)

args <- commandArgs(trailingOnly = TRUE)
trans_path    <- args[1]   # output/random_walk/{dim}/transition.tsv
visit_path    <- args[2]   # output/random_walk/{dim}/visit_count.tsv
subgraph_path <- args[3]   # plot/.../Landscaper/{dim}/SubGraph.tsv
outfile       <- args[4]   # plot/random_walk/{dim}/subpattern_transition.png
top_n         <- if (length(args) >= 5) as.integer(args[5]) else 12L

trans <- as.matrix(read.table(trans_path, header = FALSE))
visit <- as.integer(scan(visit_path, what = integer(), quiet = TRUE))
sub   <- as.integer(scan(subgraph_path, what = integer(), quiet = TRUE))

n_pat <- nrow(trans)
sub_full <- rep(NA_integer_, n_pat)
sub_full[seq_along(sub)] <- sub

# Basin 1 のみ、visit 上位 N
basin1_ids <- which(sub_full == 1L)
basin1_visit <- visit[basin1_ids]
ord <- order(basin1_visit, decreasing = TRUE)
sel <- basin1_ids[ord[seq_len(min(top_n, length(ord)))]]

sub_trans <- trans[sel, sel]
# 行正規化: P(to | from) = N(from→to) / sum_to N(from→to)
row_sum <- rowSums(sub_trans)
P <- sub_trans / pmax(row_sum, 1)

# 並び順: Basin 1 内 visit 上位順（既に sel が visit 降順）

dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)
png(outfile, width = 1800, height = 1700, type = "cairo", res = 220)
op <- par(no.readonly = TRUE); on.exit(par(op), add = TRUE)
par(mar = c(5.0, 5.0, 3.0, 4.5))

# heatmap (image: 行→y 軸下から上なので転置)
image(seq_along(sel), seq_along(sel), t(P[nrow(P):1, ]),
      col = hcl.colors(64, "YlOrRd", rev = TRUE),
      xlab = "", ylab = "",
      axes = FALSE,
      main = sprintf("Sub-pattern transition (Basin 1, top %d by visit)", length(sel)))
axis(1, at = seq_along(sel), labels = sel, las = 2, cex.axis = 0.9)
axis(2, at = seq_along(sel), labels = rev(sel), las = 1, cex.axis = 0.9)
mtext("To pattern", side = 1, line = 3.3, cex = 1.1)
mtext("From pattern", side = 2, line = 3.3, cex = 1.1)

# カラーバー（簡易）
zlim <- range(P, na.rm = TRUE)
ncols <- 64
xr <- par("usr")
xbar <- xr[2] + (xr[2] - xr[1]) * 0.03
wbar <- (xr[2] - xr[1]) * 0.015
ybr  <- seq(par("usr")[3], par("usr")[4], length.out = ncols + 1)
cols <- hcl.colors(ncols, "YlOrRd", rev = TRUE)
for (k in seq_len(ncols)) {
  rect(xbar, ybr[k], xbar + wbar, ybr[k+1], col = cols[k], border = NA, xpd = NA)
}
text(xbar + wbar + (xr[2]-xr[1]) * 0.005, par("usr")[3], sprintf("%.2f", zlim[1]), adj = c(0, 0), xpd = NA, cex = 0.8)
text(xbar + wbar + (xr[2]-xr[1]) * 0.005, par("usr")[4], sprintf("%.2f", zlim[2]), adj = c(0, 1), xpd = NA, cex = 0.8)
text(xbar + wbar * 0.5, par("usr")[4] + (par("usr")[4]-par("usr")[3]) * 0.04,
     "P(to|from)", xpd = NA, cex = 0.85)

dev.off()
cat(sprintf("saved: %s (top_n=%d)\n", outfile, length(sel)))
