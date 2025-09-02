#jsd(d1, d2)
# ##
# # number of entries
# N = 1_000   # change to 1_711_447 if you really want it that big!

# # random keys: 8-digit numbers converted to strings
# keys = string.(rand(100_000_000:999_999_999, N))

# # random values: for example integers between 1 and 10
# vals = rand(1:10, N)

# # make dictionary
# d = Dict(keys[i] => vals[i] for i in eachindex(keys))
##
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
#Pkg.develop(path="/leonardo/home/userexternal/tcausin0/SIP_package")
using SIP_package
using SIP_package: sing_kld
using DelimitedFiles
using MPI
using JSON
using Dates
using StatsBase
using StatsBase: normalize
##
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results"
# file_name = ARGS[1]
# cg_dims = Tuple(parse(Int, ARGS[i]) for i in 2:4)
# win_dims = Tuple(parse(Int, ARGS[i]) for i in 5:7) # rows, cols, depth
##
function new_json2intdict(str_dict)
	int_dict = Dict{Int64, UInt64}()      # Preallocate target dict
	for (key, value) in str_dict
		try
			int_key = parse(Int64, key)
			int_value = UInt64(value)
			int_dict[int_key] = int_value
		catch e
			println("Skipping entry ($key => $value): ", e)
		end
	end
	return int_dict
end
# ##
# KL divergence in bits
function jsdiv(p::Vector{Float64}, q::Vector{Float64})
	m = 0.5 .* (p .+ q)
	return 0.5 * kldiv(p, m) + 0.5 * kldiv(q, m)
end

function kldiv(p::Vector{Float64}, q::Vector{Float64})
	return sum(p[i] * log2(p[i] / q[i]) for i in eachindex(p) if p[i] > 0)
end

N = 1000

iterations_num = 2
#counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
tot_prob_dicts = []

mykeys = string.(rand(100_000_000:999_999_999, N))

# uniform distribution p
p = fill(1 / N, N)

# make q: biased toward the first element
q = copy(p)
q[1] += 0.1          # bump one entry
q .= normalize(q, 1) # renormalize

##

# ##
# typeof(p2)
# ##
# function avg_PDD(dict1, dict2)
# 	avg_dict = mergewith((a, b) -> (a + b) / 2.0, dict1, dict2)
# 	return avg_dict
# end

# function jsdd(dict1, dict2; eps = 1e-10)
# 	jsd = 0
# 	avg_dict = avg_PDD(dict1, dict2)
# 	for key in keys(avg_dict)
# 		val1 = get(dict1, key, 0)
# 		val2 = get(dict2, key, 0)
# 		avg_val = max(avg_dict[key], eps) # max ensures that we don't get avg_val = 0 thus causing NaN
# 		jsd += 1 / 2 * (sing_kld(val1, avg_val) + sing_kld(val2, avg_val))
# 	end # key in keys(avg_PD)
# 	return jsd
# end # EOF
##
#@info "d1 vs d2 = $(jsdd(p1,p2)), $(jsdd(p2,p1))"
##
#jsdd(p1, p2)
##

##
println("KL(p||q) = ", jsdiv(p, q), jsdiv(q, p), " bits")

# turn into Dicts with integer counts
scale = 10_000
d1 = Dict(mykeys[i] => round(Int, p[i] * scale) for i in eachindex(mykeys))
d2 = Dict(mykeys[i] => round(Int, q[i] * scale) for i in eachindex(mykeys))
##
for iter in 1:iterations_num
	# @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): ITER $iter"
	# path2dict = "$(counts_path)/counts_$(file_name)_iter$(iter).json"
	# @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): running JSON.parsefile, max size by now $(Sys.maxrss()/1024^3) "
	# str_dict = JSON.parsefile(path2dict)
	# @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): finished JSON.parsefile, max size by now $(Sys.maxrss()/1024^3)"

	if iter == 1
		@info "iter 1"
		str_dict = d1
	elseif iter == 2
		str_dict = d2
		@info "iter 2"
	end
	# path2dict = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/oregon_counts_cg_3x3x9_win_3x3x3/counts_oregon_iter3.json"
	# str_dict = JSON.parsefile(path2dict)
	if rank == root
		curr_dict = master_json2intdict(str_dict, nproc, 64, comm)
		@info "$(Dates.format(now(), "HH:MM:SS")) root: dict $iter converted, size dict: $(Base.summarysize(curr_dict)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
		curr_dict = counts2prob(curr_dict, 8)
		push!(tot_prob_dicts, curr_dict)
		@info "$(Dates.format(now(), "HH:MM:SS")) root: dict $iter to prob, tot size: $(Base.summarysize(tot_prob_dicts)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
		str_dict = nothing
		curr_dict = nothing
		GC.gc()
	else
		workers_json2intdict(str_dict, rank, root, 64, comm)
		@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): dict $iter, max size by now $(Sys.maxrss()/1024^3)"
		str_dict = nothing
		GC.gc()
	end
end
@info "$(Dates.format(now(), "HH:MM:SS")) rank $(rank) : finished iterations max size by now $(Sys.maxrss()/1024^3)"
div_mat = zeros(iterations_num, iterations_num)
if rank == root
	for i in 1:iterations_num
		for j in 1:iterations_num
			#if rank == root
			#    div_mat[i, j] = jsd_master(tot_prob_dicts[i], tot_prob_dicts[j], rank, nproc, comm)
			#@info "$(Dates.format(now(), "HH:MM:SS")) root: iter $i , $j , tot size: $(Base.summarysize(tot_prob_dicts)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
			#else 
			#    jsd_workers(root, rank, comm)
			#end
			@info "$(Dates.format(now(), "HH:MM:SS")) root: starting iter $i , $j , tot size: $(Base.summarysize(tot_prob_dicts)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
			div_mat[i, j] = jsd(tot_prob_dicts[i], tot_prob_dicts[j])
			@info "jsd $i $j = $(div_mat[i, j])"
		end # for j in 1:i
	end # for i in 1:iterations_num
end # if rank == root
if rank == root
	a = jsd(tot_prob_dicts[1], tot_prob_dicts[2])
	b = jsd(tot_prob_dicts[2], tot_prob_dicts[1])
	@info "d1 vs d2 = $a , d2 vs d1 = $b"
	p1 = counts2prob(new_json2intdict(d1), 8)
	p2 = counts2prob(new_json2intdict(d2), 8)
	@info "non parallel : d1 vs d2 = $(jsd(p1,p2)) , d2 vs d1 = $(jsd(p2,p1))"
	writedlm("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/oregon_counts_cg_3x3x9_win_3x3x3/debug_jsd.csv", div_mat, ',')
end
@info "proc $rank finished"
MPI.Finalize()
