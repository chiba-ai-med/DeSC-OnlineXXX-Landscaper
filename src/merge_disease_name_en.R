# Arguments
args <- commandArgs(trailingOnly = TRUE)
infile_master <- args[1]   # data/col_id_disease_name_small.txt   (code,id,ja_name)
infile_en     <- args[2]   # data/who_icd10_en.tsv               (icd10_code\tenglish_name\tsource)
outfile_merge <- args[3]   # data/col_id_disease_name_en_small.txt (code\tid\tja_name\ten_name\tsource)
outfile_miss  <- args[4]   # data/missing_en_codes.tsv           (code\tid\tja_name)

source("src/Functions.R")

# 既存マスタ（カンマ多数で壊れている可能性に強い read_name_table_split2 を流用）
master <- read_name_table_split2(infile_master, n_expected = 0L)
colnames(master)[3] <- "ja_name"

# WHO/CM 英語マスタ（TSV）
en <- read.table(infile_en, sep = "\t", header = TRUE, quote = "",
                 stringsAsFactors = FALSE, encoding = "UTF-8",
                 comment.char = "")

# Left join: master.code -> en.icd10_code
merged <- merge(master, en, by.x = "code", by.y = "icd10_code",
                all.x = TRUE, sort = FALSE)
merged <- merged[order(merged$id), ]
colnames(merged)[colnames(merged) == "english_name"] <- "en_name"

# 欠損は "NA" 文字列で埋める（タグクラウド側で見分けやすく）
merged$en_name[is.na(merged$en_name)] <- "NA"
merged$source [is.na(merged$source) ] <- "NA"

write.table(merged[, c("code", "id", "ja_name", "en_name", "source")],
            outfile_merge, sep = "\t", quote = FALSE, row.names = FALSE,
            fileEncoding = "UTF-8")

# 欠損リスト
missing <- merged[merged$en_name == "NA", c("code", "id", "ja_name")]
write.table(missing, outfile_miss, sep = "\t", quote = FALSE, row.names = FALSE,
            fileEncoding = "UTF-8")

cat(sprintf("Total: %d, Matched: %d (WHO_2011: %d, ICD10CM_2022: %d), Missing: %d\n",
            nrow(merged),
            sum(merged$en_name != "NA"),
            sum(merged$source == "WHO_2011"),
            sum(merged$source == "ICD10CM_2022"),
            nrow(missing)))
