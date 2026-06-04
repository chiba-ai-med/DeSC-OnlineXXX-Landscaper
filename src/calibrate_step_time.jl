using Mmap
using Printf
using DelimitedFiles

# Arguments
row_id_file   = ARGS[1]
row2pat_bin   = ARGS[2]
n_patterns    = parse(Int, ARGS[3])
out_summary   = ARGS[4]
out_pairs     = ARGS[5]
gap_months    = parse(Int, ARGS[6])
subgraph_file = ARGS[7]   # plot/.../Landscaper/{dim}/SubGraph.tsv

@inline month_to_idx(year::Int, month::Int) = UInt8((year - 2014) * 12 + (month - 4))

function parse_records!(row_id_file::String,
                        row2pat::Vector{UInt32},
                        person_ids::Vector{UInt32},
                        month_idxs::Vector{UInt8},
                        pattern_ids::Vector{UInt32})
    n = 0
    n_bad = 0
    open(row_id_file, "r") do io
        for line in eachline(io)
            n += 1
            sp = split(strip(line))
            if length(sp) < 2
                n_bad += 1; continue
            end
            win_pid = sp[1]
            row_idx = parse(Int, sp[2])
            us = findfirst(==('_'), win_pid)
            if us === nothing
                n_bad += 1; continue
            end
            win_str = win_pid[1:us-1]
            pid_str = win_pid[us+1:end]
            person_id = parse(UInt32, pid_str)
            ymd = win_str[1:7]
            year  = parse(Int, ymd[1:4])
            month = parse(Int, ymd[6:7])
            midx  = month_to_idx(year, month)
            pid = row2pat[row_idx]

            person_ids[row_idx]  = person_id
            month_idxs[row_idx]  = midx
            pattern_ids[row_idx] = pid

            if n % 50_000_000 == 0
                @info "progress" n
            end
        end
    end
    return n, n_bad
end

function count_pairs(person_ids::Vector{UInt32},
                     month_idxs::Vector{UInt8},
                     pattern_ids::Vector{UInt32},
                     basin_of_pattern::Vector{UInt8},
                     n_patterns::Int,
                     gap_months::Int)
    n_pairs = 0
    n_same_pat = 0
    n_diff_pat = 0
    # Basin 集計（basin が両方 assigned なペアのみ）
    n_basin_pairs    = 0
    n_same_basin     = 0
    n_diff_basin     = 0
    transition_matrix = zeros(Int64, n_patterns, n_patterns)

    N = length(person_ids)
    i = 1
    while i <= N
        j = i + 1
        while j <= N && person_ids[j] == person_ids[i]
            j += 1
        end
        for a in i:(j-2)
            target = month_idxs[a] + UInt8(gap_months)
            for b in (a+1):(j-1)
                mb = month_idxs[b]
                if mb == target
                    n_pairs += 1
                    pf = Int(pattern_ids[a])
                    pt = Int(pattern_ids[b])
                    transition_matrix[pf, pt] += 1
                    if pf == pt
                        n_same_pat += 1
                    else
                        n_diff_pat += 1
                    end
                    # basin 比較
                    bf = basin_of_pattern[pf]
                    bt = basin_of_pattern[pt]
                    if bf != 0 && bt != 0
                        n_basin_pairs += 1
                        if bf == bt
                            n_same_basin += 1
                        else
                            n_diff_basin += 1
                        end
                    end
                    break
                elseif mb > target
                    break
                end
            end
        end
        i = j
    end
    return (n_pairs, n_same_pat, n_diff_pat,
            n_basin_pairs, n_same_basin, n_diff_basin,
            transition_matrix)
end

# main
row2pat = open(row2pat_bin, "r") do io
    len = Int(filesize(io) ÷ 4)
    Mmap.mmap(io, Vector{UInt32}, len)
end
n_rows = length(row2pat)
@info "row2pat loaded" n_rows

person_ids  = Vector{UInt32}(undef, n_rows)
month_idxs  = Vector{UInt8}(undef, n_rows)
pattern_ids = Vector{UInt32}(undef, n_rows)

n_parsed, n_bad = parse_records!(row_id_file, row2pat,
                                  person_ids, month_idxs, pattern_ids)
@info "parsed records" n_parsed n_bad

@info "sorting indices by (person_id, month_idx)..."
ord = sortperm(collect(zip(person_ids, month_idxs)))
person_ids  = person_ids[ord]
month_idxs  = month_idxs[ord]
pattern_ids = pattern_ids[ord]
@info "sort done"

# SubGraph (basin id) を読み込み
subgraph = vec(readdlm(subgraph_file, Int))
basin_of_pattern = fill(UInt8(0), n_patterns)
for i in 1:length(subgraph)
    basin_of_pattern[i] = UInt8(subgraph[i])
end
n_basin_assigned = count(b -> b != 0, basin_of_pattern)
n_basins = maximum(subgraph)
@info "basin info" n_basin_assigned n_basins

@info "counting pairs with gap=$(gap_months) months..."
n_pairs, n_same_pat, n_diff_pat,
n_basin_pairs, n_same_basin, n_diff_basin,
transition_matrix =
    count_pairs(person_ids, month_idxs, pattern_ids,
                basin_of_pattern, n_patterns, gap_months)

p_transition_pat = n_pairs > 0 ? n_diff_pat / n_pairs : 0.0
p_stay_pat       = n_pairs > 0 ? n_same_pat / n_pairs : 0.0
p_transition_basin = n_basin_pairs > 0 ? n_diff_basin / n_basin_pairs : 0.0
p_stay_basin       = n_basin_pairs > 0 ? n_same_basin / n_basin_pairs : 0.0
@info "summary (pattern)" n_pairs n_same_pat n_diff_pat p_transition_pat p_stay_pat
@info "summary (basin)"   n_basin_pairs n_same_basin n_diff_basin p_transition_basin p_stay_basin

mkpath(dirname(out_summary))
open(out_summary, "w") do f
    println(f, "key\tvalue")
    println(f, "gap_months\t$gap_months")
    # pattern 一致
    println(f, "n_pairs\t$n_pairs")
    println(f, "n_same_pattern\t$n_same_pat")
    println(f, "n_diff_pattern\t$n_diff_pat")
    println(f, "p_transition\t$p_transition_pat")
    println(f, "p_stay\t$p_stay_pat")
    # basin 一致
    println(f, "n_basin_pairs\t$n_basin_pairs")
    println(f, "n_same_basin\t$n_same_basin")
    println(f, "n_diff_basin\t$n_diff_basin")
    println(f, "p_transition_basin\t$p_transition_basin")
    println(f, "p_stay_basin\t$p_stay_basin")
    println(f, "n_basins\t$n_basins")
end

open(out_pairs, "w") do f
    println(f, "from\tto\tcount")
    for i in 1:n_patterns, j in 1:n_patterns
        if transition_matrix[i, j] > 0
            println(f, "$i\t$j\t$(transition_matrix[i, j])")
        end
    end
end

@info "done"
