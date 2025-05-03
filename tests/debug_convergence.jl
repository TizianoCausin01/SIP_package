using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using SIP_package
using MPI
using CodecZlib
##
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
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
##
if rank == 0
	my_dict = 1111111111111111111111111111111111111111111#generate_rand_dict(10, 100, 4)
	# my_dict = MPI.serialize(my_dict)
	# my_dict = transcode(ZlibCompressor, my_dict)
	@info "size: $(size(my_dict)) \n type: $(typeof(my_dict))"
	MPI.send(my_dict, Int32(1), 1, comm)
else
	dict_rec, status = MPI.recv(Int32(0), 1, comm)
	# dict_rec = transcode(ZlibDecompressor, dict_rec)
	# dict_rec = MPI.deserialize(dict_rec)
	@info "$dict_rec"
end #if rank==0
