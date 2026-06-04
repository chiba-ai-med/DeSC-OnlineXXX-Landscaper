## ATC group ごとに Basin 1 vs Basin 2 の処方 OR を計算 (H1 statin/antidiabetic, H2 bisphosphonate, H5 inflammation)
##
## 入力: data/person_atc.tsv, output/person_table.tsv
## 出力: output/atc_or/{tsv, png}

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(scales)
})

args <- commandArgs(trailingOnly = TRUE)
atc_path <- args[1]
pt_path  <- args[2]
out_dir  <- args[3]

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cat("Loading ATC flags ...\n")
atc <- fread(atc_path)
cat(sprintf("  persons with target ATC: %d\n", nrow(atc)))

cat("Loading person_table ...\n")
pt <- fread(pt_path,
            select = c("kojin_id", "baseline_basin", "baseline_pattern_id",
                       "sex_code", "age_at_baseline", "event"))

## ATC flag が無い person は 0 で埋める (= 当該薬剤を一度も処方されなかった)
all_persons <- pt[, .(kojin_id, baseline_basin, baseline_pattern_id, sex_code, age_at_baseline, event)]
m <- atc[all_persons, on = "kojin_id"]
atc_cols <- c("atc_NSAIDs", "atc_Steroid", "atc_Antihistamine",
              "atc_Diabetes", "atc_Statin", "atc_Osteoporosis")
for (cn in atc_cols) {
  m[[cn]][is.na(m[[cn]])] <- 0L
}
m <- m[!is.na(baseline_basin)]
m[, basin_label := paste0("Basin", baseline_basin)]
cat(sprintf("  persons with basin assignment: %d\n", nrow(m)))

##-------------------------------------------------------------------
## 処方率 (各 ATC × Basin)
##-------------------------------------------------------------------
rates <- m[, lapply(.SD, function(x) mean(x == 1L)),
           by = basin_label, .SDcols = atc_cols]
setorder(rates, basin_label)
fwrite(rates, file.path(out_dir, "atc_rates_by_basin.tsv"), sep = "\t")
cat("\n=== Prescription rates per Basin ===\n")
print(rates)

##-------------------------------------------------------------------
## logistic regression: ATC ~ basin + age + sex
##-------------------------------------------------------------------
or_rows <- list()
m[, basin_factor := factor(basin_label, levels = c("Basin1", "Basin2"))]
m[, sex_f := factor(sex_code)]
for (cn in atc_cols) {
  fit <- glm(as.formula(sprintf("%s ~ basin_factor + age_at_baseline + sex_f", cn)),
             data = m, family = binomial())
  s <- summary(fit)
  ci <- suppressMessages(confint.default(fit))
  or_rows[[length(or_rows) + 1]] <- data.frame(
    atc        = sub("^atc_", "", cn),
    OR         = exp(coef(fit)["basin_factorBasin2"]),
    OR_lower   = exp(ci["basin_factorBasin2", 1]),
    OR_upper   = exp(ci["basin_factorBasin2", 2]),
    pvalue     = s$coefficients["basin_factorBasin2", 4]
  )
}
or_df <- do.call(rbind, or_rows)
fwrite(or_df, file.path(out_dir, "atc_or_basin2vs1.tsv"), sep = "\t")
cat("\n=== OR (Basin 2 vs Basin 1, age/sex adjusted) ===\n")
print(or_df)

##-------------------------------------------------------------------
## Forest plot (Basin 2 vs Basin 1)
##-------------------------------------------------------------------
or_df$atc <- factor(or_df$atc,
                    levels = rev(c("NSAIDs", "Steroid", "Antihistamine",
                                   "Diabetes", "Statin", "Osteoporosis")))
g_or <- ggplot(or_df, aes(x = OR, y = atc)) +
  geom_vline(xintercept = 1, linetype = 2, color = "gray40") +
  geom_errorbarh(aes(xmin = OR_lower, xmax = OR_upper), height = 0.2,
                 color = "#3a6dd9") +
  geom_point(size = 3.5, color = "#3a6dd9") +
  scale_x_log10() +
  labs(title = "Prescription OR: Basin 2 vs Basin 1 (age, sex adjusted)",
       subtitle = "Right of 1 = more prescribed in Basin 2",
       x = "OR (95% CI), log scale", y = NULL) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"))
ggsave(file.path(out_dir, "atc_or_basin2vs1.png"), g_or,
       width = 8, height = 5, dpi = 200)

##-------------------------------------------------------------------
## 特定 sub-pattern 比較 (Basin 1 中心 pat 32 vs sub 96 vs Basin 2 sub 107)
##-------------------------------------------------------------------
m[, pat_group := NA_character_]
m[baseline_pattern_id == 32L,  pat_group := "pat32 (Basin1 rep)"]
m[baseline_pattern_id == 96L,  pat_group := "pat96 (PC7 flip)"]
m[baseline_pattern_id == 107L, pat_group := "pat107 (PC6 flip)"]
m[baseline_pattern_id == 75L,  pat_group := "pat75 (Basin2 rep)"]

sub <- m[!is.na(pat_group)]
sub[, pat_group := factor(pat_group,
                           levels = c("pat32 (Basin1 rep)", "pat96 (PC7 flip)",
                                      "pat75 (Basin2 rep)", "pat107 (PC6 flip)"))]
pat_rates <- sub[, lapply(.SD, function(x) mean(x == 1L)),
                 by = pat_group, .SDcols = atc_cols]
setorder(pat_rates, pat_group)
fwrite(pat_rates, file.path(out_dir, "atc_rates_by_pattern.tsv"), sep = "\t")
cat("\n=== Prescription rates per key pattern ===\n")
print(pat_rates)

pat_long <- melt(pat_rates, id.vars = "pat_group",
                 variable.name = "atc", value.name = "rate")
pat_long[, atc := sub("^atc_", "", atc)]
g_pat <- ggplot(pat_long, aes(x = pat_group, y = rate, fill = atc)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Prescription rate by key pattern",
       x = NULL, y = "Share of persons prescribed", fill = "ATC") +
  theme_minimal(base_size = 13) +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
ggsave(file.path(out_dir, "atc_rates_by_pattern.png"), g_pat,
       width = 9, height = 5, dpi = 200)

cat("\n=== done ===\n")
cat(sprintf("Outputs in %s\n", out_dir))
