## H4 dim sensitivity: dim=2..7 の ELA で n_basin / n_states を集計
##
## 入力: plot/exact_ooc_pca_sparse_bincoo/Landscaper/{dim}/Basin.tsv, Allstates.tsv, SubGraph.tsv
## 出力: output/h4/dim_sensitivity.tsv + png

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
lscaper_root <- args[1]
out_tsv      <- args[2]
out_png      <- args[3]

dir.create(dirname(out_tsv), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(out_png), showWarnings = FALSE, recursive = TRUE)

dims <- c(2, 3, 4, 5, 6, 7)
rows <- list()
for (d in dims) {
  base <- file.path(lscaper_root, as.character(d))
  basin_path <- file.path(base, "Basin.tsv")
  states_path <- file.path(base, "Allstates.tsv")
  sub_path   <- file.path(base, "SubGraph.tsv")
  if (!file.exists(basin_path)) next
  n_basin  <- length(scan(basin_path, what = integer(), quiet = TRUE))
  n_states <- nrow(read.table(states_path, header = FALSE))
  sub <- as.integer(scan(sub_path, what = integer(), quiet = TRUE))
  n_assigned_major <- sum(sub %in% c(1L, 2L))
  rows[[length(rows) + 1]] <- data.frame(
    dim = d, n_states = n_states, n_basin = n_basin,
    n_assigned_to_major = n_assigned_major
  )
}
df <- do.call(rbind, rows)
fwrite(df, out_tsv, sep = "\t")
print(df)

## plot
g <- ggplot(df, aes(x = factor(dim))) +
  geom_col(aes(y = n_states), fill = "gray70", alpha = 0.5) +
  geom_text(aes(y = n_states + 5,
                label = sprintf("states=%d", n_states)),
            color = "gray30", size = 4) +
  geom_point(aes(y = n_basin * 20), color = "#d94a3a", size = 5) +
  geom_text(aes(y = n_basin * 20 + 8,
                label = sprintf("n_basin=%d", n_basin)),
            color = "#d94a3a", size = 4.5, fontface = "bold") +
  scale_y_continuous(name = "Number of states (gray bars)",
                     sec.axis = sec_axis(~ . / 20, name = "Number of major basins (red dots)")) +
  labs(title = "H4: dim sensitivity of ELA",
       subtitle = "Two major basins emerge at dim >= 6",
       x = "PCA dim (k)") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"),
        axis.title.y.right = element_text(color = "#d94a3a"))
ggsave(out_png, g, width = 8, height = 5, dpi = 200)
cat(sprintf("saved: %s\nsaved: %s\n", out_tsv, out_png))
