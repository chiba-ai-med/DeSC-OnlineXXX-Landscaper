## Random walk trajectory の可視化
## 横軸: step、縦軸: pattern_id、色: SubGraph (basin)
## 入力 trajectory は ELA のステップ数なので、サブサンプリングして描画

args <- commandArgs(trailingOnly = TRUE)
traj_path     <- args[1]   # output/random_walk/{dim}/trajectory.tsv
subgraph_path <- args[2]   # plot/.../Landscaper/{dim}/SubGraph.tsv
e_path        <- args[3]   # plot/.../Landscaper/{dim}/E.tsv
outfile       <- args[4]   # plot/random_walk/{dim}/trajectory.png
n_show        <- if (length(args) >= 5) as.integer(args[5]) else 5000L

traj <- as.integer(scan(traj_path, what = integer(), quiet = TRUE))
sub  <- as.integer(scan(subgraph_path, what = integer(), quiet = TRUE))
E    <- as.numeric(scan(e_path, what = double(), quiet = TRUE))

n_pat <- length(E)
# SubGraph は 125 行（3 パターン欠落）。欠損には NA を割り当て
sub_full <- rep(NA_integer_, n_pat)
sub_full[seq_along(sub)] <- sub

# 表示用にサブサンプリング（先頭から）
take <- seq_len(min(n_show, length(traj)))
t_step <- take
t_pid  <- traj[take]

dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)
png(outfile, width = 2400, height = 1400, type = "cairo", res = 200)
op <- par(no.readonly = TRUE); on.exit(par(op), add = TRUE)
par(mar = c(4.5, 4.5, 3.0, 1.0))

# 色: basin 1 = 青、basin 2 = 赤、unknown = 灰
col_basin <- ifelse(is.na(sub_full[t_pid]), "gray60",
                    ifelse(sub_full[t_pid] == 1L, "#3a6dd9", "#d94a3a"))

plot(t_step, t_pid,
     pch = 19, cex = 0.35, col = col_basin,
     xlab = "Step", ylab = "Pattern id",
     ylim = c(0.5, n_pat + 0.5),
     main = sprintf("ELA random walk trajectory (first %d steps)", length(take)))

# 凡例
legend("topright", legend = c("Basin 1", "Basin 2", "unassigned"),
       col = c("#3a6dd9", "#d94a3a", "gray60"),
       pch = 19, pt.cex = 0.8, bty = "n")

dev.off()
cat(sprintf("saved: %s\n", outfile))
