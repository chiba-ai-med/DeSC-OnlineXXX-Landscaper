## 1 Basin 内の複数 pair の transition_diff TSV を読み、
## Top N (符号付き棒) を facet で並べた panel 画像を出力。

source("src/Functions.R")
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

args <- commandArgs(trailingOnly = TRUE)
out_png <- args[1]
top_n   <- as.integer(args[2])
basin_label <- args[3]   # 例: "Basin 1 (rep = pattern 32)"
tsv_paths <- args[-(1:3)]

stopifnot(length(tsv_paths) >= 1)

wrap_label <- function(icd, name, width = 28) {
  is_name <- nzchar(name) & name != icd
  raw <- ifelse(is_name, name, "(no name)")
  vapply(seq_along(raw), function(i) {
    wrapped <- paste(strwrap(raw[i], width = width), collapse = "\n")
    sprintf("%s  %s", icd[i], wrapped)
  }, character(1))
}

read_pair <- function(path) {
  bn <- sub("\\.tsv$", "", basename(path))
  m  <- regmatches(bn, regexec("pair_([0-9]+)_([0-9]+)", bn))[[1]]
  i_id <- as.integer(m[2]); j_id <- as.integer(m[3])
  df <- read.table(path, sep = "\t", header = TRUE, quote = "",
                   stringsAsFactors = FALSE, comment.char = "")
  df <- df[order(-abs(df$w)), ]
  df <- head(df, top_n)
  df$pair <- sprintf("%d -> %d", i_id, j_id)
  df$pair_order <- i_id * 10000 + j_id
  df$label <- wrap_label(df$icd10, df$en_name)
  df
}
dat <- do.call(rbind, lapply(tsv_paths, read_pair))
dat$pair <- factor(dat$pair, levels = unique(dat$pair[order(dat$pair_order)]))

## facet 内で abs(w) 順に label を順序付け（pair ごとに独立）
dat <- dat %>%
  group_by(pair) %>%
  mutate(row_id = row_number()) %>%
  ungroup()
dat$label_facet <- sprintf("%s__%s", dat$pair, dat$label)
dat$label_facet <- factor(dat$label_facet,
                          levels = rev(dat$label_facet[order(dat$pair, dat$row_id)]))

g <- ggplot(dat, aes(x = label_facet, y = w, fill = sign)) +
  geom_col(width = 0.7) +
  geom_hline(yintercept = 0, color = "gray50") +
  coord_flip() +
  facet_wrap(~ pair, scales = "free", ncol = 1) +
  scale_x_discrete(labels = function(x) sub("^.+__", "", x)) +
  scale_fill_manual(values = c("+" = "#d94a3a", "-" = "#3a6dd9", "0" = "gray70"),
                    guide = "none") +
  labs(
    title = basin_label,
    subtitle = sprintf("top %d disease per transition by |w = L Delta|", top_n),
    x = NULL, y = expression(w == L %.% Delta)
  ) +
  theme_minimal(base_size = 22) +
  theme(plot.title    = element_text(face = "bold", size = 26),
        plot.subtitle = element_text(color = "gray30", size = 18),
        strip.text    = element_text(face = "bold", size = 22),
        axis.text.y   = element_text(size = 19, lineheight = 0.85),
        axis.text.x   = element_text(size = 18),
        axis.title.x  = element_text(size = 20),
        panel.spacing = unit(1.5, "lines"),
        plot.margin   = margin(10, 14, 10, 10))

n_pair <- length(unique(dat$pair))
# 棒グラフ領域を狭めて左ラベルに幅を譲る (label width 28 で折り返し)
# canvas は print 時 (~7 inch 幅) でも読める文字サイズを優先
ggsave(out_png, plot = g, width = 12, height = 4.2 * n_pair + 1.8,
       dpi = 200, limitsize = FALSE)
cat(sprintf("saved: %s  (n_pair=%d, top_n=%d)\n", out_png, n_pair, top_n))
