using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
##
using SIP_package
using DelimitedFiles
using MPI
##
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
results_path = "/leonardo_work/Sis25_piasini/tcausin/SIP_results"
file_name = ARGS[1]
cg_dims = Tuple(parse(Int, ARGS[i]) for i in 2:4)
win_dims = Tuple(parse(Int, ARGS[i]) for i in 5:7) # rows, cols, depth
iterations_num = 5
counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
if rank == root
tot_prob_dicts = [counts2prob(json2intdict("$(counts_path)/counts_$(file_name)_iter$(iter).json"), 8) for iter in 1:iterations_num]
end
@info "dicts converted"
##
div_mat = zeros(iterations_num, iterations_num)
for i in 1:iterations_num
	for j in 1:i
            if rank == root
            div_mat[i, j] = jsd_master(tot_prob_dicts[i], tot_prob_dicts[j], rank, nproc, comm)
        else 
            jsd_worker(root, rank, comm)
	end
end
##
writedlm("$(counts_path)/jsd_$(file_name).csv", div_mat, ',')
