using SIP_package
using MPI
using JSON
using Dates
using CodecZlib
const Int = Int32
##
using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
# vars for parallel
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
fn = ARGS[1]
cg_dim = Tuple(parse(Int, ARGS[i]) for i in 2:4)
win_dim = Tuple(parse(Int, ARGS[i]) for i in 5:7)
results_folder = "/leonardo_work/Sis25_piasini/tcausin/SIP_results/$(fn)_counts_cg_$(cg_dim[1])x$(cg_dim[2])x$(cg_dim[3])_win_$(win_dim[1])x$(win_dim[2])x$(win_dim[3])"
num_of_iterations = 5
old_rank = rank + 2
mergers_arr = 0:nproc
dict_vec = Vector{Dict{Int64, UInt64}}([])
for iter_idx in 1:num_of_iterations
	dict_path = "$(results_folder)/counts_$(fn)_iter$(iter_idx)_rank$(old_rank).json"
	d = json2intdict(dict_path)
	push!(dict_vec, d)
end # for i in 1:num_of_iterations

mergers_convergence(rank, mergers_arr, dict_vec, num_of_iterations, results_folder, fn, comm)
