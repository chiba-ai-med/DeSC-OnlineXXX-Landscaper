source("src/Functions.R")

# Argument
args <- commandArgs(trailingOnly = TRUE)
infile1 <- args[1]
infile2 <- args[2]
outfile <- args[3]

# Load
pval <- read.csv(infile1, header=FALSE)
disease_name <- read.csv(infile2, header=TRUE)[, 3]

# Setting
outdir <- dirname(outfile)
dir.create(outdir, showWarnings = FALSE)

colors <- colorRampPalette(rev(brewer.pal(9, "YlOrRd")))(ncol(pval))

# Plot
lapply(seq(nrow(pval)), function(i){
  weights <- -log10(as.numeric(pval[i, ]))
  weights[!is.finite(weights)] <- 0  # 0 や NA の安全対策

  index <- order(weights, decreasing = TRUE)[1:20]

  # 値の大小で色付け
  pal <- colorRampPalette(rev(brewer.pal(9, "YlOrRd")))
  colmap <- pal(length(index))
  cols   <- colmap[rank(-weights[index], ties.method = "first")]

  # ラベル（日本語）を幅10で折り返し
  labels <- wrap_jp(disease_name[index], width = 20)

  filename <- file.path(outdir, sprintf("pattern_%d.png", i))
  png(filename, width = 800, height = 800, type = "cairo")  # ← Cairo で文字化け回避
  par(family = "jp")                                         # ← 登録した日本語フォントを使用
  tagcloud(labels, weights = weights[index], col = cols)
  dev.off()
})

# Save
file.create(outfile)
