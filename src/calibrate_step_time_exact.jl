using DelimitedFiles
using LinearAlgebra

# Args
h_file         = ARGS[1]   # plot/.../Landscaper/{dim}/h.tsv
J_file         = ARGS[2]   # plot/.../Landscaper/{dim}/J.tsv
allstates_file = ARGS[3]   # plot/.../Landscaper/{dim}/Allstates.tsv
summary_file   = ARGS[4]   # output/calibrate/{dim}/summary_gap6.tsv
T_temp         = parse(Float64, ARGS[5])  # 1.0 (ELA standard)
out_file       = ARGS[6]
N_max          = length(ARGS) >= 8 ? parse(Int, ARGS[8]) : 500
subgraph_file  = ARGS[7]   # plot/.../Landscaper/{dim}/SubGraph.tsv

# Load h, J, S
h = vec(readdlm(h_file))
J = readdlm(J_file)
S = readdlm(allstates_file, '\t', Int)
n_patterns, k = size(S)
@info "loaded" k n_patterns

function energy(s::Vector{Int}, h::Vector{Float64}, J::Matrix{Float64})
    e = -sum(h .* s)
    @inbounds for i in 1:length(s), j in (i+1):length(s)
        e -= J[i, j] * s[i] * s[j]
    end
    return e
end

E = [energy(S[i, :], h, J) for i in 1:n_patterns]

state_to_id = Dict{Vector{Int}, Int}()
for i in 1:n_patterns
    state_to_id[S[i, :]] = i
end

# 遷移行列 P (Metropolis-Hastings, 1 bit flip per step)
function build_P(S, E, state_to_id, n_patterns, k, T)
    P = zeros(n_patterns, n_patterns)
    inv_k = 1.0 / k
    for i in 1:n_patterns
        s = S[i, :]
        p_stay_self = 0.0
        for b in 1:k
            s_new = copy(s); s_new[b] = -s_new[b]
            j = state_to_id[s_new]
            dE = E[j] - E[i]
            p_accept = dE <= 0 ? 1.0 : exp(-dE / T)
            P[i, j] += inv_k * p_accept
            p_stay_self += inv_k * (1 - p_accept)
        end
        P[i, i] += p_stay_self
    end
    return P
end

P = build_P(S, E, state_to_id, n_patterns, k, T_temp)
@info "row sums of P (should be 1.0)" minimum(sum(P, dims=2)) maximum(sum(P, dims=2))

# 平衡分布 (Boltzmann)
boltz = exp.(-E ./ T_temp)
pi_eq = boltz ./ sum(boltz)
selfoverlap_eq_pattern = sum(pi_eq .^ 2)
@info "equilibrium" pi_max=maximum(pi_eq) pi_min=minimum(pi_eq) selfoverlap_eq_pattern

# Basin (SubGraph) を読み込み
subgraph = vec(readdlm(subgraph_file, Int))
basin_of = fill(0, n_patterns)
for i in 1:length(subgraph)
    basin_of[i] = subgraph[i]
end
n_basins = maximum(subgraph)

# basin 別の平衡質量
pi_basin = zeros(n_basins)
for i in 1:n_patterns
    if basin_of[i] > 0
        pi_basin[basin_of[i]] += pi_eq[i]
    end
end
selfoverlap_eq_basin = sum(pi_basin .^ 2)
@info "basin equilibrium" pi_basin selfoverlap_eq_basin

# 実データの target を読み込み（関数化して scoping 安全に）
function read_targets(summary_file)
    target_pat = NaN
    target_basin = NaN
    gap_months = 6
    for line in eachline(summary_file)
        sp = split(strip(line), '\t')
        length(sp) >= 2 || continue
        if sp[1] == "p_stay"
            target_pat = parse(Float64, sp[2])
        elseif sp[1] == "p_stay_basin"
            target_basin = parse(Float64, sp[2])
        elseif sp[1] == "gap_months"
            gap_months = parse(Int, sp[2])
        end
    end
    return target_pat, target_basin, gap_months
end
target_pat, target_basin, gap_months = read_targets(summary_file)
@info "targets from data" target_pat target_basin gap_months

# N step 後の stay 確率（pattern 単位 / basin 単位）
function compute_stay_sequences(P, pi_eq, basin_of, n_basins, N_max)
    n = size(P, 1)
    seq_pat = Vector{Float64}(undef, N_max + 1)
    seq_basin = Vector{Float64}(undef, N_max + 1)
    # N=0: 必ず一致 → 1
    seq_pat[1]   = 1.0
    seq_basin[1] = 1.0
    Pk = copy(P)
    for N in 1:N_max
        # pattern: 平衡で出発し、N step 後に同じ pattern に居る確率
        seq_pat[N+1] = sum(pi_eq .* diag(Pk))
        # basin: 平衡で出発し、N step 後に同じ basin に居る確率
        # = Σ_i pi_eq[i] * Σ_{j : basin(j)=basin(i)} P^N[i, j]
        s = 0.0
        for i in 1:n
            bi = basin_of[i]
            bi == 0 && continue
            for j in 1:n
                if basin_of[j] == bi
                    s += pi_eq[i] * Pk[i, j]
                end
            end
        end
        seq_basin[N+1] = s
        if N < N_max
            Pk = Pk * P
        end
    end
    return seq_pat, seq_basin
end

@info "computing stay sequences up to N=$(N_max)..."
seq_pat, seq_basin = compute_stay_sequences(P, pi_eq, basin_of, n_basins, N_max)
@info "stay_seq pattern samples" N1=seq_pat[2] N10=seq_pat[11] N50=seq_pat[51] N100=seq_pat[101] Nmax=seq_pat[end]
@info "stay_seq basin samples"   N1=seq_basin[2] N10=seq_basin[11] N50=seq_basin[51] N100=seq_basin[101] Nmax=seq_basin[end]

# 線形補間で N を解く
function solve_N(seq, target, N_max)
    isnan(target) && return NaN
    for N in 1:N_max
        if seq[N+1] <= target && seq[N] > target
            s_lo = seq[N]
            s_hi = seq[N+1]
            return (N - 1) + (s_lo - target) / (s_lo - s_hi)
        end
    end
    if seq[end] > target
        @warn "target never reached within N_max" seq_end=seq[end]
        return NaN
    end
    return NaN
end

N_pat   = solve_N(seq_pat,   target_pat,   N_max)
N_basin = solve_N(seq_basin, target_basin, N_max)

month_per_step_pat   = isnan(N_pat)   ? NaN : gap_months / N_pat
month_per_step_basin = isnan(N_basin) ? NaN : gap_months / N_basin

# 出力
mkpath(dirname(out_file))
open(out_file, "w") do f
    println(f, "key\tvalue")
    println(f, "method\texact (P^N)")
    println(f, "n_patterns\t$n_patterns")
    println(f, "n_basins\t$n_basins")
    println(f, "k\t$k")
    println(f, "T\t$T_temp")
    println(f, "gap_months\t$gap_months")
    println(f, "")
    println(f, "# Pattern-level calibration")
    println(f, "target_p_stay_pattern\t$target_pat")
    println(f, "selfoverlap_eq_pattern (Σπ_i^2)\t$selfoverlap_eq_pattern")
    println(f, "N_solved_pattern\t$N_pat")
    println(f, "1 step ≒ months (pattern)\t$month_per_step_pat")
    println(f, "")
    println(f, "# Basin-level calibration")
    println(f, "target_p_stay_basin\t$target_basin")
    println(f, "selfoverlap_eq_basin (Σπ_b^2)\t$selfoverlap_eq_basin")
    println(f, "pi_basin\t$(join(pi_basin, \",\"))")
    println(f, "N_solved_basin\t$N_basin")
    println(f, "1 step ≒ months (basin)\t$month_per_step_basin")
    println(f, "1 step ≒ years (basin)\t$(month_per_step_basin/12)")
    println(f, "")
    println(f, "# Diagnostics (pattern stay sequence)")
    for N in [1, 5, 10, 20, 50, 100, N_max]
        if N+1 <= length(seq_pat)
            println(f, "seq_pat[N=$N]\t$(seq_pat[N+1])")
        end
    end
    println(f, "")
    println(f, "# Diagnostics (basin stay sequence)")
    for N in [1, 5, 10, 20, 50, 100, N_max]
        if N+1 <= length(seq_basin)
            println(f, "seq_basin[N=$N]\t$(seq_basin[N+1])")
        end
    end
end

@info "done" N_pat N_basin month_per_step_basin
