# Argument
args <- commandArgs(trailingOnly = TRUE)
outfile <- args[1]

library(comorbidity)

# Primary: WHO ICD-10 2011 版（日本のレセプトコードと最も互換）
data("icd10_2011",  package = "comorbidity")
who <- data.frame(
  icd10_code   = icd10_2011$Code.clean,
  english_name = icd10_2011$ICD.title,
  source       = "WHO_2011",
  stringsAsFactors = FALSE
)
who <- who[!duplicated(who$icd10_code) & nzchar(who$icd10_code), ]

# Fallback: ICD-10-CM 2022 版（WHOで欠落する細分化コードを補完）
data("icd10cm_2022", package = "comorbidity")
cm <- data.frame(
  icd10_code   = icd10cm_2022$Code,
  english_name = icd10cm_2022$Description,
  source       = "ICD10CM_2022",
  stringsAsFactors = FALSE
)
cm <- cm[!duplicated(cm$icd10_code) & nzchar(cm$icd10_code), ]
cm <- cm[!cm$icd10_code %in% who$icd10_code, ]   # WHOにあるものはWHOを優先

out <- rbind(who, cm)

write.table(out, outfile, sep = "\t", quote = FALSE, row.names = FALSE,
            fileEncoding = "UTF-8")

cat(sprintf("WHO_2011: %d codes, ICD10CM_2022 (extra): %d codes, Total: %d\n",
            nrow(who), nrow(cm), nrow(out)))
