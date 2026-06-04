## Cox 比例ハザード回帰 4 model
##  Model 1: univariate per-PC (+ age + sex)
##  Model 2: multivariate PC1-7 (+ age + sex)
##  Model 3: basin (Basin 1 vs Basin 2) (+ age + sex)
##  Model 4: energy E (+ age + sex)
##
## 入力: output/person_table.tsv
## 出力: output/cox/{model{1,2,3,4}_*.tsv, summary.txt, km_basin.png, km_energy.png, forest.png}

suppressPackageStartupMessages({
  library(data.table)
  library(survival)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
pt_path <- args[1]
out_dir <- args[2]

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cat("Reading person table ...\n")
pt <- fread(pt_path)
cat(sprintf("  n = %d\n", nrow(pt)))

## 共変量整形
pt[, sex := factor(sex_code)]
pt[, basin_factor := factor(baseline_basin, levels = c(1L, 2L),
                            labels = c("Basin1", "Basin2"))]
## PC を Z 標準化 (per +1 SD HR の解釈)
for (a in 1:7) {
  pcname <- paste0("baseline_PC", a)
  pt[, (paste0("PC", a, "_z")) := scale(get(pcname))[, 1]]
}

## time / event の有効性チェック
pt <- pt[is.finite(time_years) & time_years > 0]
cat(sprintf("  valid time>0: n = %d\n", nrow(pt)))
cat(sprintf("  events       : %d (%.2f%%)\n", sum(pt$event == 1L),
            100 * mean(pt$event == 1L)))

##-------------------------------------------------------------------
## Model 3: basin + age + sex (main result)
##-------------------------------------------------------------------
cat("\n=== Model 3: basin + age + sex ===\n")
sub3 <- pt[!is.na(basin_factor)]
fit3 <- coxph(Surv(time_years, event) ~ basin_factor + age_at_baseline + sex,
              data = sub3)
print(summary(fit3))
m3_df <- as.data.frame(summary(fit3)$conf.int)
m3_df$term  <- rownames(m3_df)
m3_df$pvalue <- coef(summary(fit3))[, 5]
fwrite(m3_df, file.path(out_dir, "cox_model3_basin.tsv"), sep = "\t")

## KM curves
km3 <- survfit(Surv(time_years, event) ~ basin_factor, data = sub3)
km3_df <- data.frame(
  time      = km3$time,
  surv      = km3$surv,
  lower     = km3$lower,
  upper     = km3$upper,
  basin     = rep(c("Basin1", "Basin2"), km3$strata)
)
g_km3 <- ggplot(km3_df, aes(x = time, y = surv, color = basin, fill = basin)) +
  geom_step(linewidth = 1.0) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.15, color = NA) +
  scale_color_manual(values = c("Basin1" = "#3a6dd9", "Basin2" = "#d94a3a")) +
  scale_fill_manual(values  = c("Basin1" = "#3a6dd9", "Basin2" = "#d94a3a")) +
  labs(title = "Cox Model 3: Kaplan-Meier by baseline Basin",
       x = "Years from baseline", y = "Survival probability", color = NULL, fill = NULL) +
  theme_minimal(base_size = 14)
ggsave(file.path(out_dir, "km_basin.png"), g_km3, width = 8, height = 5, dpi = 200)

##-------------------------------------------------------------------
## Model 4: energy E + age + sex
##-------------------------------------------------------------------
cat("\n=== Model 4: energy E + age + sex ===\n")
sub4 <- pt[is.finite(baseline_energy_E)]
sub4[, E_z := scale(baseline_energy_E)[, 1]]
fit4 <- coxph(Surv(time_years, event) ~ E_z + age_at_baseline + sex,
              data = sub4)
print(summary(fit4))
m4_df <- as.data.frame(summary(fit4)$conf.int)
m4_df$term <- rownames(m4_df)
m4_df$pvalue <- coef(summary(fit4))[, 5]
fwrite(m4_df, file.path(out_dir, "cox_model4_energy.tsv"), sep = "\t")

## E を 3 分位に分けて KM
sub4[, E_tertile := cut(baseline_energy_E,
                        breaks = quantile(baseline_energy_E, probs = c(0, 1/3, 2/3, 1)),
                        labels = c("low", "mid", "high"),
                        include.lowest = TRUE)]
km4 <- survfit(Surv(time_years, event) ~ E_tertile, data = sub4)
km4_df <- data.frame(
  time = km4$time, surv = km4$surv, lower = km4$lower, upper = km4$upper,
  E_tertile = rep(c("low", "mid", "high"), km4$strata)
)
km4_df$E_tertile <- factor(km4_df$E_tertile, levels = c("low", "mid", "high"))
g_km4 <- ggplot(km4_df, aes(x = time, y = surv, color = E_tertile, fill = E_tertile)) +
  geom_step(linewidth = 1.0) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.15, color = NA) +
  scale_color_manual(values = c("low" = "#3a6dd9", "mid" = "gray50", "high" = "#d94a3a")) +
  scale_fill_manual(values  = c("low" = "#3a6dd9", "mid" = "gray50", "high" = "#d94a3a")) +
  labs(title = "Cox Model 4: Kaplan-Meier by baseline energy E (tertile)",
       x = "Years from baseline", y = "Survival probability",
       color = "E tertile", fill = "E tertile") +
  theme_minimal(base_size = 14)
ggsave(file.path(out_dir, "km_energy.png"), g_km4, width = 8, height = 5, dpi = 200)

##-------------------------------------------------------------------
## Model 1: univariate per-PC (+ age + sex)
##-------------------------------------------------------------------
cat("\n=== Model 1: univariate per-PC + age + sex ===\n")
m1_rows <- vector("list", 7)
for (a in 1:7) {
  fn <- as.formula(sprintf("Surv(time_years, event) ~ PC%d_z + age_at_baseline + sex", a))
  fit_a <- coxph(fn, data = pt)
  s_a <- summary(fit_a)
  m1_rows[[a]] <- data.frame(
    PC       = a,
    HR       = s_a$conf.int[1, 1],
    HR_lower = s_a$conf.int[1, 3],
    HR_upper = s_a$conf.int[1, 4],
    pvalue   = coef(s_a)[1, 5]
  )
}
m1_df <- do.call(rbind, m1_rows)
print(m1_df)
fwrite(m1_df, file.path(out_dir, "cox_model1_univariate_pc.tsv"), sep = "\t")

##-------------------------------------------------------------------
## Model 2: multivariate PC1-7 + age + sex
##-------------------------------------------------------------------
cat("\n=== Model 2: multivariate PC1-7 + age + sex ===\n")
fit2 <- coxph(Surv(time_years, event) ~ PC1_z + PC2_z + PC3_z + PC4_z + PC5_z + PC6_z + PC7_z +
              age_at_baseline + sex, data = pt)
print(summary(fit2))
ci <- summary(fit2)$conf.int
pv <- coef(summary(fit2))[, 5]
m2_df <- data.frame(
  term     = rownames(ci),
  HR       = ci[, 1],
  HR_lower = ci[, 3],
  HR_upper = ci[, 4],
  pvalue   = pv
)
m2_df$PC <- ifelse(grepl("^PC", m2_df$term), as.integer(sub("PC([0-9]+)_z", "\\1", m2_df$term)), NA)
fwrite(m2_df, file.path(out_dir, "cox_model2_multivariate_pc.tsv"), sep = "\t")

##-------------------------------------------------------------------
## Forest plot (Model 1 + Model 2 per-PC)
##-------------------------------------------------------------------
fp_df <- rbind(
  cbind(m1_df, model = "Univariate (Model 1)"),
  data.frame(
    PC       = m2_df$PC[!is.na(m2_df$PC)],
    HR       = m2_df$HR[!is.na(m2_df$PC)],
    HR_lower = m2_df$HR_lower[!is.na(m2_df$PC)],
    HR_upper = m2_df$HR_upper[!is.na(m2_df$PC)],
    pvalue   = m2_df$pvalue[!is.na(m2_df$PC)],
    model    = "Multivariate (Model 2)"
  )
)
fp_df$PC_label <- factor(paste0("PC", fp_df$PC), levels = paste0("PC", 1:7))

g_fp <- ggplot(fp_df, aes(x = HR, y = PC_label, color = model)) +
  geom_vline(xintercept = 1, linetype = 2, color = "gray40") +
  geom_errorbarh(aes(xmin = HR_lower, xmax = HR_upper),
                 position = position_dodge(width = 0.5), height = 0.2) +
  geom_point(position = position_dodge(width = 0.5), size = 3) +
  scale_x_log10() +
  scale_color_manual(values = c("Univariate (Model 1)" = "#d94a3a",
                                 "Multivariate (Model 2)" = "#3a6dd9")) +
  labs(title = "Per-PC HR for mortality (Cox Models 1 & 2)",
       subtitle = "per +1 SD of PC, adjusted for age and sex",
       x = "HR (95% CI), log scale", y = NULL, color = NULL) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")
ggsave(file.path(out_dir, "forest_pc.png"), g_fp, width = 9, height = 5.5, dpi = 200)

cat("\n=== done ===\n")
cat(sprintf("Outputs in %s\n", out_dir))
