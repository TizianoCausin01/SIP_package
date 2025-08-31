using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
##
using SIP_package
using DelimitedFiles
using Dates
using MPI
using JSON
##
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
results_path = "/leonardo_work/Sis25_piasini/tcausin/SIP_results"
file_name1 = ARGS[1]
file_name2 = ARGS[2]
cg_dims = Tuple(parse(Int, ARGS[i]) for i in 3:5)
win_dims = Tuple(parse(Int, ARGS[i]) for i in 6:8) # rows, cols, depth
iterations_num = 5
counts_path1 = "$(results_path)/$(file_name1)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
counts_path2 = "$(results_path)/$(file_name2)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
tot_prob_dicts1 = []
tot_prob_dicts2 = []
for iter in 1:iterations_num
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): ITER $iter dict 2"
    path2dict = "$(counts_path1)/counts_$(file_name1)_iter$(iter).json"
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): running JSON.parsefile, max size by now $(Sys.maxrss()/1024^3) "
    str_dict = JSON.parsefile(path2dict)
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): finished JSON.parsefile, max size by now $(Sys.maxrss()/1024^3)"
    if rank == root
        curr_dict = master_json2intdict(str_dict, nproc, 64, comm)
        @info "$(Dates.format(now(), "HH:MM:SS")) root: dict $iter converted, size dict: $(Base.summarysize(curr_dict)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
        curr_dict = counts2prob(curr_dict, 8) 
        push!(tot_prob_dicts1, curr_dict)
        @info "$(Dates.format(now(), "HH:MM:SS")) root: dict $iter to prob, tot size: $(Base.summarysize(tot_prob_dicts1)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
        str_dict = nothing
        curr_dict = nothing
        GC.gc()
    else
        workers_json2intdict(str_dict, rank, root, 64, comm)
        @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): dict $iter, max size by now $(Sys.maxrss()/1024^3)"
        str_dict = nothing
        GC.gc()
    end
end

for iter in 1:iterations_num
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): ITER $iter dict 2"
    path2dict = "$(counts_path2)/counts_$(file_name2)_iter$(iter).json"
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): running JSON.parsefile, max size by now $(Sys.maxrss()/1024^3) "
    str_dict = JSON.parsefile(path2dict)
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): finished JSON.parsefile, max size by now $(Sys.maxrss()/1024^3)"
    if rank == root
        curr_dict = master_json2intdict(str_dict, nproc, 64, comm)
        @info "$(Dates.format(now(), "HH:MM:SS")) root: dict $iter converted, size dict: $(Base.summarysize(curr_dict)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
        curr_dict = counts2prob(curr_dict, 8) 
        push!(tot_prob_dicts2, curr_dict)
        @info "$(Dates.format(now(), "HH:MM:SS")) root: dict $iter to prob, tot size: $(Base.summarysize(tot_prob_dicts2)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
        str_dict = nothing
        curr_dict = nothing
        GC.gc()
    else
        workers_json2intdict(str_dict, rank, root, 64, comm)
        @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): dict $iter, max size by now $(Sys.maxrss()/1024^3)"
        str_dict = nothing
        GC.gc()
    end
end
if rank == root
div_mat = zeros(iterations_num, iterations_num)
for i in 1:iterations_num
	for j in 1:i
		div_mat[i, j] = jsd(tot_prob_dicts1[i], tot_prob_dicts2[j])
	end
end

cross_folder1="$(counts_path1)/cross_jsd_$(file_name1)"
cross_folder2="$(counts_path2)/cross_jsd_$(file_name2)"
if !isdir(cross_folder1) # checks if the directory already exists
	mkpath(cross_folder1) # if not, it creates the folder where to put the split_files
end # if !isdir(dir_path)

if !isdir(cross_folder2) # checks if the directory already exists
	mkpath(cross_folder2) # if not, it creates the folder where to put the split_files
end # if !isdir(dir_path)
writedlm("$(cross_folder1)/cross_jsd_$(file_name1)_vs_$(file_name2).csv", div_mat, ',')
writedlm("$(cross_folder2)/cross_jsd_$(file_name2)_vs_$(file_name1).csv", div_mat, ',')
end
@info "proc $rank finished"
MPI.Finalize()
