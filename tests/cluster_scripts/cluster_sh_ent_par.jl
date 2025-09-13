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
results_path = "/leonardo_work/Sis25_piasini/tcausin/SIP_results"
file_name = ARGS[1]
cg_dims = Tuple(parse(Int, ARGS[i]) for i in 2:4)
win_dims = Tuple(parse(Int, ARGS[i]) for i in 5:7) # rows, cols, depth
iterations_num = 5
counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
tot_prob_dicts = []
for iter in 1:iterations_num
    @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): ITER $iter"
    path2dict = "$(counts_path)/counts_$(file_name)_iter$(iter).json"
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
div_vec = zeros(iterations_num)
if rank == root
for i in 1:iterations_num
        @info "$(Dates.format(now(), "HH:MM:SS")) root: starting iter $i tot size: $(Base.summarysize(tot_prob_dicts)/1024^3) , max size by now $(Sys.maxrss()/1024^3)"
	div_vec[i] = tot_sh_entropy(tot_prob_dicts[i])
end # for i in 1:iterations_num
end # if rank == root
if rank == root
    writedlm("$(counts_path)/sh_ent_$(file_name).csv", div_vec, ',')
end
@info "proc $rank finished"
MPI.Finalize()
