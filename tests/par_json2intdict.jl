using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
using MPI
using SIP_package
using JSON
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
path2dict = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/oregon_counts_cg_3x3x3_win_4x4x2/counts_oregon_iter5.json"
str_dict = JSON.parsefile(path2dict)  # Parses into Dict{String, Any}

if rank == root
	d = master_json2intdict(str_dict, nproc, 64, comm)
else
	workers_json2intdict(str_dict, rank, root, 64, comm)
end
