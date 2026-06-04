using DelimitedFiles
using Random

# Arguments
hfile        = ARGS[1]   # plot/.../{dim}/h.tsv          (k 行 1 列)
Jfile        = ARGS[2]   # plot/.../{dim}/J.tsv          (k x k)
allstates    = ARGS[3]   # plot/.../{dim}/Allstates.tsv  (2^k x k, ±1)
out_traj     = ARGS[4]   # 各 step ごとの pattern_id
out_visit    = ARGS[5]   # pattern_id → 訪問回数
out_trans    = ARGS[6]   # pattern_id × pattern_id 遷移カウント
T            = parse(Float64, ARGS[7])   # 温度
n_steps      = parse(Int,     ARGS[8])   # 本サンプリングの step 数
init_pid     = parse(Int,     ARGS[9])   # 初期パターン id（例: 32 = Basin 1 底）
burn_in      = parse(Int,     ARGS[10])  # burn-in step 数
seed         = length(ARGS) >= 11 ? parse(Int, ARGS[11]) : 1234

Random.seed!(seed)

# Load
h = vec(readdlm(hfile))
J = readdlm(Jfile)
S = readdlm(allstates, '\t', Int)
n_patterns, k = size(S)
@assert length(h) == k
@assert size(J) == (k, k)

# state ベクトル → pattern_id 引き
state_to_id = Dict{Vector{Int}, Int}()
for i in 1:n_patterns
    state_to_id[S[i, :]] = i
end

# 全パターンのエネルギーを前計算
function energy(s::Vector{Int}, h::Vector{Float64}, J::Matrix{Float64})
    e = -sum(h .* s)
    @inbounds for i in 1:length(s), j in (i+1):length(s)
        e -= J[i, j] * s[i] * s[j]
    end
    return e
end
E_cache = [energy(S[i, :], h, J) for i in 1:n_patterns]

function run_walk(S::Matrix{Int}, E_cache::Vector{Float64},
                  state_to_id::Dict{Vector{Int},Int},
                  init_pid::Int, T::Float64,
                  n_steps::Int, burn_in::Int,
                  n_patterns::Int, k::Int)
    s = copy(S[init_pid, :])
    cur_id = init_pid
    trajectory       = Vector{Int}(undef, n_steps)
    visit_count      = zeros(Int, n_patterns)
    transition_count = zeros(Int, n_patterns, n_patterns)
    prev_id = -1
    accepted = 0
    total_steps = burn_in + n_steps

    for step in 1:total_steps
        i = rand(1:k)
        s_new = copy(s)
        s_new[i] = -s_new[i]
        new_id = state_to_id[s_new]
        dE = E_cache[new_id] - E_cache[cur_id]

        if dE <= 0 || rand() < exp(-dE / T)
            s = s_new
            cur_id = new_id
            accepted += 1
        end

        if step > burn_in
            idx = step - burn_in
            trajectory[idx] = cur_id
            visit_count[cur_id] += 1
            if prev_id > 0
                transition_count[prev_id, cur_id] += 1
            end
            prev_id = cur_id
        end

        if step % 100_000 == 0
            @info "progress" step total=total_steps acc_rate=accepted/step
        end
    end

    return trajectory, visit_count, transition_count, accepted / total_steps
end

trajectory, visit_count, transition_count, acc_rate =
    run_walk(S, E_cache, state_to_id, init_pid, T, n_steps, burn_in, n_patterns, k)

writedlm(out_traj,  trajectory)
writedlm(out_visit, visit_count)
writedlm(out_trans, transition_count)

@info "done" n_steps=n_steps init_pid=init_pid T=T acc_rate=acc_rate
