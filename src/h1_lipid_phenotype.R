## H1: 脂質異常の 2 phenotype (FH 型 vs Triglyceride+糖尿+肝型) 仮説の検証
## - 健診データ (exam_interview.csv) から LDL/TG/HDL/HbA1c/GOT/GPT/BMI を抽出
## - 各 person 最古の exam を 1 件採用 (baseline に近い)
## - Basin 1 中心 (pat 32) vs sub 96 (PC7 flip = 純高コレ side) で比較
## - Basin 1 全体 vs Basin 2 全体でも参考比較
## - 仮説: pat 32 (Basin 1 中心) で TG・HbA1c・GPT 高、LDL 並み or 低
##         pat 96 (sub) で LDL 高、TG・HbA1c 並み or 低

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
exam_path <- args[1]
pt_path   <- args[2]
out_dir   <- args[3]

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cat("Loading exam_interview.csv ... (this may take a few minutes)\n")
ex <- fread(exam_path,
            select = c("kojin_id", "exam_ymd", "bmi",
                       "chusei_shibou_kashi", "chusei_shibou_shigai", "chusei_shibou_other",
                       "hdl_kashi", "hdl_shigai", "hdl_other",
                       "ldl_kashi", "ldl_shigai", "ldl_other", "ldl_keisanhou",
                       "got_shigai", "got_other",
                       "gpt_shigai", "gpt_other",
                       "gamma_gt_kashi", "gamma_gt_other",
                       "kuufukuji_ketto_kashi", "kuufukuji_ketto_shigai", "kuufukuji_ketto_other",
                       "hba1c_ngsp_meneki", "hba1c_ngsp_hplc", "hba1c_ngsp_kousohou",
                       "hba1c_ngsp_other",
                       "systolic_blood_pressure1", "diastolic_blood_pressure1",
                       "e_gfr"))
cat(sprintf("  loaded: %d rows\n", nrow(ex)))

## 同一 person 複数行 → 最古を採用 (baseline に近い)
setorder(ex, kojin_id, exam_ymd)
ex <- ex[, .SD[1], by = kojin_id]
cat(sprintf("  unique persons (oldest exam): %d\n", nrow(ex)))

## 並列カラム (kashi / shigai / other / keisanhou) を集約 (max を採用、すべて NA なら NA)
maxna <- function(...) {
  v <- pmax(..., na.rm = TRUE)
  v[is.infinite(v)] <- NA_real_
  v
}
ex[, TG    := maxna(chusei_shibou_kashi, chusei_shibou_shigai, chusei_shibou_other)]
ex[, HDL   := maxna(hdl_kashi, hdl_shigai, hdl_other)]
ex[, LDL   := maxna(ldl_kashi, ldl_shigai, ldl_other, ldl_keisanhou)]
ex[, GOT   := maxna(got_shigai, got_other)]
ex[, GPT   := maxna(gpt_shigai, gpt_other)]
ex[, GGT   := maxna(gamma_gt_kashi, gamma_gt_other)]
ex[, FBS   := maxna(kuufukuji_ketto_kashi, kuufukuji_ketto_shigai, kuufukuji_ketto_other)]
ex[, HbA1c := maxna(hba1c_ngsp_meneki, hba1c_ngsp_hplc, hba1c_ngsp_kousohou, hba1c_ngsp_other)]
ex[, SBP   := as.numeric(systolic_blood_pressure1)]
ex[, DBP   := as.numeric(diastolic_blood_pressure1)]
ex[, eGFR  := as.numeric(e_gfr)]

ex <- ex[, .(kojin_id, BMI = bmi, TG, HDL, LDL, GOT, GPT, GGT, FBS, HbA1c, SBP, DBP, eGFR)]

cat("Joining with person_table ...\n")
pt <- fread(pt_path,
            select = c("kojin_id", "baseline_basin", "baseline_pattern_id", "sex_code",
                       "age_at_baseline", "baseline_energy_E"))
m <- ex[pt, on = "kojin_id"]
m <- m[!is.na(baseline_basin) & !is.na(BMI)]   # 健診の取れた person のみ
cat(sprintf("  persons with exam + basin: %d\n", nrow(m)))

m[, basin_label := paste0("Basin", baseline_basin)]

## グループ作成:
##   group1: Basin 1 中心 = pat 32
##   group2: sub 96 = Basin 1 内 PC7 flip
##   group3: Basin 2 全体 (chronic metabolic)
m[, group := NA_character_]
m[baseline_pattern_id == 32L,  group := "Basin1_center (pat 32)"]
m[baseline_pattern_id == 96L,  group := "Basin1_sub96 (PC7 flip)"]
m[baseline_basin == 2L,         group := "Basin2_all"]
sub <- m[!is.na(group)]
sub[, group := factor(group,
                       levels = c("Basin1_center (pat 32)",
                                  "Basin1_sub96 (PC7 flip)",
                                  "Basin2_all"))]
cat(sprintf("  group sizes:\n"))
print(table(sub$group))

##-------------------------------------------------------------------
## 群別 統計サマリー
##-------------------------------------------------------------------
vars <- c("BMI", "TG", "HDL", "LDL", "GOT", "GPT", "GGT", "FBS", "HbA1c", "SBP", "DBP", "eGFR")
summ <- sub[, lapply(.SD, function(x) {
  paste0(sprintf("%.1f", median(x, na.rm = TRUE)), " [",
         sprintf("%.1f", quantile(x, 0.25, na.rm = TRUE)), ",",
         sprintf("%.1f", quantile(x, 0.75, na.rm = TRUE)), "] (n=",
         sum(!is.na(x)), ")")
}), by = group, .SDcols = vars]
fwrite(summ, file.path(out_dir, "lipid_summary.tsv"), sep = "\t")
cat("\n=== Median [Q25, Q75] (n) per group ===\n")
print(summ)

##-------------------------------------------------------------------
## ペアワイズ Wilcoxon (Basin1_center vs Basin1_sub96 と Basin1_center vs Basin2_all)
##-------------------------------------------------------------------
pw_rows <- list()
groups_pair <- list(
  c("Basin1_center (pat 32)", "Basin1_sub96 (PC7 flip)"),
  c("Basin1_center (pat 32)", "Basin2_all")
)
for (var in vars) {
  for (p in groups_pair) {
    x <- sub[group == p[1] & !is.na(get(var)), get(var)]
    y <- sub[group == p[2] & !is.na(get(var)), get(var)]
    if (length(x) >= 30 && length(y) >= 30) {
      ## 巨大サンプルでの Wilcoxon は重いので、median 差 + 標準誤差で代用
      ## (n が 100k 超なら p 値ほぼ 0 で意味なし)
      delta <- median(y, na.rm = TRUE) - median(x, na.rm = TRUE)
      n_x <- length(x); n_y <- length(y)
      pw_rows[[length(pw_rows) + 1]] <- data.frame(
        variable = var,
        contrast = sprintf("%s vs %s", p[2], p[1]),
        median_diff = delta,
        n_x = n_x, n_y = n_y
      )
    }
  }
}
pw_df <- do.call(rbind, pw_rows)
fwrite(pw_df, file.path(out_dir, "lipid_pairwise.tsv"), sep = "\t")

##-------------------------------------------------------------------
## Violin plot (主要変数のみ)
##-------------------------------------------------------------------
sub_long <- melt(sub[, c("group", vars), with = FALSE],
                 id.vars = "group", variable.name = "marker", value.name = "value")
sub_long <- sub_long[!is.na(value)]

## 外れ値カットオフ (per marker 99 percentile)
cutoffs <- sub_long[, .(cut = quantile(value, 0.995, na.rm = TRUE)), by = marker]
sub_long <- sub_long[cutoffs, on = "marker"][value <= cut]

g <- ggplot(sub_long, aes(x = group, y = value, fill = group)) +
  geom_violin(scale = "width", trim = TRUE, alpha = 0.7, color = NA) +
  geom_boxplot(width = 0.15, outlier.shape = NA, alpha = 0.6,
               position = position_dodge(width = 0.9)) +
  facet_wrap(~ marker, scales = "free_y", ncol = 4) +
  scale_fill_manual(values = c("Basin1_center (pat 32)" = "#3a6dd9",
                                "Basin1_sub96 (PC7 flip)" = "#7d4ad9",
                                "Basin2_all" = "#d94a3a"),
                    guide = "none") +
  labs(title = "H1: Lipid / liver / glucose markers by phenotype",
       subtitle = "Hypothesis: pat 32 (Basin 1) = Triglyceride+糖尿+肝 / pat 96 = LDL only / Basin 2 = chronic metabolic",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1),
        strip.text = element_text(face = "bold"))

ggsave(file.path(out_dir, "lipid_violin.png"), g, width = 14, height = 10, dpi = 200)

cat("\n=== done ===\n")
cat(sprintf("Outputs in %s\n", out_dir))
