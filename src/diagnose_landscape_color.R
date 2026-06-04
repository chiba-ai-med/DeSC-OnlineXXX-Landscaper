## Landscape.png の色分けと座標の整合性診断
## Coordinate.tsv (各 pattern の (x, y))
## SubGraph.tsv (各 pattern の basin id)
## を結合して散布図化し、basin が空間的に分離しているかを直接見る

args <- commandArgs(trailingOnly = TRUE)
coord_path <- args[1]   # plot/.../Landscaper/7/Coordinate.tsv
sub_path   <- args[2]   # plot/.../Landscaper/7/SubGraph.tsv
basin_path <- args[3]   # plot/.../Landscaper/7/Basin.tsv
outfile    <- args[4]

coord <- as.matrix(read.table(coord_path, header = FALSE))
sub   <- as.integer(scan(sub_path, what = integer(), quiet = TRUE))
basin_reps <- as.integer(scan(basin_path, what = integer(), quiet = TRUE))

n_pat <- nrow(coord)
sub_full <- rep(NA_integer_, n_pat)
sub_full[seq_along(sub)] <- sub

## Basin 別の (x, y) 範囲を表示
cat("=== Basin members (by SubGraph) and coordinate ranges ===\n")
for (b in sort(unique(na.omit(sub_full)))) {
  idx <- which(sub_full == b)
  cat(sprintf("Basin %d: n=%d members, x in [%.3f, %.3f], y in [%.3f, %.3f]\n",
              b, length(idx),
              min(coord[idx, 1]), max(coord[idx, 1]),
              min(coord[idx, 2]), max(coord[idx, 2])))
}
na_idx <- which(is.na(sub_full))
if (length(na_idx) > 0) {
  cat(sprintf("Unassigned: n=%d members\n", length(na_idx)))
}

cat("\n=== Basin reps (Basin.tsv): pattern ids = ", paste(basin_reps, collapse=", "), "\n")
for (rid in basin_reps) {
  if (rid <= n_pat) {
    cat(sprintf("  pattern %d at (%.3f, %.3f), SubGraph=%s\n",
                rid, coord[rid, 1], coord[rid, 2],
                ifelse(is.na(sub_full[rid]), "NA", sub_full[rid])))
  }
}

## 散布図描画
dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)
png(outfile, width = 1800, height = 1700, type = "cairo", res = 210)
op <- par(no.readonly = TRUE); on.exit(par(op), add = TRUE)
par(mar = c(4.5, 4.5, 3.0, 1.5))

cols <- ifelse(is.na(sub_full), "gray60",
               ifelse(sub_full == 1L, "#3a6dd9", "#d94a3a"))
plot(coord[, 1], coord[, 2],
     col = cols, pch = 19, cex = 1.6,
     xlab = "x (Coordinate.tsv col 1)", ylab = "y (Coordinate.tsv col 2)",
     main = "Landscape coordinates colored by SubGraph (Basin)")
abline(h = 0, v = 0, col = "gray70", lty = 2)

## Basin 代表をマーキング
for (rid in basin_reps) {
  if (rid <= n_pat) {
    points(coord[rid, 1], coord[rid, 2],
           pch = 21, cex = 3.5, lwd = 2.5,
           bg = NA, col = "black")
    text(coord[rid, 1], coord[rid, 2], labels = paste0(rid, "*"),
         pos = 4, cex = 1.0, font = 2)
  }
}

legend("topright",
       legend = c("Basin 1", "Basin 2", "unassigned", "Basin rep"),
       col = c("#3a6dd9", "#d94a3a", "gray60", "black"),
       pch = c(19, 19, 19, 21),
       pt.cex = c(1.5, 1.5, 1.5, 2.0),
       bty = "n")

dev.off()
cat(sprintf("\nsaved: %s\n", outfile))
