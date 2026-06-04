## Cox 入院イベント解析 (Phase 5)
##   Model H1: 入院 hazard ~ basin + age + sex
##   Model H2: 入院 hazard ~ Energy E + age + sex
##   (オプション) Fine-gray competing risk (死亡を競合事象)

suppressPackageStartupMessages({
  library(data.table)
  library(survival)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
pt_path   <- args[1]
hosp_path <- args[2]
out_dir   <- args[3]

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cat("Loading person_table ...\n")
pt <- fread(pt_path)

cat("Loading hospitalization ...\n")
hp <- fread(hosp_path)
cat(sprintf("  persons with admission: %d\n", nrow(hp)))

m <- hp[pt, on = "kojin_id"]
m[is.na(n_admissions), n_admissions := 0L]

##-------------------------------------------------------------------
## 日付処理 (YYYY/MM, YYYY/MM/DD)
##-------------------------------------------------------------------
parse_ymd <- function(s) {
  # YYYY/MM/DD or YYYY/MM
  y <- suppressWarnings(as.numeric(substr(s, 1, 4)))
  mo <- suppressWarnings(as.numeric(substr(s, 6, 7)))
  da <- ifelse(nchar(s) >= 10, suppressWarnings(as.numeric(substr(s, 9, 10))), 15)
  y + (mo - 1 + (da - 1) / 30) / 12
}
m[, start_y      := parse_ymd(observable_start_ym)]
m[, end_y        := parse_ymd(observable_end_ym)]
m[, adm_y        := parse_ymd(first_admission_ymd)]
m[, has_adm      := !is.na(adm_y) & adm_y >= start_y & adm_y <= end_y]
m[, t_event      := ifelse(has_adm, adm_y - start_y, end_y - start_y)]
m[, event_adm    := as.integer(has_adm)]
m <- m[is.finite(t_event) & t_event > 0]
m[, sex_f := factor(sex_code)]
m[, basin_factor := factor(baseline_basin, levels = c(1L, 2L),
                            labels = c("Basin1", "Basin2"))]

cat(sprintf("  valid rows                   : %d\n", nrow(m)))
cat(sprintf("  with admission within obs    : %d (%.2f%%)\n",
            sum(m$event_adm == 1L), 100 * mean(m$event_adm == 1L)))

##-------------------------------------------------------------------
## Model H1: basin
##-------------------------------------------------------------------
cat("\n=== Model H1: hospitalization ~ basin + age + sex ===\n")
sub1 <- m[!is.na(basin_factor)]
fit1 <- coxph(Surv(t_event, event_adm) ~ basin_factor + age_at_baseline + sex_f,
              data = sub1)
print(summary(fit1))
m1_df <- as.data.frame(summary(fit1)$conf.int)
m1_df$term  <- rownames(m1_df)
m1_df$pvalue <- coef(summary(fit1))[, 5]
fwrite(m1_df, file.path(out_dir, "cox_hospitalization_basin.tsv"), sep = "\t")

##-------------------------------------------------------------------
## Model H2: Energy E
##-------------------------------------------------------------------
cat("\n=== Model H2: hospitalization ~ Energy E + age + sex ===\n")
sub2 <- m[is.finite(baseline_energy_E)]
sub2[, E_z := scale(baseline_energy_E)[, 1]]
fit2 <- coxph(Surv(t_event, event_adm) ~ E_z + age_at_baseline + sex_f,
              data = sub2)
print(summary(fit2))
m2_df <- as.data.frame(summary(fit2)$conf.int)
m2_df$term  <- rownames(m2_df)
m2_df$pvalue <- coef(summary(fit2))[, 5]
fwrite(m2_df, file.path(out_dir, "cox_hospitalization_energy.tsv"), sep = "\t")

##-------------------------------------------------------------------
## Kaplan-Meier (入院イベント) by Basin
##-------------------------------------------------------------------
km <- survfit(Surv(t_event, event_adm) ~ basin_factor, data = sub1)
km_df <- data.frame(
  time = km$time, surv = km$surv, lower = km$lower, upper = km$upper,
  basin = rep(c("Basin1", "Basin2"), km$strata)
)
g_km <- ggplot(km_df, aes(x = time, y = 1 - surv, color = basin, fill = basin)) +
  geom_step(linewidth = 1.0) +
  geom_ribbon(aes(ymin = 1 - upper, ymax = 1 - lower), alpha = 0.15, color = NA) +
  scale_color_manual(values = c("Basin1" = "#3a6dd9", "Basin2" = "#d94a3a")) +
  scale_fill_manual(values  = c("Basin1" = "#3a6dd9", "Basin2" = "#d94a3a")) +
  labs(title = "Cumulative incidence of hospitalization by baseline Basin",
       x = "Years from baseline", y = "Cumulative incidence",
       color = NULL, fill = NULL) +
  theme_minimal(base_size = 14)
ggsave(file.path(out_dir, "km_hospitalization_basin.png"), g_km,
       width = 8, height = 5, dpi = 200)

##-------------------------------------------------------------------
## n_admissions の分布 (count, by Basin)
##-------------------------------------------------------------------
cnt <- sub1[, .(mean_adm = mean(n_admissions),
                pct_any  = mean(n_admissions >= 1L),
                pct_3plus= mean(n_admissions >= 3L)),
            by = basin_factor]
fwrite(cnt, file.path(out_dir, "admission_counts.tsv"), sep = "\t")
cat("\n=== Admission counts per Basin ===\n")
print(cnt)

cat("\n=== done ===\n")
cat(sprintf("Outputs in %s\n", out_dir))
