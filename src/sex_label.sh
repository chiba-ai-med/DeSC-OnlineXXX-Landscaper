awk -F, '
  NR==FNR {
    if (FNR > 1) sex[$1] = $3   # 1列目: kojin_id → 3列目: sex_code
    next
  }
  {
    id = ""
    if (match($1, /_[0-9]+/)) {                 # "_数字" を探す
      id = substr($1, RSTART + 1, RLENGTH - 1)  # "_" を除いてIDだけに
    }
    if (id == "" || sex[id] == "") print "NA"
    else                             print sex[id]
  }
' data/tekiyo.csv data/row_id_number_small.txt > data/sex_label.txt
