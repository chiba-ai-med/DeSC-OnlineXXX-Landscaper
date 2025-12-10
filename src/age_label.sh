awk -F, '
  NR==FNR {
    if (FNR > 1) birth[$1] = $2   # 1列目: kojin_id → 2列目: birth_ym
    next
  }
  {
    id = ""
    if (match($1, /_[0-9]+/)) {           # 例: "2014/04..2014/09_662432"
      id = substr($1, RSTART + 1, RLENGTH - 1)  # 先頭の "_" を除く
    }
    if (id == "" || birth[id] == "") print "NA"
    else                               print birth[id]
  }
' data/tekiyo.csv data/row_id_number_small.txt > data/age_label.txt
