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


##
function generate_rand_dict(size_str, size_dict, num_of_iterations)

	if 2^size_str < size_dict
		@warn "the possible combinations of bits are less than the desired size of the dictionary"
	end
	dicts_vec = []
	for iter in 1:num_of_iterations
		my_dict = Dict{BitVector, Int}()
		for i in 1:size_dict
			key = BitVector(rand(Bool, size_str))
			val = rand(1:100)
			my_dict[key] = val
		end # for i in 1:size_dict
		push!(dicts_vec, my_dict)
	end #for iter in 1:num_of_iterations
	return dicts_vec
end # EOF
my_dicts = generate_rand_dict(5, 100, 5)
if in(rank, mergers)
	mergers_convergence(rank, mergers, my_dicts, comm)
end # if in(rank, mergers)
@info "proc $(rank) finished"
