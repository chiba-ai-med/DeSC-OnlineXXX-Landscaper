## baseline_features.tsv + tekiyo.csv + SubGraph.tsv + Basin.tsv + E.tsv を join し、
## person 単位 wide table (Cox 等の入力) を作成。
## - 1 行 = 1 person
## - 列: 個人情報 + 観察期間 + shibou_flg + baseline 時点の (window, row_id, pattern_id, basin, energy E, PC1-7)

suppressPackageStartupMessages({
  library(data.table)
})

args <- commandArgs(trailingOnly = TRUE)
feat_path     <- args[1]   # data/baseline_features.tsv
tekiyo_path   <- args[2]   # data/tekiyo.csv
subgraph_path <- args[3]   # plot/.../Landscaper/7/SubGraph.tsv
basin_path    <- args[4]   # plot/.../Landscaper/7/Basin.tsv
energy_path   <- args[5]   # plot/.../Landscaper/7/E.tsv
out_path      <- args[6]

feat   <- fread(feat_path, sep = "\t")
tekiyo <- fread(tekiyo_path, sep = ",")
sub        <- as.integer(scan(subgraph_path, what = integer(), quiet = TRUE))
basin_reps <- as.integer(scan(basin_path,    what = integer(), quiet = TRUE))
E_vec      <- as.numeric(scan(energy_path,   what = numeric(), quiet = TRUE))

cat(sprintf("baseline_features rows: %d\n", nrow(feat)))
cat(sprintf("tekiyo rows         : %d\n", nrow(tekiyo)))
cat(sprintf("SubGraph length     : %d\n", length(sub)))
cat(sprintf("E length            : %d\n", length(E_vec)))
cat(sprintf("Basin reps          : %s\n", paste(basin_reps, collapse = ", ")))

## pattern -> basin (Major 1 or 2、それ以外は NA)
basin_assignment <- ifelse(sub %in% c(1L, 2L), sub, NA_integer_)

## tekiyo 必要列のみ
tek <- tekiyo[, .(kojin_id, birth_ym, sex_code,
                  observable_start_ym, observable_end_ym,
                  shibou_flg, kenshin_data_ari, shika_receipt_ari)]
setkey(tek, kojin_id)
setkey(feat, kojin_id)

pt <- tek[feat, on = "kojin_id"]   # left join feat <- tek（feat 側を残す）
## feat に居て tekiyo に居ない人は除外
pt <- pt[!is.na(birth_ym)]

## pattern_id は 1-based 整数
pt[, baseline_basin    := basin_assignment[baseline_pattern_id]]
pt[, baseline_energy_E := E_vec[baseline_pattern_id]]

## "YYYY/MM" -> 小数年
parse_ym <- function(s) {
  y <- suppressWarnings(as.numeric(substr(s, 1, 4)))
  m <- suppressWarnings(as.numeric(substr(s, 6, 7)))
  y + (m - 1) / 12
}
pt[, birth_year_num := parse_ym(birth_ym)]
pt[, start_year_num := parse_ym(observable_start_ym)]
pt[, end_year_num   := parse_ym(observable_end_ym)]
pt[, age_at_baseline := start_year_num - birth_year_num]
pt[, time_years      := end_year_num - start_year_num]
pt[, event           := ifelse(is.na(shibou_flg), 0L, as.integer(shibou_flg))]

## NA / 異常値ハンドリング
pt <- pt[!is.na(age_at_baseline) & !is.na(time_years) & time_years >= 0]

keep <- c(
  "kojin_id", "sex_code", "birth_ym", "age_at_baseline",
  "observable_start_ym", "observable_end_ym", "time_years",
  "shibou_flg", "event",
  "kenshin_data_ari", "shika_receipt_ari",
  "baseline_window", "baseline_row_id",
  "baseline_pattern_id", "baseline_basin", "baseline_energy_E",
  paste0("baseline_PC", 1:7)
)
out <- pt[, ..keep]

fwrite(out, out_path, sep = "\t", na = "")
cat(sprintf("\nsaved: %s  (rows = %d, cols = %d)\n",
            out_path, nrow(out), ncol(out)))

cat("\n=== summary ===\n")
cat(sprintf("Total persons      : %d\n", nrow(out)))
cat(sprintf("With shibou_flg=1  : %d (%.2f%%)\n",
            sum(out$event == 1L), 100 * mean(out$event == 1L)))
cat(sprintf("Baseline Basin 1   : %d (%.2f%%)\n",
            sum(out$baseline_basin == 1L, na.rm = TRUE),
            100 * mean(out$baseline_basin == 1L, na.rm = TRUE)))
cat(sprintf("Baseline Basin 2   : %d (%.2f%%)\n",
            sum(out$baseline_basin == 2L, na.rm = TRUE),
            100 * mean(out$baseline_basin == 2L, na.rm = TRUE)))
cat(sprintf("Baseline unassigned: %d (%.2f%%)\n",
            sum(is.na(out$baseline_basin)),
            100 * mean(is.na(out$baseline_basin))))
