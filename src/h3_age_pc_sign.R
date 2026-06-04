## H3: 加齢の二分成分の検証
## person_table の baseline_pattern_id を Ising bits に展開し、
## 年齢層別に各 PC が +1 の比率を集計。
##
## 仮説: PC2/4/6 は age と monotonic 相関、PC1/3/5/7 は非 monotonic

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(scales)
})

args <- commandArgs(trailingOnly = TRUE)
pt_path        <- args[1]
allstates_path <- args[2]
out_tsv        <- args[3]
out_png        <- args[4]

dir.create(dirname(out_tsv), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(out_png), showWarnings = FALSE, recursive = TRUE)

pt     <- fread(pt_path)
states <- as.matrix(read.table(allstates_path, header = FALSE))  # 128 × 7 (-1/+1)
k <- ncol(states)
stopifnot(k == 7)

## baseline_pattern_id (1-128) を各 PC 符号にマッピング
for (a in 1:k) {
  pt[, (paste0("PC", a, "_sign")) := states[baseline_pattern_id, a]]
}

## 年齢層 (5 年区切り、20〜100)
pt[, age_group := cut(age_at_baseline,
                      breaks = seq(0, 110, by = 5),
                      right = FALSE,
                      include.lowest = TRUE)]
pt <- pt[!is.na(age_group)]

## 各層 × 各 PC で +1 比率
sign_pos <- pt[, lapply(.SD, function(x) mean(x == 1L)),
               by = age_group, .SDcols = paste0("PC", 1:7, "_sign")]
n_per_grp <- pt[, .(n = .N), by = age_group]
setkey(sign_pos, age_group); setkey(n_per_grp, age_group)
result <- sign_pos[n_per_grp]
setcolorder(result, c("age_group", "n", paste0("PC", 1:7, "_sign")))
setorder(result, age_group)

fwrite(result, out_tsv, sep = "\t")

## age_group の中央値 (連続軸として)
parse_grp <- function(g) {
  m <- regmatches(as.character(g), regexec("\\[([0-9.]+),([0-9.]+)\\)", as.character(g)))
  vapply(m, function(x) if (length(x) >= 3) (as.numeric(x[2]) + as.numeric(x[3])) / 2 else NA_real_, numeric(1))
}
result[, age_mid := parse_grp(age_group)]

## long 形式に
long <- melt(result, id.vars = c("age_group", "age_mid", "n"),
             measure.vars = paste0("PC", 1:7, "_sign"),
             variable.name = "PC", value.name = "frac_plus")
long[, PC := factor(sub("_sign", "", PC), levels = paste0("PC", 1:7))]
long <- long[!is.na(age_mid) & age_mid >= 20 & age_mid <= 90]

## 共通軸 vs 対立軸の色分け
basin1_sign <- c(1, 1, 1, 1, 1, -1, -1)
basin2_sign <- c(-1, 1, -1, 1, -1, -1, 1)
common_axes <- which(basin1_sign == basin2_sign)   # PC2, PC4, PC6
diverging_axes <- which(basin1_sign != basin2_sign) # PC1, PC3, PC5, PC7
long[, axis_type := ifelse(as.integer(sub("PC", "", PC)) %in% common_axes,
                           "Common (PC2/4/6)", "Diverging (PC1/3/5/7)")]
long[, axis_type := factor(axis_type,
                            levels = c("Common (PC2/4/6)", "Diverging (PC1/3/5/7)"))]

## プロット
g <- ggplot(long, aes(x = age_mid, y = frac_plus, color = PC, group = PC)) +
  geom_line(linewidth = 1.0) +
  geom_point(size = 1.5) +
  facet_wrap(~ axis_type, ncol = 2) +
  scale_y_continuous(labels = percent_format(), limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(20, 90, by = 10)) +
  scale_color_brewer(palette = "Set1") +
  labs(
    title    = "H3: Per-PC +1 share across age groups",
    subtitle = "Common axes (PC2/4/6) are predicted to show monotonic age trend; diverging axes (PC1/3/5/7) are not",
    x        = "Age at baseline (mid of 5-year bin)",
    y        = "Fraction of persons with PC sign = +1",
    color    = NULL
  ) +
  theme_minimal(base_size = 14) +
  theme(plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(color = "gray30", size = 11),
        legend.position = "bottom",
        strip.text    = element_text(face = "bold"))

ggsave(out_png, g, width = 12, height = 5.5, dpi = 200)
cat(sprintf("saved: %s\nsaved: %s\n", out_tsv, out_png))
