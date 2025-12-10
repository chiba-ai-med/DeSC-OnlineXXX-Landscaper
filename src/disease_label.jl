using DelimitedFiles
using StatsBase

# 引数の取得
mapfile = ARGS[1]
coofile = ARGS[2]
outfile = ARGS[3]

function build_number_to_letter(mapfile::AbstractString)
    number_to_letter = Dict{Int32, Char}()
    open(mapfile, "r") do io
        for ln in eachline(io)
            # 例: "T629,1,食物として摂取された有害物質，詳細不明"
            # 先頭: ICD-10コード, 2列目: 番号
            cols = split(ln, ',')
            length(cols) >= 2 || continue
            code = strip(cols[1])
            num  = parse(Int32, strip(cols[2]))
            # ICD-10先頭文字（英大文字）を採用
            number_to_letter[num] = first(code)
        end
    end
    return number_to_letter
end

function make_disease_label(mapfile::AbstractString, coofile::AbstractString, outfile::AbstractString)
    # 1) 番号→先頭文字のマップ
    num2letter = build_number_to_letter(mapfile)

    # 2) まず coo の最大行 index を把握（ついでに一意列判定も同時にやってOK）
    #     state[r] の意味:
    #       0  : まだ未出現
    #      >0  : その列番号が唯一候補
    #      -1  : 複数列あり（= NA）
    maxrow = Int32(0)

    # 一度 maxrow が見えたら、配列を確保
    # ただし maxrow が事前に未知なら、2 パスにしてもOK。
    # ここでは 1 パスでやるため、必要に応じてサイズ拡張します。
    state = Vector{Int32}(undef, 0)

    function ensure_size!(v::Vector{Int32}, need::Int32)
        oldlen = length(v)
        if need > oldlen
            resize!(v, need)
            @inbounds fill!(view(v, oldlen + 1:need), Int32(0))
        end
    end

    open(coofile, "r") do io
        for (k, ln) in enumerate(eachline(io))
            s = split(ln)  # 空白区切り
            length(s) == 2 || continue
            r = parse(Int32, s[1])  # 行
            c = parse(Int32, s[2])  # 列（疾患番号）

            if r > maxrow
                maxrow = r
                ensure_size!(state, maxrow)
            end

            v = state[r]
            if v == 0
                state[r] = c
            elseif v == c
                # 変化なし（同一列が重複してもOK）
            elseif v > 0 && v != c
                state[r] = Int32(-1)  # 複数列あり → NA
            # v == -1 は既に複数確定なので放置
            end

            # 進捗（任意）
            if k % 100_000_000 == 0
                @info "processed $k lines"
            end
        end
    end

    # 3) 出力：1..maxrow 行。唯一の列 c があれば num2letter[c]、なければ "NA"
    open(outfile, "w") do io
        for r in 1:Int(maxrow)
            c = r <= length(state) ? state[r] : Int32(0)
            if c > 0
                letter = get(num2letter, c, nothing)
                if letter === nothing
                    write(io, "NA\n")
                else
                    write(io, string(letter), "\n")
                end
            else
                write(io, "NA\n")
            end
        end
    end
end

# Output
make_disease_label(mapfile, coofile, outfile)
