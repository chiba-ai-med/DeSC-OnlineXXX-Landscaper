## ある状態 i から別状態 j への 1-bit (またはそれ以上) flip 遷移について、
## 「変動する疾患」を Loading 行列 L から推定し、軸内 z-score と相関係数 t 検定で評価する。
##
## 状態は Ising 表記 s ∈ {-1, +1}^k (Landscaper Allstates.tsv そのまま)
## w_{i->j} = L · Δ ∈ R^D,  Δ = s_j - s_i ∈ {-2, 0, +2}^k
## (A) z[d] = w[d] / sd(w)
## (B) ρ[d] = ( Σ_a Δ_a · V[d, a] · sqrt(λ_a) ) / sd(X[:, d])
##     sd(X[:, d]) = sqrt(p_d (1 - p_d)),  t = ρ √(n-2) / √(1 - ρ²)
##     ※ Δ が ±2 のため ρ の絶対値が 1 を超えうるが、相対 (符号付き寄与) の順位は不変。

source("src/Functions.R")
suppressPackageStartupMessages({
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
L_path        <- args[1]   # Eigen_vectors.csv (D × k)
allstates_path<- args[2]   # Landscaper Allstates.tsv (S × k, -1/+1)
colmean_path  <- args[3]   # ooc_cov/colmeanvec.csv (D)
eigval_path   <- args[4]   # Eigen_values.csv (k)
name_path_en  <- args[5]   # col_id_disease_name_en_small.txt
i_id          <- as.integer(args[6])
j_id          <- as.integer(args[7])
n_rows        <- as.numeric(args[8])
top_n         <- as.integer(args[9])
out_tsv       <- args[10]
out_png       <- args[11]

dir.create(dirname(out_tsv), showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(out_png), showWarnings = FALSE, recursive = TRUE)

L      <- as.matrix(read.csv(L_path, header = FALSE))           # D × k
states <- as.matrix(read.table(allstates_path, header = FALSE)) # S × k, -1/+1
p_d    <- scan(colmean_path, what = numeric(), quiet = TRUE)    # D
lam    <- scan(eigval_path,  what = numeric(), quiet = TRUE)    # k

D <- nrow(L); k <- ncol(L)
stopifnot(length(p_d) == D, length(lam) == k, ncol(states) == k)
stopifnot(i_id >= 1, i_id <= nrow(states), j_id >= 1, j_id <= nrow(states))

## 英語病名 (ない場合は ICD-10 コード)
nm_en <- read_name_table_en(name_path_en)
disease_name <- character(D)
en_name <- nm_en$en_name
ok <- !is.na(en_name) & nzchar(en_name) & en_name != "NA"
disease_name[nm_en$id[ok]] <- en_name[ok]
icd_code <- character(D)
icd_code[nm_en$id] <- nm_en$code
disease_name[!nzchar(disease_name)] <- icd_code[!nzchar(disease_name)]

## Ising 表記のまま Δ を取る ({-2, 0, +2}^k)
s_i <- states[i_id, ]
s_j <- states[j_id, ]
delta <- s_j - s_i
flipped <- which(delta != 0)
flip_label <- if (length(flipped) == 0) {
  "(no flip)"
} else {
  paste(sprintf("PC%d%s", flipped, ifelse(delta[flipped] > 0, "+", "-")), collapse = ", ")
}

## (A) 軸内 z-score
w   <- as.numeric(L %*% delta)            # D
sdw <- sd(w)
z_A <- if (sdw > 0) w / sdw else rep(0, D)
p_A <- 2 * pnorm(-abs(z_A))
q_A <- p.adjust(p_A, method = "BH")

## (B) 相関係数 → t 検定
sd_X <- sqrt(p_d * (1 - p_d))
sd_X[sd_X == 0] <- NA_real_
## ρ_signed[d] = Σ_a Δ_a · V[d, a] · sqrt(λ_a) / sd_X[d]
rho <- as.numeric(L %*% (delta * sqrt(lam))) / sd_X
rho <- pmin(pmax(rho, -1 + 1e-12), 1 - 1e-12)
df  <- n_rows - 2
t_B <- rho * sqrt(df) / sqrt(1 - rho^2)
p_B <- 2 * pt(-abs(t_B), df = df)
q_B <- p.adjust(p_B, method = "BH")

out <- data.frame(
  rank_w   = rank(-abs(w), ties.method = "first"),
  icd10    = icd_code,
  en_name  = disease_name,
  sign     = ifelse(w > 0, "+", ifelse(w < 0, "-", "0")),
  w        = w,
  z        = z_A,
  q_A      = q_A,
  rho      = rho,
  t_stat   = t_B,
  q_B      = q_B,
  stringsAsFactors = FALSE
)
out <- out[order(-abs(out$w)), ]
write.table(out, out_tsv, sep = "\t", row.names = FALSE, quote = FALSE)

## per-pair 棒グラフ (top_n、符号付き)
df_top <- head(out, top_n)
df_top$label <- sprintf("%s  %s", df_top$icd10, df_top$en_name)
df_top$label <- factor(df_top$label, levels = rev(df_top$label))

g <- ggplot(df_top, aes(x = label, y = w, fill = sign)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("+" = "#d94a3a", "-" = "#3a6dd9", "0" = "gray70"),
                    guide = "none") +
  labs(
    title    = sprintf("Pattern %d -> Pattern %d", i_id, j_id),
    subtitle = sprintf("flip: %s   |   top %d (|w|)", flip_label, nrow(df_top)),
    x = NULL, y = expression(w == L %.% Delta)
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(color = "gray30"))

ggsave(out_png, plot = g, width = 8, height = 4.5, dpi = 200)
cat(sprintf("saved: %s\nsaved: %s\nflip: %s\n", out_tsv, out_png, flip_label))
