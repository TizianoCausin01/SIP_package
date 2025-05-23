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

function send_large_data(data, dst, tag, comm)
	size_data = length(data)
	onsets = collect(0:20:size_data)
	status = MPI.send(UInt32(length(onsets)), dst, tag, comm)
	append!(onsets, size_data)
	@info "onsets $(onsets)"
	count = 0
	for ichunk in 1:length(onsets)-1
		chunk = data[onsets[ichunk]+1:onsets[ichunk+1]]
		count += 1
		status = MPI.send(chunk, dst, tag + count, comm)
		@info "sent chunk from $(onsets[ichunk]) to $(onsets[ichunk+1])"
	end # for ichunk in 1:length(onsets)-1
	@info "things sent: $(count)"
end #EOF
function rec_large_data(src, tag, comm)
	len_onsets, status = MPI.recv(src, tag, comm)
	@info "len_onsets $(len_onsets)"
	if len_onsets == 1
		tot_steps = 1
	else
		tot_steps = len_onsets
	end # if len_onsets ==1
	data_rec = Vector{UInt8}()
	count = 0
	for ichunk in 1:tot_steps
		count += 1
		chunk, status = MPI.recv(src, tag + count, comm)
		append!(data_rec, chunk)
		@info "received chunk of size $(length(chunk))"
		@info "size current data_rec: $(length(data_rec))"
	end # for ichunk in 1:length_onsets-1
	@info "things received: $(count)"
	return data_rec
end #EOF
##
if rank == 0
	my_dict = generate_rand_dict(10, 200, 4)
	my_dict = MPI.serialize(my_dict)
	my_dict = transcode(ZlibCompressor, my_dict)
	@info "length sent: $(size(my_dict)) \n type: $(typeof(my_dict))"
	send_large_data(my_dict, Int32(1), 1000, comm)
else
	dict_rec = rec_large_data(0, 1000, comm)
	#@info "$(dict_rec)"
	@info "length received: $(length(dict_rec))"
	dict_rec = transcode(ZlibDecompressor, dict_rec)
	dict_rec = MPI.deserialize(dict_rec)
	@info "$dict_rec"
end #if rank==0
