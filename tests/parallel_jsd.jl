using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
using MPI
using SIP_package

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
function jsd_master(d1, d2, rank, nproc, comm)
	global tot_jsd = 0
	@info "I am root"

	k1 = collect(keys(d1))
	k2 = collect(keys(d2))
	k = union(k1, k2)
	keys_num = length(k)
	@info "num keys $keys_num"
	jump = cld(keys_num, nproc - 1)
	@info "jump: $jump"
	global current_start = Int32(0) # is the number of iterations we will drop before our target, that's why we start from 0
	global tot = 0
	for dst in 1:(nproc-1) # loops over the processors to deal the task
		@info "curr proc: $dst"
		start = current_start + 1
		global current_start += jump
		finish = current_start
		if finish > keys_num
			finish = keys_num
		end # if finish > keys_num

		@info "start: $start ; finish: $finish"
		curr_keys = k[start:finish]

		global tot += length(curr_keys)
		subset_d1 = Dict(key => get!(d1, key, 0) for key in curr_keys)
		subset_d1 = MPI.serialize(subset_d1)
		subset_d2 = Dict(key => get!(d1, key, 0) for key in curr_keys)
		subset_d2 = MPI.serialize(subset_d2)
		SIP_package.send_large_data(subset_d1, dst, dst + 32, comm)
		SIP_package.send_large_data(subset_d2, dst, dst + 32, comm)

	end # for dst in 1:(nproc-1)

	if tot != keys_num
		error("the number of keys sent is different from the number of keys in the dict")
	end # if tot != keys_num
	for i in 1:(nproc-1)
		local jsd_part = MPI.recv(comm; source = MPI.ANY_SOURCE, tag = 32)
		global tot_jsd += jsd_part
	end # for i in 1:(nproc-1)
	@info "tot jsd = $tot_jsd"
end #EOF


function jsd_workers(root, rank, comm)
	d1 = SIP_package.rec_large_data(0, rank + 32, comm)
	d1 = MPI.deserialize(d1)
	d2 = SIP_package.rec_large_data(0, rank + 32, comm)
	d2 = MPI.deserialize(d2)
	jsd_part = Float32(jsd(d1, d2))
	@info "jsd_part $jsd_part"
	MPI.send(jsd_part, Int32(0), 32, comm)
end # EOF


if rank == root
	path2dict = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/oregon_counts_cg_3x3x3_win_4x4x2/counts_oregon_iter5.json"
	d1 = json2intdict(path2dict)
	d2 = d1
	jsd_master(d1, d2, rank, nproc, comm)
else
	jsd_workers(root, rank, comm)
end
##
# """
# avg_PD
# Creates the average probability distribution between two dicts for computing JSD.
# Sums the distributions and then divides by 2.
# INPUT:
# - dict1, dict2 ::Dict{BitVector, Int} -> the two dicts representing the probability distributions

# OUTPUT:
# - avg_dict::Dict{BitVector, Int} -> the average probability distribution
# """
# function avg_PD(dict1, dict2)
# 	avg_dict = mergewith(+, dict1, dict2)
# 	avg_dict = Dict(key => val / 2.0 for (key, val) in avg_dict)
# 	return avg_dict
# end


# """
# sing_kld
# Computes KLD for a sing val of x from the probability distributions P(x) and Q(x).
# INPUT:
# - p, q::Float -> values of probability distribution for a certain configuration x

# OUTPUT:
# - 0 or p * (log2(p / q)) -> from the formula of the KLD
# """
# function sing_kld(p, q)
# 	if p == 0
# 		return 0 # by convention p*log2(p) = 0 in the lim
# 	else
# 		return p * (log2(p / q))
# 	end # p == 0
# end # EOF


# """
# jsd
# Computes the Jensen-Shannon divergence, defined as jsd(P||Q) = [KLD(P||M)+KLD(Q||M)]/2 . Where M(x):=[P(x)+Q(x)]/2 
# It is a way to symmetrize the KLD. 
# INPUT:
# - dict1, dict2 ::Dict{BitVector, Int} -> the two dicts representing the probability distributions
# - ϵ::Float -> small constant to add to the configurations with probability=0 to avoid getting Inf or NaN.
# It's a conditional argument, to be specified like this: jsd(dict1, dict2; ϵ = 1e-12) 

# OUTPUT:
# - jsd::Float64 -> the result of the above operation
# """

# function jsd(dict1, dict2; eps = 1e-10)
# 	jsd = 0
# 	avg_dict = avg_PD(dict1, dict2)
# 	for key in keys(avg_dict)
# 		val1 = get!(dict1, key, 0)
# 		val2 = get!(dict2, key, 0)
# 		avg_val = max(avg_dict[key], eps) # max ensures that we don't get avg_val = 0 thus causing NaN
# 		jsd += 1 / 2 * (sing_kld(val1, avg_val) + sing_kld(val2, avg_val))
# 	end # key in keys(avg_PD)
# 	return jsd
# end # EOF
# """
# tot_sh_entropy
# Computes the Shannon's entropy of a probability distribution.
# INPUT:
# - dict_prob::Dict{BitVector, Integer} -> the dict of counts converted to probability

# OUTPUT:
# - tot_sh_entropy::AbstractFloat -> the total Shannon's entropy of the probability distribution
# """

# function tot_sh_entropy(dict_prob)::Float32
# 	sh_entropy = 0
# 	for k in keys(dict_prob)
# 		sh_entropy -= sing_sh_entropy(dict_prob[k])
# 	end # for k in keys(my_dict_prob)
# 	return sh_entropy
# end # EOF


# """
# sing_sh_entropy
# Computes the Shannon's entropy of a single bin of the histogram. Useful to go through the iterations.
# INPUT:
# - p::AbstractFloat -> the probability of a patch of pixels

# OUTPUT:
# - p*log2(p)::AbstractFloat -> to compute the entropy in the sum, or 0 -> if p==0 , by convention, because x goes to 0 quicker than log2(0) to -infinity
# """

# function sing_sh_entropy(p::AbstractFloat)::AbstractFloat
# 	if p == 0
# 		return 0
# 	else
# 		return p * log2(p) # the minus is added later
# 	end # if p == 0
# end # EOF
