source("src/Functions.R")
library(ggplot2)
library(ggrepel)

## Args
args <- commandArgs(trailingOnly = TRUE)
infile_eigen <- args[1]   # output/exact_ooc_pca_sparse_bincoo/{dim}/Eigen_vectors.csv
infile_name  <- args[2]   # data/col_id_disease_name_en_small.txt
outfile      <- args[3]   # plot/.../loading_pc1_pc2.png
top_n        <- if (length(args) >= 4) as.integer(args[4]) else 20L

## Load loadings (各行が ICD-10 コード id 1..n に対応)
V <- as.matrix(read.csv(infile_eigen, header = FALSE))

## Load 英語名マスタ
nm <- read_name_table_en(infile_name)
stopifnot("id order broken" = identical(sort(nm$id), seq_len(nrow(nm))))
nm <- nm[order(nm$id), ]

if (nrow(V) != nrow(nm)) {
  stop(sprintf("Row mismatch: Eigen_vectors=%d rows, name table=%d rows",
               nrow(V), nrow(nm)))
}

## 上位寄与: |PC1| + |PC2| 大
score   <- abs(V[, 1]) + abs(V[, 2])
top_idx <- order(score, decreasing = TRUE)[seq_len(top_n)]

## ラベル: en_name 優先、欠損は ICD-10 コードで代替
labels <- nm$en_name[top_idx]
labels[is.na(labels)] <- ""
miss <- !nzchar(labels) | labels == "NA" | labels == "(NA)"
labels[miss] <- nm$code[top_idx][miss]

## data.frame 準備
df_all <- data.frame(PC1 = V[, 1], PC2 = V[, 2])
df_top <- data.frame(PC1 = V[top_idx, 1], PC2 = V[top_idx, 2], label = labels)

## ggplot + ggrepel
p <- ggplot(df_all, aes(PC1, PC2)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray60") +
  geom_point(color = "#5b8cd9", alpha = 0.35, size = 0.6) +
  geom_point(data = df_top, color = "red", size = 2.0) +
  geom_text_repel(
    data = df_top,
    aes(label = label),
    color = "red",
    size = 4.0,
    max.overlaps = Inf,
    box.padding = 0.6,
    point.padding = 0.3,
    min.segment.length = 0,
    segment.color = "gray40",
    segment.alpha = 0.6,
    seed = 1234
  ) +
  labs(
    x = "PC1 loading",
    y = "PC2 loading",
    title = sprintf("Loading scatter (PC1 vs PC2), top %d labeled (|PC1|+|PC2|)", top_n)
  ) +
  theme_bw(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5),
    panel.grid.minor = element_blank()
  )

ggsave(outfile, plot = p, width = 11, height = 11, dpi = 220, units = "in")

cat(sprintf("saved: %s (n=%d points, top_n=%d labeled)\n",
            outfile, nrow(V), top_n))
