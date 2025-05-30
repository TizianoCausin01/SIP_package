# to run this: 
# mpiexec -np 6 julia /Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/tests/loc_max_parallel.jl
##
using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
#cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")

##
using MPI
using JSON
using SIP_package
using Dates
using CodecZlib
##
# vars for parallel
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
merger = nproc - 1
if rank == root
	@info "--------------------- \n \n \n \n \n STARTING LOCAL MAXIMA COMPUTATION \n $(Dates.format(now(), "HH:MM:SS")) \n \n \n \n \n ---------------------"
end #if rank==root

num_of_iterations = 5
file_name = ARGS[1]
glider_coarse_g_dim = Tuple(parse(Int, ARGS[i]) for i in 2:4)
glider_dim = Tuple(parse(Int, ARGS[i]) for i in 5:7)
length_win = glider_dim[1] * glider_dim[2] * glider_dim[3]
results_path = "/leonardo_work/Sis25_piasini/tcausin/SIP_results/$(file_name)_counts_cg_$(glider_coarse_g_dim[1])x$(glider_coarse_g_dim[2])x$(glider_coarse_g_dim[3])_win_$(glider_dim[1])x$(glider_dim[2])x$(glider_dim[3])"
# results_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/$(file_name)_counts_cg_$(glider_coarse_g_dim[1])x$(glider_coarse_g_dim[2])x$(glider_coarse_g_dim[3])_win_$(glider_dim[1])x$(glider_dim[2])x$(glider_dim[3])"
loc_max_path = "$(results_path)/loc_max_$(file_name)"

for iter_idx in 1:num_of_iterations
	dict_path = "$(results_path)/counts_$(file_name)_iter$(iter_idx).json"
	@info "rank $rank before loading dict"
	myDict = json2intdict(dict_path)
	@info "rank $rank dict loaded"
	if rank == root
		@info "iter $(iter_idx) has a dict with $(length(myDict)) keys"
	end
	percentile = 10
	top_counts = get_top_windows(myDict, percentile)
	tot_counts = length(top_counts)
	jump = cld(tot_counts, nproc - 1) # performs a ceiling division to equally divide the number of windows among the processes, if we overshoot (because the ceiling approximation surpasses the total number of windows), the processor just skips the for loop inside parallel_get_loc_max
	##
	if rank == root # I am root
		global current_start = Int32(0) # is the number of iterations we will drop before our target, that's why we start from 0 
		for dst in 1:(nproc-1) # loops over the processors to deal the task
			MPI.Isend(Int32(current_start), dst, dst + 32, comm)
			global current_start += jump
		end # for i_deal in 1:(nproc-1)

		global counter_done_procs = 0
		global tot_list = Vector{Int64}([])
		while counter_done_procs != (nproc - 1)
			for src in 1:(nproc-1)
				ismessage_len, status = MPI.Iprobe(src, src + 64, comm)
				ismessage, status = MPI.Iprobe(src, src + 32, comm)
				if ismessage_len & ismessage
					length_mex = Vector{Int32}(undef, 1) # preallocates recv buffer
					req_len = MPI.Irecv!(length_mex, src, src + 64, comm)
					MPI.Wait(req_len)
					array_buffer = Vector{UInt8}(undef, length_mex[1])
					req_mex = MPI.Irecv!(array_buffer, src, src + 32, comm)
					MPI.Wait(req_mex)
					if length_mex[1] != 0 # if the process didn't find any loc_max i.e. anything to append
						max_list = MPI.deserialize(array_buffer)
						append!(tot_list, max_list)
						@info "received list from process $(src)"
					end # length_mex[1] != 0
					global counter_done_procs += 1
				end # if ismessage_len & ismessage
			end # for src in 1:(nproc-1)
		end # while counter_done_procs != (nproc - 1)
		loc_max_dict = Dict(window => myDict[window] for window in tot_list) # loops over the list of local maxima and creates a dict with the associated counts

		if !isdir(loc_max_path) # checks if the directory already exists
			mkpath(loc_max_path) # if not, it creates the folder where to put the split_files
		end # if !isdir(dir_path)        

		open("$(loc_max_path)/loc_max_$(file_name)_iter$(iter_idx).json", "w") do file
			JSON.print(file, loc_max_dict)
		end # open counts

	else # I am worker
		global stop = 0
		while stop != 1 # loops until its broken
			ismessage, status = MPI.Iprobe(root, rank + 32, comm) # checks if there is a message 
			if ismessage # if there is something to receive
				start = Vector{Int32}(undef, 1) # receive buffer
				MPI.Irecv!(start, root, rank + 32, comm) # receives stuff
				start = start[1] # takes just the first element of the vector (it's a vector because it's a receive buffer)
				loc_max = parallel_get_loc_max(myDict, top_counts, start, jump, length_win)
				loc_max = MPI.serialize(loc_max)
				len_mex = Int32(length(loc_max))
				len_req = MPI.Isend(len_mex, root, rank + 64, comm)
				@info "rank $(rank) sends list of length $(len_mex)"
				MPI.Wait(len_req)
				MPI.Isend(loc_max, root, rank + 32, comm)
                                loc_max = nothing
                                myDict = nothing
                                top_counts = nothing
			        @info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): free memory $(Sys.free_memory()/1024^3), max size by now: $(Sys.maxrss()/1024^3)"
				global stop = 1 # to break the while loop
			end # if ismessage
		end # while stop != 1
	end # if rank == root
end # for i in 1:5 

@info "proc $rank finished"
