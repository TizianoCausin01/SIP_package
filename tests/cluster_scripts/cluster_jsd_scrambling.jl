using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
##
Pkg.develop(path="/leonardo/home/userexternal/tcausin0/SIP_package")
using SIP_package
using DelimitedFiles
using MPI
using JSON
using Dates
##
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
file_name = ARGS[1]
cg_dims = Tuple(parse(Int, ARGS[i]) for i in 2:4)
win_dims = Tuple(parse(Int, ARGS[i]) for i in 5:7) # rows, cols, depth
scrambling_cond = ARGS[8]
@info "scrambling condition $(scrambling_cond)"
if scrambling_cond == "local"
    range = parse(Int, ARGS[9])
    stride = parse(Int, ARGS[10])
elseif scrambling_cond == "block"
    scale = parse(Int, ARGS[9])
end #if scrambling_cond == "local"
results_path = "/leonardo_work/Sis25_piasini/tcausin/SIP_results/$(scrambling_cond)_scrambling"
@info "results_path : $(results_path)"
iterations_num = 5
if scrambling_cond == "local"
    counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])_range_$(range)_stride_$(stride)"
elseif scrambling_cond == "block"
    counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])_scale_$(scale)"
end #if scrambling_cond == "local"
tot_prob_dicts = []
for iter in 1:iterations_num
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): ITER $iter"
    path2dict = "$(counts_path)/counts_$(file_name)_iter$(iter).json"
    @info "path2dict : $(path2dict)"
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): running JSON.parsefile, max size by now $(Sys.maxrss()/1024^3) "
    str_dict = JSON.parsefile(path2dict)
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): finished JSON.parsefile, max size by now $(Sys.maxrss()/1024^3)"
    if rank == root
        curr_dict = master_json2intdict(str_dict, nproc, 64, comm)
        @info "$(Dates.format(now(), "HH:MM:SS")) root: dict $iter converted, size dict: $(Base.summarysize(curr_dict)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
        curr_dict = counts2prob(curr_dict, 8) 
        push!(tot_prob_dicts, curr_dict)
        @info "$(Dates.format(now(), "HH:MM:SS")) root: dict $iter to prob, tot size: $(Base.summarysize(tot_prob_dicts)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
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
@info "$(Dates.format(now(), "HH:MM:SS")) rank $(rank) : finished iterations max size by now $(Sys.maxrss()/1024^3)"
div_mat = zeros(iterations_num, iterations_num)
if rank == root
for i in 1:iterations_num
    for j in 1:i
        #if rank == root
        #    div_mat[i, j] = jsd_master(tot_prob_dicts[i], tot_prob_dicts[j], rank, nproc, comm)
        #@info "$(Dates.format(now(), "HH:MM:SS")) root: iter $i , $j , tot size: $(Base.summarysize(tot_prob_dicts)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
        #else 
        #    jsd_workers(root, rank, comm)
        #end
        @info "$(Dates.format(now(), "HH:MM:SS")) root: starting iter $i , $j , tot size: $(Base.summarysize(tot_prob_dicts)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
	div_mat[i, j] = jsd(tot_prob_dicts[i], tot_prob_dicts[j])
    end # for j in 1:i
end # for i in 1:iterations_num
end # if rank == root
if rank == root
    writedlm("$(counts_path)/jsd_$(file_name).csv", div_mat, ',')
end
@info "proc $rank finished"
MPI.Finalize()
