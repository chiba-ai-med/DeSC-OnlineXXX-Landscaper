## baseline_row.tsv の row_id を使って、Scores.csv (347M × 7) と row2pat.bin (UInt32 × 347M)
## から baseline 時点の PC スコア + pattern_id を抽出する。
##
## 入力: data/baseline_row.tsv (kojin_id, baseline_row_id, baseline_window)
##       output/.../Scores.csv  (各行: 7 PC スコア、カンマ区切り)
##       output/.../row2pat.bin (UInt32 × N)
##
## 出力: kojin_id, baseline_row_id, baseline_window, baseline_pattern_id,
##       baseline_PC1..baseline_PC7   (TSV、kojin_id 昇順)

using Mmap
using Printf

function load_needed(rowmap_path::String)
    needed = Dict{Int, Tuple{Int, String}}()
    open(rowmap_path) do io
        readline(io)  # header
        for line in eachline(io)
            parts = split(line, '\t')
            length(parts) >= 2 || continue
            kojin_id = parse(Int, parts[1])
            row_id   = parse(Int, parts[2])
            window   = length(parts) >= 3 ? String(parts[3]) : ""
            needed[row_id] = (kojin_id, window)
        end
    end
    return needed
end

function stream_scores!(scores_path::String, needed::Dict{Int, Tuple{Int, String}},
                        row2pat::Vector{UInt32}, N::Int,
                        res_kojin::Vector{Int}, res_row::Vector{Int},
                        res_win::Vector{String}, res_pid::Vector{UInt32},
                        res_pc::Matrix{Float64})
    filled = 0
    line_no = 0
    open(scores_path) do io
        for line in eachline(io)
            line_no += 1
            if haskey(needed, line_no)
                k, w = needed[line_no]
                pid = row2pat[line_no]
                xs = split(line, ',')
                length(xs) >= 7 || continue
                filled += 1
                res_kojin[filled] = k
                res_row[filled]   = line_no
                res_win[filled]   = w
                res_pid[filled]   = pid
                @inbounds for i in 1:7
                    res_pc[filled, i] = parse(Float64, xs[i])
                end
            end
            if line_no % 50_000_000 == 0
                @printf("  line %d / %d, filled %d / %d\n",
                        line_no, N, filled, length(needed))
                flush(stdout)
            end
        end
    end
    @printf("  done. total lines = %d, filled %d\n", line_no, filled)
    return filled
end

function write_output(outfile::String, ord::Vector{Int},
                      res_kojin::Vector{Int}, res_row::Vector{Int},
                      res_win::Vector{String}, res_pid::Vector{UInt32},
                      res_pc::Matrix{Float64})
    open(outfile, "w") do out
        header = ["kojin_id", "baseline_row_id", "baseline_window", "baseline_pattern_id"]
        append!(header, ["baseline_PC$i" for i in 1:7])
        println(out, join(header, "\t"))
        for i in ord
            scs = String[]
            for j in 1:7
                push!(scs, @sprintf("%.6g", res_pc[i, j]))
            end
            println(out, "$(res_kojin[i])\t$(res_row[i])\t$(res_win[i])\t" *
                          "$(res_pid[i])\t" * join(scs, "\t"))
        end
    end
end

function main()
    scores_path  = ARGS[1]
    rowmap_path  = ARGS[2]
    row2pat_path = ARGS[3]
    outfile      = ARGS[4]

    println("Reading $rowmap_path ..."); flush(stdout)
    needed = load_needed(rowmap_path)
    println("  needed rows: ", length(needed)); flush(stdout)

    println("\nmmap-ing $row2pat_path ..."); flush(stdout)
    N = filesize(row2pat_path) ÷ 4
    row2pat = Mmap.mmap(row2pat_path, Vector{UInt32}, N)
    println("  N = $N"); flush(stdout)

    n_needed = length(needed)
    res_kojin = Vector{Int}(undef, n_needed)
    res_row   = Vector{Int}(undef, n_needed)
    res_win   = Vector{String}(undef, n_needed)
    res_pid   = Vector{UInt32}(undef, n_needed)
    res_pc    = Matrix{Float64}(undef, n_needed, 7)

    println("\nStreaming $scores_path ..."); flush(stdout)
    filled = stream_scores!(scores_path, needed, row2pat, N,
                            res_kojin, res_row, res_win, res_pid, res_pc)

    println("\nWriting $outfile ..."); flush(stdout)
    # 配列を filled サイズで切り取り (needed の row が全部 scores に対応していれば filled == n_needed)
    if filled < n_needed
        @warn "filled ($filled) < n_needed ($n_needed); truncating"
        res_kojin = res_kojin[1:filled]
        res_row   = res_row[1:filled]
        res_win   = res_win[1:filled]
        res_pid   = res_pid[1:filled]
        res_pc    = res_pc[1:filled, :]
    end
    ord = sortperm(res_kojin)
    write_output(outfile, ord, res_kojin, res_row, res_win, res_pid, res_pc)
    println("done")
end

main()
