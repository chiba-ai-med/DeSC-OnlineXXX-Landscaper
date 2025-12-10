#############################
# pair_density_plots.jl
#############################

using CairoMakie, Makie
using ColorTypes: RGBA, RGB
const RGBAf = RGBA{Float32}
using Colors: distinguishable_colors, deuteranopic

using Mmap
using Printf
using CodecZstd
using TranscodingStreams

@inline function bitpack_pm1_to_uint(x::AbstractVector{<:Integer})
    id::UInt64 = 0
    @inbounds for (r,v) in enumerate(x)
        id |= ((v > 0 ? UInt64(1) : UInt64(0)) << (r-1))  # +1→1, -1→0
    end
    return id
end

function load_pattern_dict(path::String)
    d = Dict{UInt64,UInt32}()
    ndim = 0
    open(path) do io
        for (i,ln) in enumerate(eachline(io))
            vals = split(strip(ln))
            ndim == 0 && (ndim = length(vals))
            x = Int8[parse(Int, v) >= 1 ? 1 : -1 for v in vals]
            d[bitpack_pm1_to_uint(x)] = UInt32(i)  # 1-based
        end
    end
    expected = UInt64(1) << ndim  # 2^k
    @assert length(d) == expected "Allstates.tsv の行数が 2^$ndim と一致しません。全パターンを列挙してください。"
    return d
end

# ================= Scores.mm → row2pat =================
# Matrix Market (coordinate)。非ゼロが「+1」、その他は「-1」。
# k<=64 を想定（>64 は UInt128/BitVector に拡張）。
function build_row2pat_from_mm(mm_path::String, pat2id::Dict{UInt64,UInt32}, outdir::String)
    # ヘッダ読み "m n nnz"
    nrows = 0; ndim = 0; nnz = 0
    open(mm_path, "r") do io
        for ln in eachline(io)
            s = strip(ln); isempty(s) && continue
            (startswith(s,"%%") || startswith(s,"%")) && continue
            parts = split(s); @assert length(parts) >= 3 "MatrixMarket header not found"
            nrows = parse(Int, parts[1]); ndim = parse(Int, parts[2]); nnz = parse(Int, parts[3])
            break
        end
    end
    @info "Scores.mm size" nrows=nrows ndim=ndim nnz=nnz
    @assert ndim <= 64 "k=$ndim > 64 は未対応（UInt128/BitVectorに拡張を）"

    # 各行の +成分ビット集合を mmap で保持（ディスク上に確保）
    bits_path = joinpath(outdir, "row_bits.bin")
    open(bits_path, "w+") do bio
        seek(bio, nrows*8 - 1); write(bio, UInt8(0)); seekstart(bio)
        row_bits = Mmap.mmap(bio, Vector{UInt64}, nrows)

        # 座標部を2回目でストリーム処理
        open(mm_path, "r") do io2
            header_skipped = false
            for ln in eachline(io2)
                s = strip(ln); isempty(s) && continue
                if !header_skipped
                    if startswith(s,"%%") || startswith(s,"%"); continue
                    else; header_skipped = true; continue
                    end
                end
                parts = split(s)
                @inbounds begin
                    i = parse(Int, parts[1])
                    j = parse(Int, parts[2])
                    row_bits[i] |= (UInt64(1) << (j-1))
                end
            end
        end

        # row_bits → row2pat.bin / n_s.tsv
        outbin = joinpath(outdir, "row2pat.bin")
        nsfile = joinpath(outdir, "n_s.tsv")
        counts = Dict{UInt32,Int}()
        open(outbin, "w") do bo
            @inbounds for i in 1:nrows
                key = row_bits[i]
                pid = get(pat2id, key, UInt32(0))
                pid == 0 && error("row $i のパターンが Allstates.tsv に存在しません（k/符号化の不一致）")
                write(bo, pid)
                counts[pid] = get(counts, pid, 0) + 1
                if i % 10_000_000 == 0; @info "row2pat progress" i; end
            end
        end
        open(nsfile, "w") do nsi
            for (pid,n) in counts
                @printf(nsi, "%d\t%d\n", pid, n)
            end
        end
        return outbin
    end
end

function mmap_row2pat(path::String)
    io = open(path, "r")
    len = Int(filesize(io) ÷ 4)
    return Mmap.mmap(io, Vector{UInt32}, len)
end

# ================= COO（zst）読み =================
# 先頭を覗いて text("i j") / binary(Int32,Int32) を自動判別
function _is_text_coo(zst_path::String)::Bool
    open(zst_path, "r") do fio
        zio = TranscodingStream(ZstdDecompressor(), fio)
        buf = try read(zio, 64) catch e; close(zio); rethrow(e) end
        close(zio)
        s = String(take!(IOBuffer(buf)))
        return occursin(r"^\s*\d+\s+\d+", s)
    end
end

# 出力: outfile（TSV）に「pattern_id\tj\tcount」
# シャードは (UInt32 pid, UInt32 j) の交互書き。
function build_frequency(coo_zst::String, row2pat::Vector{UInt32},
                         outdir::String, outfile::String, cols::Int, block::Int)
    nb = cld(cols, block)
    shard_paths = String[joinpath(outdir, @sprintf("blk%03d.bin", b)) for b = 1:nb]
    ios = [open(p, "w") for p in shard_paths]

    if _is_text_coo(coo_zst)
        open(coo_zst) do fio
            zio = TranscodingStream(ZstdDecompressor(), fio)
            n = 0
            for ln in eachline(zio)
                s = split(strip(ln))
                @inbounds begin
                    i = parse(Int, s[1]); j = parse(Int, s[2])
                    pid = row2pat[i]
                    b = (j-1) ÷ block + 1
                    write(ios[b], pid::UInt32); write(ios[b], UInt32(j))
                end
                n += 1
                if n % 50_000_000 == 0; @info "COO text read" n; end
            end
            close(zio)
        end
    else
        open(coo_zst) do fio
            zio = TranscodingStream(ZstdDecompressor(), fio)
            n = 0
            while true
                local i32::Int32, j32::Int32
                try
                    i32 = read(zio, Int32); j32 = read(zio, Int32)
                catch e
                    if e isa EOFError; break
                    else; close(zio); rethrow(e)
                    end
                end
                @inbounds begin
                    i = Int(i32); j = Int(j32)
                    pid = row2pat[i]
                    b = (j-1) ÷ block + 1
                    write(ios[b], pid::UInt32); write(ios[b], UInt32(j))
                end
                n += 1
                if n % 50_000_000 == 0; @info "COO binary read" n; end
            end
            close(zio)
        end
    end
    foreach(close, ios)

    # リデュース：交互レイアウトを一気読み→奇偶ビューで切り出し
    open(outfile, "w") do outfreq
        for b in 1:nb
            path = shard_paths[b]
            bytes = isfile(path) ? filesize(path) : 0
            if bytes == 0; continue; end
            @assert bytes % 8 == 0 "shard壊れ: $(path) (bytes=$bytes)"
            np = Int(bytes ÷ 8)  # 1ペア=8B
            buf = Vector{UInt32}(undef, 2*np)
            open(path, "r") do io
                read!(io, buf)   # [pid1, j1, pid2, j2, ...]
            end
            pids = @view buf[1:2:2*np]
            js   = @view buf[2:2:2*np]

            idx = collect(1:np)
            sort!(idx, by = t -> (pids[t], js[t]))

            runp, runj = pids[idx[1]], js[idx[1]]
            runct = 0
            for t in idx
                p, j = pids[t], js[t]
                if p == runp && j == runj
                    runct += 1
                else
                    @printf(outfreq, "%d\t%d\t%d\n", runp, runj, runct)
                    runp, runj, runct = p, j, 1
                end
            end
            @printf(outfreq, "%d\t%d\t%d\n", runp, runj, runct)
            rm(path; force=true)
            @info "block reduced" b np
        end
    end
end

# 安全なビン計算（全要素同値でも落ちない/範囲外丸め）
@inline function _safe_bin(v::Float32, vmin::Float32, vmax::Float32, nb::Int)
    width = max(vmax - vmin, eps(Float32))
    t = (v - vmin) / width
    b = Int(floor(t * nb)) + 1
    return ifelse(b < 1, 1, ifelse(b > nb, nb, b))
end

# 軸表示軽量化（桁を間引く）＋科学記法
using Printf
@inline function _set_pretty_ticks!(ax::Axis, xmin::Float32, xmax::Float32, ymin::Float32, ymax::Float32; nticks::Int=3)
    # x軸の範囲チェック
    xrange = xmax - xmin
    if abs(xmax) > 1e4 || abs(xmin) > 1e4 || (xrange != 0 && xrange < 1e-3)
        ax.xtickformat = xs -> [@sprintf("%.1e", x) for x in xs]
    end
    
    # y軸の範囲チェック
    yrange = ymax - ymin
    if abs(ymax) > 1e4 || abs(ymin) > 1e4 || (yrange != 0 && yrange < 1e-3)
        ax.ytickformat = ys -> [@sprintf("%.1e", y) for y in ys]
    end
    
    ax.xticks = Makie.LinearTicks(nticks)
    ax.yticks = Makie.LinearTicks(nticks)
    ax.xticklabelrotation = 0
    ax.yticklabelrotation = 0
end

# 文字列ラベル（カテゴリ）の色を決める
function _make_group_colors(groups::Vector{String})
    # 背景の青（viridis）と区別しやすい色を使用
    if length(groups) == 2
        # 2グループの場合は赤とライムグリーン
        return [RGBAf(1.0, 0.2, 0.2, 0.8), RGBAf(0.2, 1.0, 0.2, 0.8)]
    else
        # 3グループ以上の場合は背景を避けた色を生成
        cs = distinguishable_colors(length(groups), 
            [RGB(0.44, 0.0, 0.62), RGB(0.0, 0.0, 0.5)],  # 青・紫を避ける
            transform=deuteranopic)
        return RGBAf.(cs, 0.8)
    end
end

# ダミー要素から凡例を作る（axis を渡さない！）
function add_group_legend!(fig::Figure, names::Vector{String}, colors::Vector{RGBAf};
                           title::AbstractString="Group")
    @assert length(names) == length(colors)
    elems = [MarkerElement(color=c, marker=:rect, markersize=12) for c in colors]
    leg = Legend(fig, elems, names; title=title)
    fig[1, end+1] = leg  # 右側に配置
    return leg
end

"""
pair_density_plots(path; cols=1:7, nbins=(100,100), outfile,
                   labels_path=nothing,
                   label_kind=:categorical,  # or :continuous
                   label_colors=nothing,     # Vector{RGBAf}（カテゴリ時のみ）
                   print_every=10_000_000,
                   label_max_per_pair=300)

巨大CSV（カンマ区切り）から列 `cols` のペアプロット密度図を `outfile` に保存。
- 全ペアで **列ごとの min/max を共有**（値域を統一）
- 対角は 1D ヒスト、下三角は 2D ヒートマップ
- `labels_path` を与えると、点を少量サンプリングして色付き散布を重ねる
  - `label_kind=:categorical` → グループ別の色、**凡例あり**
  - `label_kind=:continuous`  → 色は使わず（ご要望どおり）凡例なし
"""
function pair_density_plots(path::AbstractString;
    cols::UnitRange{Int}=1:7,
    nbins::Tuple{Int,Int}=(100,100),
    outfile::AbstractString,
    labels_path::Union{Nothing,AbstractString}=nothing,
    label_kind::Symbol=:categorical, # or :continuous
    label_colors::Union{Nothing,Vector{RGBAf}}=nothing,
    print_every::Int=10_000_000,
    label_max_per_pair::Int=300
)
    @assert isfile(path) "data file not found: $path"
    k = length(cols)
    nbx, nby = nbins

    # ---- ラベル読み込み（任意） ----
    labels::Union{Nothing,Vector{String}} = nothing
    label_values::Union{Nothing,Vector{Float32}} = nothing
    groups::Vector{String} = String[]
    group2idx = Dict{String,Int}()
    if labels_path !== nothing
        @assert isfile(labels_path) "labels file not found: $labels_path"
        println("[pass 0] reading labels ...")
        labels = readlines(labels_path)
        if label_kind == :categorical
            groups = sort!(unique(labels))
            for (i,g) in enumerate(groups)
                group2idx[g] = i
            end
        elseif label_kind == :continuous
            # 連続値を数値に変換（YYYY/MM形式を数値化）
            label_values = Float32[]
            for lbl in labels
                # YYYY/MM形式を年.月の小数に変換
                parts = split(lbl, '/')
                if length(parts) == 2
                    year = parse(Float32, parts[1])
                    month = parse(Float32, parts[2])
                    push!(label_values, year + month/12.0)
                else
                    # その他の形式は直接数値化を試みる
                    push!(label_values, parse(Float32, lbl))
                end
            end
        else
            error("label_kind must be :categorical or :continuous")
        end
    end

    # ---- Pass1: 列ごとの min/max 推定 ----
    println("\n[pass 1] estimating per-column min/max ...\n")
    col_min = fill(typemax(Float32), k)
    col_max = fill(typemin(Float32), k)

    total_lines = 0
    open(path, "r") do io
        for (line_no, line) in enumerate(eachline(io))
            isempty(line) && continue
            xs = split(line, ',')
            for (ii, c) in enumerate(cols)
                v = parse(Float32, xs[c])
                @inbounds begin
                    if v < col_min[ii]; col_min[ii] = v; end
                    if v > col_max[ii]; col_max[ii] = v; end
                end
            end
            total_lines = line_no
            if (line_no % print_every) == 0
                println("[pass 1] lines: $line_no")
            end
        end
    end
    println("\n[pass 1] done. total lines = $total_lines")

    # ---- ヒスト配列準備 ----
    diag_hists = [zeros(Int, nbx) for _ in 1:k]                  # 対角
    pair_hists = [zeros(Int, nbx, nby) for _ in 1:(k*(k-1)÷2)]   # 下三角
    pair_index = Dict{Tuple{Int,Int},Int}()                       # (col,row)->idx where row>col
    cnt = 0
    for row in 1:k, col in 1:k
        if row > col
            cnt += 1
            pair_index[(col,row)] = cnt
        end
    end

    # 散布点のサンプル（ラベルがある場合／各ペア上限）
    sampled_xy = nothing
    sampled_labels = nothing
    sampled_values = nothing
    if labels !== nothing
        sampled_xy = [Tuple{Float32,Float32}[] for _ in 1:length(pair_hists)]
        if label_kind == :categorical
            sampled_labels = [String[] for _ in 1:length(pair_hists)]
        else  # continuous
            sampled_values = [Float32[] for _ in 1:length(pair_hists)]
        end
    end

    # ---- Pass2: ビン詰め & サンプリング ----
    println("\n[pass 2] filling hist bins ...\n")
    open(path, "r") do io
        for (line_no, line) in enumerate(eachline(io))
            isempty(line) && continue
            xs = split(line, ',')

            # 対角（1D）
            for i in 1:k
                v = parse(Float32, xs[cols[i]])
                b = _safe_bin(v, col_min[i], col_max[i], nbx)
                @inbounds diag_hists[i][b] += 1
            end

            # 下三角（2D） + サンプル点
            for row in 1:k, col in 1:k
                (row > col) || continue  # 下三角のみ（row > col）
                vcol = parse(Float32, xs[cols[col]])  # x軸
                vrow = parse(Float32, xs[cols[row]])  # y軸
                bx = _safe_bin(vcol, col_min[col], col_max[col], nbx)
                by = _safe_bin(vrow, col_min[row], col_max[row], nby)
                idx = pair_index[(col,row)]  # (col, row)の順序で格納
                @inbounds pair_hists[idx][bx, by] += 1

                if sampled_xy !== nothing && labels !== nothing
                    # ざっくり確率で間引く（上限を大きく超えないように控えめ）
                    if length(sampled_xy[idx]) < label_max_per_pair && rand() < (label_max_per_pair/total_lines)
                        push!(sampled_xy[idx], (vcol, vrow))  # (x, y)の順序
                        if label_kind == :categorical
                            push!(sampled_labels[idx], labels[line_no])
                        else  # continuous
                            push!(sampled_values[idx], label_values[line_no])
                        end
                    end
                end
            end

            if (line_no % print_every) == 0
                println("[pass 2] lines: $line_no/$total_lines")
            end
        end
    end
    println("\n[pass 2] done. total lines = $total_lines")

    # ---- Figure 描画 ----
    # 横幅を1.2倍にして正方形に近づける
    plot_width = 264  # 横幅（220 * 1.2）
    plot_height = 220  # 縦幅（そのまま）
    legend_width = ((labels !== nothing && label_kind==:categorical) ? 180 : 0)
    fig = Figure(size = (plot_width*k + legend_width, plot_height*k))

    # カテゴリ色
    if (labels !== nothing) && (label_kind == :categorical) && (label_colors === nothing)
        label_colors = _make_group_colors(groups)
    end

    # 描画
    for row in 1:k, col in 1:k
        ax = Axis(fig[row, col])

        if row == col
            # 1Dヒスト（線）
            xedges = range(col_min[row], col_max[row], length=nbx)
            yvals  = @views Float64.(diag_hists[row])
            ymax = maximum(yvals)
            _set_pretty_ticks!(ax, col_min[row], col_max[row], 0.0f0, Float32(ymax); nticks=3)
            lines!(ax, collect(xedges), yvals)
            xlims!(ax, (Float64(col_min[row]), Float64(col_max[row])))
        elseif row > col
            # 2D ヒートマップ
            idx = pair_index[(col, row)]
            H = @views Float32.(pair_hists[idx])
            
            _set_pretty_ticks!(ax, col_min[col], col_max[col], col_min[row], col_max[row]; nticks=3)

            xlims!(ax, (Float64(col_min[col]), Float64(col_max[col])))
            ylims!(ax, (Float64(col_min[row]), Float64(col_max[row])))

            xedges = range(col_min[col], col_max[col], length=nbx+1)
            yedges = range(col_min[row], col_max[row], length=nby+1)
            heatmap!(ax, collect(xedges), collect(yedges), H; colormap=:viridis)

            # ラベルがあれば散布点を重ねる
            if sampled_xy !== nothing
                xy = sampled_xy[idx]
                if !isempty(xy) && label_kind == :categorical && sampled_labels !== nothing
                    slabels = sampled_labels[idx]
                    xs = Float32.(first.(xy))
                    ys = Float32.(last.(xy))
                    # 各点のグループに応じた色を割り当て
                    point_colors = RGBAf[]
                    for i in 1:length(slabels)
                        gidx = get(group2idx, slabels[i], 1)
                        push!(point_colors, label_colors[gidx])
                    end
                    scatter!(ax, xs, ys; markersize=4, color=point_colors)
                elseif !isempty(xy) && label_kind == :continuous && sampled_values !== nothing
                    # 連続値の場合はグラデーション
                    svalues = sampled_values[idx]
                    xs = Float32.(first.(xy))
                    ys = Float32.(last.(xy))
                    # 値の範囲を正規化（0-1）
                    vmin, vmax = extrema(svalues)
                    if vmin < vmax
                        normalized_values = (svalues .- vmin) ./ (vmax - vmin)
                    else
                        normalized_values = fill(0.5, length(svalues))
                    end
                    # プラズマカラーマップを使用（背景のviridisと区別しやすい）
                    scatter!(ax, xs, ys; markersize=4, color=normalized_values, colormap=:plasma)
                end
            end
        else
            hidespines!(ax); hidedecorations!(ax)
        end
    end

    # 凡例（カテゴリの場合のみ）
    if (labels !== nothing) && (label_kind == :categorical)
        add_group_legend!(fig, groups, label_colors; title="Group")
    end

    save(outfile, fig)
    println("saved: $outfile")
    return nothing
end
