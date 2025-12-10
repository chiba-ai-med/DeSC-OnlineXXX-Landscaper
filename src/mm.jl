using DelimitedFiles
using SparseArrays
using MatrixMarket

# Arguments
infile = ARGS[1]
outfile = ARGS[2]

function csv_to_mm(infile::String, outfile::String)
    # CSVを文字列として読み込む
    data = readdlm(infile, ',')

    # スパース行列のインデックスと値を構築
    nrow, ncol = size(data)
    row_idx = Int[]
    col_idx = Int[]
    vals = Int[]

    for i in 1:nrow
        for j in 1:ncol
            val = strip(string(data[i][j]))
            if val == "+"
                push!(row_idx, i)
                push!(col_idx, j)
                push!(vals, 1)
            end
        end
    end

    # スパース行列に変換
    S = sparse(row_idx, col_idx, vals, nrow, ncol)

    # Matrix Market 形式で保存
    mmwrite(outfile, S)
end

# 使用例
csv_to_mm(infile, outfile)
