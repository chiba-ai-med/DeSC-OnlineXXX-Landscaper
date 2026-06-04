## H2: Locomo + メタボ併存型 phenotype 仮説の検証 (軽量版)
## - Basin 1 / Basin 2 メンバーの sex 比率、age 中央値
## - 各 basin 内で sub-pattern 構成 (top 10 freq)
## - 「整形外科 sub-pattern (pat 64 / 107)」の Basin 別頻度

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(scales)
})

args <- commandArgs(trailingOnly = TRUE)
pt_path <- args[1]
out_dir <- args[2]

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

pt <- fread(pt_path)
pt <- pt[!is.na(baseline_basin)]
pt[, basin_label := paste0("Basin", baseline_basin)]
pt[, sex_label := factor(sex_code, levels = c(1, 2), labels = c("Male", "Female"))]

##-------------------------------------------------------------------
## (1) Basin 別 sex / age 分布
##-------------------------------------------------------------------
demog <- pt[, .(
  n       = .N,
  pct_female = mean(sex_code == 2, na.rm = TRUE),
  age_median = median(age_at_baseline, na.rm = TRUE),
  age_q25    = quantile(age_at_baseline, 0.25, na.rm = TRUE),
  age_q75    = quantile(age_at_baseline, 0.75, na.rm = TRUE),
  event_rate = mean(event == 1L, na.rm = TRUE),
  energy_median = median(baseline_energy_E, na.rm = TRUE)
), by = basin_label]
setorder(demog, basin_label)
fwrite(demog, file.path(out_dir, "basin_demographics.tsv"), sep = "\t")
cat("=== Basin 別 demographics ===\n")
print(demog)

##-------------------------------------------------------------------
## (2) Basin × sex の cross-table
##-------------------------------------------------------------------
sx <- pt[, .N, by = .(basin_label, sex_label)]
sx[, pct := N / sum(N), by = basin_label]
fwrite(sx, file.path(out_dir, "basin_sex.tsv"), sep = "\t")
cat("\n=== Basin × sex ===\n")
print(sx)

##-------------------------------------------------------------------
## (3) age 分布
##-------------------------------------------------------------------
pt[, age_group := cut(age_at_baseline,
                      breaks = c(0, 20, 40, 50, 60, 65, 70, 75, 80, 110),
                      right = FALSE)]
age_tbl <- pt[, .N, by = .(basin_label, age_group)]
age_tbl[, pct := N / sum(N), by = basin_label]
fwrite(age_tbl, file.path(out_dir, "basin_age.tsv"), sep = "\t")

##-------------------------------------------------------------------
## (4) Basin 内 sub-pattern 構成 (top 10 by frequency)
##-------------------------------------------------------------------
sub_top <- pt[, .(n = .N), by = .(basin_label, baseline_pattern_id)]
setorder(sub_top, basin_label, -n)
sub_top[, rank := seq_len(.N), by = basin_label]
sub_top[, pct_within_basin := n / sum(n), by = basin_label]
sub_top_10 <- sub_top[rank <= 10]
fwrite(sub_top_10, file.path(out_dir, "basin_top_subpatterns.tsv"), sep = "\t")
cat("\n=== Top 10 sub-patterns per basin ===\n")
print(sub_top_10)

##-------------------------------------------------------------------
## プロット (1): sex × Basin 棒
##-------------------------------------------------------------------
g_sex <- ggplot(sx, aes(x = basin_label, y = N, fill = sex_label)) +
  geom_col(position = "fill") +
  geom_text(aes(label = sprintf("%.1f%%", 100 * pct)),
            position = position_fill(vjust = 0.5), color = "white", size = 5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Male" = "#3a6dd9", "Female" = "#d94a3a")) +
  labs(title = "H2: Sex composition by Basin",
       x = NULL, y = "Proportion", fill = NULL) +
  theme_minimal(base_size = 14)
ggsave(file.path(out_dir, "basin_sex.png"), g_sex, width = 6, height = 5, dpi = 200)

##-------------------------------------------------------------------
## プロット (2): age density
##-------------------------------------------------------------------
g_age <- ggplot(pt[age_at_baseline >= 0 & age_at_baseline <= 100],
                aes(x = age_at_baseline, fill = basin_label, color = basin_label)) +
  geom_density(alpha = 0.35, linewidth = 0.8) +
  scale_fill_manual(values = c("Basin1" = "#3a6dd9", "Basin2" = "#d94a3a")) +
  scale_color_manual(values = c("Basin1" = "#3a6dd9", "Basin2" = "#d94a3a")) +
  labs(title = "H2: Age distribution by Basin",
       x = "Age at baseline", y = "Density", fill = NULL, color = NULL) +
  theme_minimal(base_size = 14)
ggsave(file.path(out_dir, "basin_age_density.png"), g_age, width = 7, height = 5, dpi = 200)

##-------------------------------------------------------------------
## プロット (3): top-10 sub-pattern 棒 (Basin 別 facet)
##-------------------------------------------------------------------
sub_top_10[, label := factor(baseline_pattern_id,
                              levels = unique(baseline_pattern_id))]
g_sub <- ggplot(sub_top_10,
                aes(x = reorder(factor(baseline_pattern_id), -n), y = pct_within_basin,
                    fill = basin_label)) +
  geom_col() +
  facet_wrap(~ basin_label, scales = "free_x") +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Basin1" = "#3a6dd9", "Basin2" = "#d94a3a"),
                    guide = "none") +
  labs(title = "H2: Top 10 sub-patterns per Basin",
       x = "Pattern ID", y = "Share within basin") +
  theme_minimal(base_size = 14)
ggsave(file.path(out_dir, "basin_top_subpatterns.png"), g_sub,
       width = 10, height = 5, dpi = 200)

cat("\n=== done ===\n")
cat(sprintf("Outputs in %s\n", out_dir))
