using CodecZstd
using TranscodingStreams

infile  = ARGS[1]
outfile = ARGS[2]
n_scan  = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 200_000_000

# テキスト判定（Functions.jl と同等）
function is_text_coo(zst_path::String)::Bool
    open(zst_path, "r") do fio
        zio = TranscodingStream(ZstdDecompressor(), fio)
        buf = try read(zio, 64) catch e; close(zio); rethrow(e) end
        close(zio)
        s = String(take!(IOBuffer(buf)))
        return occursin(r"^\s*\d+\s+\d+", s)
    end
end

is_text = is_text_coo(infile)

open(outfile, "w") do out
    println(out, "COO file: $infile")
    println(out, "format  : $(is_text ? "text" : "binary (Int32,Int32)")")
    println(out, "scanning first $n_scan entries...")
    println(out, "")

    max_i = 0
    max_j = 0
    min_i = typemax(Int)
    min_j = typemax(Int)
    n_total = 0
    samples = Tuple{Int,Int}[]
    # 受診者ごとの非ゼロ列数（先頭 1000 人サンプル）
    rowcount = Dict{Int,Int}()

    open(infile, "r") do io
        zio = TranscodingStream(ZstdDecompressor(), io)
        if is_text
            for line in eachline(zio)
                parts = split(strip(line))
                length(parts) >= 2 || continue
                i = parse(Int, parts[1])
                j = parse(Int, parts[2])
                max_i = max(max_i, i); min_i = min(min_i, i)
                max_j = max(max_j, j); min_j = min(min_j, j)
                n_total += 1
                if length(samples) < 30
                    push!(samples, (i, j))
                end
                if i <= 1000
                    rowcount[i] = get(rowcount, i, 0) + 1
                end
                if n_total >= n_scan; break; end
                if n_total % 50_000_000 == 0
                    @info "progress" n_total max_i max_j
                end
            end
        else
            while !eof(zio) && n_total < n_scan
                try
                    i32 = read(zio, Int32)
                    j32 = read(zio, Int32)
                    i, j = Int(i32), Int(j32)
                    max_i = max(max_i, i); min_i = min(min_i, i)
                    max_j = max(max_j, j); min_j = min(min_j, j)
                    n_total += 1
                    if length(samples) < 30
                        push!(samples, (i, j))
                    end
                    if i <= 1000
                        rowcount[i] = get(rowcount, i, 0) + 1
                    end
                    if n_total % 50_000_000 == 0
                        @info "progress" n_total max_i max_j
                    end
                catch e
                    if e isa EOFError; break
                    else; rethrow(e)
                    end
                end
            end
        end
        close(zio)
    end

    println(out, "scanned    : $n_total entries")
    println(out, "i range    : [$min_i, $max_i]   (expected: 受診者ID 1..7581)")
    println(out, "j range    : [$min_j, $max_j]   (この値次第で列が何を表すか判別)")
    println(out, "")
    println(out, "--- First 30 (i, j) pairs ---")
    for (k, (i, j)) in enumerate(samples)
        println(out, "  $k: i=$i j=$j")
    end
    println(out, "")

    # 同一受診者の j 系列で「ソートされているか」「重複あるか」「単調か」を見る
    # 先頭から 1 受診者分の j 系列を抽�出
    println(out, "--- Same-i sequence inspection (first ~200 entries that have i==samples[1][1]) ---")
    target_i = samples[1][1]
    js_target = Int[]
    open(infile, "r") do io
        zio = TranscodingStream(ZstdDecompressor(), io)
        cnt = 0
        while !eof(zio) && cnt < 5_000_000 && length(js_target) < 200
            try
                if is_text
                    line = readline(zio)
                    parts = split(strip(line))
                    length(parts) >= 2 || continue
                    i = parse(Int, parts[1]); j = parse(Int, parts[2])
                else
                    i = Int(read(zio, Int32)); j = Int(read(zio, Int32))
                end
                cnt += 1
                if i == target_i
                    push!(js_target, j)
                end
            catch e
                if e isa EOFError; break; else; rethrow(e); end
            end
        end
        close(zio)
    end
    println(out, "target i = $target_i, collected j count = $(length(js_target))")
    if length(js_target) >= 2
        diffs = diff(js_target)
        println(out, "  j sequence sorted? $(issorted(js_target))")
        println(out, "  any duplicate j?   $(length(unique(js_target)) < length(js_target))")
        println(out, "  Δj summary: min=$(minimum(diffs)) median=$(diffs[end÷2+1]) max=$(maximum(diffs))")
        println(out, "  first 30 j: ", js_target[1:min(30,end)])
    end

    println(out, "")
    println(out, "--- Per-receiver (i in 1..1000) entry count summary ---")
    if !isempty(rowcount)
        cnts = collect(values(rowcount))
        sort!(cnts)
        n_recv = length(cnts)
        println(out, "  receivers scanned: $n_recv")
        println(out, "  entries/receiver  min=$(minimum(cnts)) median=$(cnts[end÷2+1]) mean=$(round(sum(cnts)/n_recv,digits=1)) max=$(maximum(cnts))")
    end
end
