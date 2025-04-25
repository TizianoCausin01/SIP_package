using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")

using SIP_package
using MPI

const Int = Int32
##
# vars for parallel
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
mergers = 0:(parse(Int, ARGS[1])-1)
# function get_steps(arr)
# 	levels = [collect(arr)]
# 	global count = 0
# 	@info "levels $(levels)"
# 	while length(levels[end]) > 1
# 		global count += 1
# 		@info "count : $count"
# 		@info "$(levels[count]) , $(typeof(levels[count]))"
# 		current_lvl = levels[end]
# 		@info "current_lvl $current_lvl[1:2:end] "
# 		@info "current_lvl $(current_lvl), $(typeof(current_lvl))"
# 		idx = 1:2:length(current_lvl)
# 		nxt_lvl = current_lvl[idx]
# 		@info "$(nxt_lvl), $(typeof(nxt_lvl))"
# 		push!(levels, nxt_lvl)
# 	end # while length(levels[end]) > 1
# 	return levels
# end #EOF

function generate_rand_dict(size_str, size_dict)
	my_dict = Dict{BitVector, Int}()
	for i in 1:size_dict
		key = BitVector(rand(Bool, size_str))
		val = rand(1:100)
		my_dict[key] = val
	end # for i in 1:size_dict
	return my_dict
end # EOF
my_dict = generate_rand_dict(5, 100)
if in(rank, mergers)
	levels = get_steps_convergence(mergers)
	if rank == 0
		@info "$(levels)"
	end # if rank==0
	for lev in 1:(length(levels)-1) # stops before the last el in levels
		if in(rank, levels[lev])
			if in(rank, levels[lev+1])
				if rank + 1 <= levels[lev][end] # for the margins
					idx_src = findfirst(rank .== levels[lev]) + 1
					new_dict, status = MPI.recv(levels[lev][idx_src], lev, comm)

					mergewith!(+, my_dict, new_dict)
					@info "rank $(rank): merged with dict from rank $(levels[lev][idx_src])"
				end # if proc + 1 <= length(mergers) 
			else
				idx_dst = findfirst(rank .== levels[lev]) - 1
				MPI.send(my_dict, levels[lev][idx_dst], lev, comm)

			end # if in(rank, lev)
		end # if in(rank, levels[lev])
	end # for lev in levels
end # if in(rank, mergers)
##
if rank == 0
	println(my_dict)
end
@info "proc $(rank) finished"
