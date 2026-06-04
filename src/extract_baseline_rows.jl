## row_id_number_small.txt をストリーム読みして、各 kojin_id の最初の row_id を抽出
## 入力 1 行: "YYYY/MM..YYYY/MM_kojin_id row_id"  (空白区切り)
## 出力: kojin_id\tbaseline_row_id\tbaseline_window  (TSV、kojin_id 昇順)

infile  = ARGS[1]   # data/row_id_number_small.txt
outfile = ARGS[2]   # data/baseline_row.tsv

baseline = Dict{Int, Tuple{Int, String}}()  # kojin_id -> (min row_id, window)

println("Streaming $infile ...")
open(infile, "r") do io
    line_no = 0
    for line in eachline(io)
        line_no += 1
        parts = split(line, ' ')
        length(parts) == 2 || continue
        win_kojin = parts[1]
        row_id_str = parts[2]
        ki = findlast(==('_'), win_kojin)
        ki === nothing && continue
        window = win_kojin[1:(ki-1)]
        kojin_id = parse(Int, win_kojin[(ki+1):end])
        row_id   = parse(Int, row_id_str)
        cur = get(baseline, kojin_id, nothing)
        if cur === nothing || row_id < cur[1]
            baseline[kojin_id] = (row_id, window)
        end
        if line_no % 20_000_000 == 0
            println("  line $line_no, |unique kojin| = $(length(baseline))")
        end
    end
    println("Total lines: $line_no")
end

println("Writing $(length(baseline)) entries to $outfile ...")
open(outfile, "w") do out
    println(out, "kojin_id\tbaseline_row_id\tbaseline_window")
    for (k, (r, w)) in sort!(collect(baseline), by = x -> x[1])
        println(out, "$k\t$r\t$w")
    end
end
println("done")
