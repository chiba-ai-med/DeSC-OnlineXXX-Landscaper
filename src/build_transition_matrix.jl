using DelimitedFiles

# Arguments
h_file         = ARGS[1]   # plot/.../Landscaper/{dim}/h.tsv
J_file         = ARGS[2]   # plot/.../Landscaper/{dim}/J.tsv
allstates_file = ARGS[3]   # plot/.../Landscaper/{dim}/Allstates.tsv
T_temp         = parse(Float64, ARGS[4])  # 1.0 (ELA standard)
out_P          = ARGS[5]   # 出力: 128x128 遷移確率行列 (TSV)
out_pi         = ARGS[6]   # 出力: 128 平衡分布 (TSV)

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

# 遷移確率行列 P (Metropolis-Hastings, 1 bit flip)
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
@info "P row sums" min=minimum(sum(P, dims=2)) max=maximum(sum(P, dims=2))

# 平衡分布 (Boltzmann)
boltz = exp.(-E ./ T_temp)
pi_eq = boltz ./ sum(boltz)

# 出力: P 行列 (header なし TSV、128行 × 128列)
mkpath(dirname(out_P))
open(out_P, "w") do f
    for i in 1:n_patterns
        println(f, join(P[i, :], "\t"))
    end
end

# 出力: pi_eq (1列 TSV)
open(out_pi, "w") do f
    for i in 1:n_patterns
        println(f, pi_eq[i])
    end
end

@info "done" n_patterns
