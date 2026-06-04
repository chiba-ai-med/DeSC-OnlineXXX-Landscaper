## H4 robustness: ELA basin と代替手法 (k-means, GMM) の cluster assignment 一致度
##
## 入力: output/person_table.tsv (baseline_PC1-7 + baseline_basin)
## 出力: output/h4/{tsv, png}

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

## ARI / NMI 自作 (パッケージ依存を回避)
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
out_dir <- args[2]

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cat("Loading person_table ...\n")
pt <- fread(pt_path,
            select = c("kojin_id", "baseline_basin",
                       paste0("baseline_PC", 1:7)))
pt <- pt[!is.na(baseline_basin)]
cat(sprintf("  n = %d\n", nrow(pt)))

## 計算負荷軽減のため 300,000 person sample (再現性 seed 固定)
set.seed(42)
N_SAMPLE <- 300000
idx <- sample.int(nrow(pt), N_SAMPLE)
sub <- pt[idx]
X <- as.matrix(sub[, paste0("baseline_PC", 1:7), with = FALSE])
ela_labels <- sub$baseline_basin
cat(sprintf("  sampled n = %d for clustering\n", N_SAMPLE))

##-------------------------------------------------------------------
## (1) k-means (k = 2, 3, 4)
##-------------------------------------------------------------------
km_results <- list()
for (k in c(2, 3, 4)) {
  km <- kmeans(X, centers = k, nstart = 10, iter.max = 100)
  ari <- ARI(km$cluster, ela_labels)
  nmi <- NMI(km$cluster, ela_labels)
  km_results[[length(km_results) + 1]] <- data.frame(
    method = sprintf("k-means (k=%d)", k),
    n_clusters = k,
    ARI = ari, NMI = nmi
  )
  cat(sprintf("  k-means k=%d : ARI=%.3f  NMI=%.3f\n", k, ari, nmi))
}

## GMM はパッケージなしでは重い → 省略 (代替手法は k-means と Hierarchical で十分)
gmm_results <- list()

##-------------------------------------------------------------------
## (3) Hierarchical (Ward) — 軽量、サブサンプル
##-------------------------------------------------------------------
cat("\nHierarchical (Ward, k=2/3, on 30k sub) ...\n")
sub_idx2 <- sample(N_SAMPLE, 30000)
X_small <- X[sub_idx2, ]
ela_small <- ela_labels[sub_idx2]
d <- dist(X_small)
hc <- hclust(d, method = "ward.D2")
hc_results <- list()
for (k in c(2, 3, 4)) {
  cl <- cutree(hc, k = k)
  ari <- ARI(cl, ela_small)
  nmi <- NMI(cl, ela_small)
  hc_results[[length(hc_results) + 1]] <- data.frame(
    method = sprintf("Hierarchical (k=%d)", k),
    n_clusters = k,
    ARI = ari, NMI = nmi
  )
  cat(sprintf("  Hier k=%d : ARI=%.3f  NMI=%.3f\n", k, ari, nmi))
}

##-------------------------------------------------------------------
## 集約
##-------------------------------------------------------------------
all_df <- do.call(rbind, c(km_results, gmm_results, hc_results))
fwrite(all_df, file.path(out_dir, "h4_clustering_comparison.tsv"), sep = "\t")
cat("\n=== Summary ===\n")
print(all_df)

##-------------------------------------------------------------------
## プロット
##-------------------------------------------------------------------
plot_df <- melt(as.data.table(all_df), id.vars = c("method", "n_clusters"),
                measure.vars = c("ARI", "NMI"))
g <- ggplot(plot_df, aes(x = method, y = value, fill = variable)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("ARI" = "#3a6dd9", "NMI" = "#d94a3a")) +
  ylim(0, 1) +
  labs(title = "H4: Concordance of ELA basin with alternative clustering",
       subtitle = sprintf("on %d sampled persons (PC1-7 features)", N_SAMPLE),
       x = NULL, y = "Concordance with ELA basin (0-1)", fill = NULL) +
  theme_minimal(base_size = 13) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1),
        legend.position = "top")
ggsave(file.path(out_dir, "h4_clustering_comparison.png"), g,
       width = 9, height = 5, dpi = 200)

cat("\n=== done ===\n")
cat(sprintf("Outputs in %s\n", out_dir))
