## H4 robustness: bootstrap ARI between k-means(k=2) and ELA basin
##
## - person_table の baseline_PC1-7 を使い、N 回 bootstrap (~30k subsample) × k-means
## - 各 bootstrap で ELA basin との ARI / NMI を計算
## - ARI 分布をヒストグラム + 中央値の表示
##
## 目的: ELA basin と k-means cluster の一致度の安定性 (= ELA は density-based clustering を超えた情報)

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

ARI <- function(a, b) {
  ct <- table(a, b)
  na <- sum(choose(rowSums(ct), 2))
  nb <- sum(choose(colSums(ct), 2))
  nt <- sum(ct)
  expected <- (na * nb) / choose(nt, 2)
  observed <- sum(choose(ct, 2))
  (observed - expected) / ((na + nb) / 2 - expected)
}
NMI <- function(a, b) {
  ct <- table(a, b)
  n  <- sum(ct)
  pxy <- ct / n
  px <- rowSums(pxy); py <- colSums(pxy)
  px[px == 0] <- 1e-12; py[py == 0] <- 1e-12
  mi <- 0
  for (i in seq_along(px)) for (j in seq_along(py)) {
    if (pxy[i, j] > 0) mi <- mi + pxy[i, j] * log2(pxy[i, j] / (px[i] * py[j]))
  }
  hx <- -sum(px * log2(px))
  hy <- -sum(py * log2(py))
  2 * mi / (hx + hy)
}

args <- commandArgs(trailingOnly = TRUE)
pt_path <- args[1]
out_tsv <- args[2]
out_png <- args[3]
n_boot  <- if (length(args) >= 4) as.integer(args[4]) else 50L
n_sub   <- if (length(args) >= 5) as.integer(args[5]) else 30000L

dir.create(dirname(out_tsv), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(out_png), showWarnings = FALSE, recursive = TRUE)

cat("Loading person_table ...\n")
pt <- fread(pt_path,
            select = c("baseline_basin", paste0("baseline_PC", 1:7)))
pt <- pt[!is.na(baseline_basin)]
cat(sprintf("  n = %d\n", nrow(pt)))

set.seed(42)
results <- data.frame(
  bootstrap = integer(),
  ARI = numeric(),
  NMI = numeric()
)
for (b in seq_len(n_boot)) {
  idx <- sample.int(nrow(pt), n_sub)
  X <- as.matrix(pt[idx, paste0("baseline_PC", 1:7), with = FALSE])
  ela <- pt$baseline_basin[idx]
  km <- kmeans(X, centers = 2L, nstart = 5, iter.max = 100)
  ari <- ARI(km$cluster, ela)
  nmi <- NMI(km$cluster, ela)
  results <- rbind(results, data.frame(bootstrap = b, ARI = ari, NMI = nmi))
  if (b %% 10 == 0) cat(sprintf("  boot %d/%d : ARI=%.3f NMI=%.3f\n", b, n_boot, ari, nmi))
}
fwrite(results, out_tsv, sep = "\t")
cat("\n=== Bootstrap summary ===\n")
cat(sprintf("ARI : median=%.3f  IQR=[%.3f, %.3f]\n",
            median(results$ARI),
            quantile(results$ARI, 0.25),
            quantile(results$ARI, 0.75)))
cat(sprintf("NMI : median=%.3f  IQR=[%.3f, %.3f]\n",
            median(results$NMI),
            quantile(results$NMI, 0.25),
            quantile(results$NMI, 0.75)))

## ヒストグラム
long <- melt(as.data.table(results), id.vars = "bootstrap",
             variable.name = "metric", value.name = "value")
g <- ggplot(long, aes(x = value, fill = metric)) +
  geom_histogram(bins = 20, alpha = 0.7) +
  geom_vline(xintercept = 0, linetype = 2, color = "gray40") +
  facet_wrap(~ metric, scales = "free") +
  scale_fill_manual(values = c("ARI" = "#3a6dd9", "NMI" = "#d94a3a"),
                    guide = "none") +
  labs(title = "H4 bootstrap: k-means(k=2) vs ELA basin agreement",
       subtitle = sprintf("%d bootstrap × %d-person subsample of PC1-7 space",
                          n_boot, n_sub),
       x = "Score (0-1)", y = "Bootstrap count") +
  theme_minimal(base_size = 14) +
  theme(strip.text = element_text(face = "bold", size = 13))
ggsave(out_png, g, width = 9, height = 4.5, dpi = 200)
cat(sprintf("\nsaved: %s\nsaved: %s\n", out_tsv, out_png))
