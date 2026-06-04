## receipt.csv (25 GB) をストリーム読みし、各 kojin_id の最初の入院日 (nyuin_ymd) を抽出。
## nyuin_ymd が空 = 外来のみ、入っていれば入院あり。
## 出力: kojin_id\tfirst_admission_ymd\tn_admissions  (TSV, kojin_id 昇順)

using Printf

function scan_receipt!(path::String,
                       first_adm::Dict{Int, String},
                       n_adm::Dict{Int, Int})
    open(path) do io
        readline(io)  # header
        line_no = 0
        for line in eachline(io)
            line_no += 1
            parts = split(line, ',')
            length(parts) >= 6 || continue
            kojin_id_str = parts[3]
            nyuin_ymd    = parts[6]
            isempty(kojin_id_str) && continue
            isempty(nyuin_ymd) && continue
            kid = tryparse(Int, kojin_id_str)
            kid === nothing && continue
            # admission count
            n_adm[kid] = get(n_adm, kid, 0) + 1
            # 最も古い admission を採用
            cur = get(first_adm, kid, "")
            if isempty(cur) || nyuin_ymd < cur
                first_adm[kid] = String(nyuin_ymd)
            end
            if line_no % 100_000_000 == 0
                @printf("  line %d, persons with admission = %d\n",
                        line_no, length(first_adm))
                flush(stdout)
            end
        end
        @printf("  total lines = %d, persons with admission = %d\n",
                line_no, length(first_adm))
    end
end

function write_output(outfile::String,
                      first_adm::Dict{Int, String},
                      n_adm::Dict{Int, Int})
    open(outfile, "w") do out
        println(out, "kojin_id\tfirst_admission_ymd\tn_admissions")
        ks = sort!(collect(keys(first_adm)))
        for k in ks
            println(out, "$k\t$(first_adm[k])\t$(get(n_adm, k, 0))")
        end
    end
end

function main()
    receipt_path = ARGS[1]
    outfile      = ARGS[2]

    println("Scanning $receipt_path ..."); flush(stdout)
    first_adm = Dict{Int, String}()
    n_adm     = Dict{Int, Int}()
    scan_receipt!(receipt_path, first_adm, n_adm)

    println("\nWriting $outfile ..."); flush(stdout)
    write_output(outfile, first_adm, n_adm)
    println("done")
end

main()
