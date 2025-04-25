using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
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



function generate_rand_dict(size_str, size_dict)
	my_dict = Dict{BitVector, Int}()
	if 2^size_str < size_dict
		@warn "the possible combinations of bits are less than the desired size of the dictionary"
	end
	for i in 1:size_dict
		key = BitVector(rand(Bool, size_str))
		val = rand(1:100)
		my_dict[key] = val
	end # for i in 1:size_dict
	return my_dict
end # EOF
my_dictt = generate_rand_dict(5, 100)
if in(rank, mergers)
	mergers_convergence(rank, mergers, my_dictt, comm)
end # if in(rank, mergers)
@info "proc $(rank) finished"
