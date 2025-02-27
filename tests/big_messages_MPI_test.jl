##
# to run:
# mpiexec -np 6 julia /Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/tests/template_matching_parallel_test.jl
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")

##
using MPI
using CodecZlib
##
# vars for parallel
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
##
n = 0
if rank == 0
	a = zeros(Int32, n, n, n)
	a_ser = MPI.serialize(a) # first serialize
	a_comp = transcode(ZlibCompressor, a_ser) # then compress
	length_mex = Int32(length(a_comp))
	MPI.Send([length_mex], 1, 64, comm)
	MPI.Isend(a_comp, 1, 32, comm) # finally send
elseif rank == 1
	@info "I am rank 1"
	mex_len = Vector{Int32}(undef, 1)
	req_len = MPI.Recv!(mex_len, 0, 64, comm)
	@info "mex_len = $(mex_len)"
	b_comp = Vector{UInt8}(undef, mex_len[1])
	req_mex = MPI.Irecv!(b_comp, 0, 32, comm) # first receive
	@info "message received"
	MPI.Wait(req_mex)
	b_ser = transcode(ZlibDecompressor, b_comp) # then decompress
	@info "message decompressed"
	b = MPI.deserialize(b_ser) #then deserialize
	@info "type $(typeof(b))"
	# @info "b $(b[1,1,1])"
	@info "size $(size(b))"
end
