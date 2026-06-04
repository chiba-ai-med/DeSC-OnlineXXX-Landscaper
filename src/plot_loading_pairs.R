## PC1〜PCk の Loading 行列 L (D × k) を 7C2 = 21 ペアで散布図にして並べる。
## 各セル内で、PC 軸 i または j の軸内 z-score 検定 (BH 補正済み q < 0.05) で
## 有意になった ICD-10 を **赤** で塗り、上位 top_n_label 件に ICD-10 コードをラベル付与。

source("src/Functions.R")
suppressPackageStartupMessages({
  library(ggplot2)
  library(ggrepel)
  library(dplyr)
})

args <- commandArgs(trailingOnly = TRUE)
L_path        <- args[1]   # Eigen_vectors.csv (D × k)
name_path_en  <- args[2]   # data/col_id_disease_name_en_small.txt
out_png       <- args[3]
top_n_label   <- if (length(args) >= 4) as.integer(args[4]) else 8L
q_thresh      <- if (length(args) >= 5) as.numeric(args[5]) else 0.05

dir.create(dirname(out_png), showWarnings = FALSE, recursive = TRUE)

L <- as.matrix(read.csv(L_path, header = FALSE))
D <- nrow(L); k <- ncol(L)

nm <- read_name_table_en(name_path_en)
icd <- character(D)
icd[nm$id] <- nm$code

## 軸ごと: 軸内 z-score + 両側 p + BH
z_mat <- matrix(0, D, k)
q_mat <- matrix(1, D, k)
for (a in seq_len(k)) {
  s <- sd(L[, a])
  if (s > 0) {
    z_mat[, a] <- L[, a] / s
    p <- 2 * pnorm(-abs(z_mat[, a]))
    q_mat[, a] <- p.adjust(p, method = "BH")
  }
}

## 7C2 ペアの long 形式 (facet_wrap で並べる)
combos <- combn(k, 2)
pair_levels <- vapply(seq_len(ncol(combos)),
                      function(kk) sprintf("PC%d vs PC%d", combos[1, kk], combos[2, kk]),
                      character(1))

## 下三角 (j > i): x 軸 = PCi、y 軸 = PCj
pc_levels <- sprintf("PC%d", seq_len(k))
df_long <- do.call(rbind, lapply(seq_len(ncol(combos)), function(kk) {
  i <- combos[1, kk]; j <- combos[2, kk]
  sig <- q_mat[, i] < q_thresh | q_mat[, j] < q_thresh
  score <- sqrt(L[, i]^2 + L[, j]^2)
  data.frame(
    pc_x  = factor(sprintf("PC%d", i), levels = pc_levels),
    pc_y  = factor(sprintf("PC%d", j), levels = pc_levels),
    x     = L[, i],
    y     = L[, j],
    icd   = icd,
    sig   = sig,
    score = score,
    stringsAsFactors = FALSE
  )
}))

df_long <- df_long %>%
  group_by(pc_x, pc_y) %>%
  mutate(rank  = rank(-score, ties.method = "first"),
         label = ifelse(sig & rank <= top_n_label, icd, "")) %>%
  ungroup()

g <- ggplot(df_long, aes(x = x, y = y)) +
  geom_hline(yintercept = 0, color = "gray85", linewidth = 0.3) +
  geom_vline(xintercept = 0, color = "gray85", linewidth = 0.3) +
  geom_point(aes(color = sig), size = 0.7, alpha = 0.55) +
  geom_text_repel(aes(label = label),
                  size = 3.0, max.overlaps = Inf,
                  segment.size = 0.25, segment.alpha = 0.5,
                  min.segment.length = 0, seed = 1234,
                  color = "black") +
  facet_grid(rows = vars(pc_y), cols = vars(pc_x),
             scales = "free", drop = FALSE, switch = "both") +
  scale_color_manual(values = c("FALSE" = "gray70", "TRUE" = "#d94a3a"),
                     labels = c("FALSE" = "n.s.", "TRUE" = sprintf("BH q < %g", q_thresh)),
                     name = NULL) +
  labs(
    title    = "Loading pair plot (lower triangle, PC1〜PC7)",
    subtitle = sprintf("colored by per-axis z-score test (BH q < %g); labeled = top %d |L| within significant set",
                       q_thresh, top_n_label),
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title       = element_text(face = "bold", size = 16),
        plot.subtitle    = element_text(color = "gray30", size = 11),
        strip.text       = element_text(face = "bold", size = 13),
        strip.placement  = "outside",
        panel.spacing    = unit(0.6, "lines"),
        panel.border     = element_rect(color = "gray80", fill = NA, linewidth = 0.3),
        axis.text        = element_text(size = 8),
        legend.position  = "bottom",
        legend.text      = element_text(size = 12))

ggsave(out_png, plot = g, width = 22, height = 22, dpi = 200)
cat(sprintf("saved: %s\n", out_png))
