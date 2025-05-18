# master, workers, mergers, master_merger
# master: allocates jobs
using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")

using SIP_package
using MPI
using JSON
using Dates
using CodecZlib
const Int = Int32
##
# vars for parallel
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0


# vars for parallel
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
master_merger = 1
n_mergers = parse(Int, ARGS[8])
mergers = 2:(1+n_mergers)
workers = (1+mergers[end]):(nproc-1)
name_vid = ARGS[1]
split_folder = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/$(name_vid)_split"
results_path = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_results"
split_files = "$(split_folder)/$(name_vid)%03d.mp4"
files_names = readdir(split_folder)
n_tasks = length(files_names) # also the length of it
tasks = 1:n_tasks
# vars for sampling
num_of_iterations = 5 # counting the 0th iteration
glider_coarse_g_dim = Tuple(parse(Int, ARGS[i]) for i in 2:4)
glider_dim = Tuple(parse(Int, ARGS[i]) for i in 5:7) # rows, cols, depth
results_folder = "$(results_path)/random_counts_cg_$(glider_coarse_g_dim[1])x$(glider_coarse_g_dim[2])x$(glider_coarse_g_dim[3])_win_$(glider_dim[1])x$(glider_dim[2])x$(glider_dim[3])"
if !isdir(results_folder) # checks if the directory already exists
	mkpath(results_folder) # if not, it creates the folder where to put the split_files
end # if !isdir(dir_path)
##
if rank == root
	@info "--------------------- \n \n \n \n \n STARTING SAMPLING \n $(Dates.format(now(), "HH:MM:SS")) \n \n \n \n \n ---------------------"
end #if rank==root

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

function wrapper_sampling_parallel(video_path, num_of_iterations, glider_coarse_g_dim, glider_dim)
	# video conversion into BitArray
	@info "worker $(rank): running binarization,  free memory $(Sys.free_memory()/1024^3) max size by now: $(Sys.maxrss()/1024^3)    $(Dates.format(now(), "HH:MM:SS"))"
	flush(stdout)
	bin_vid = whole_video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
        @info "worker $(rank) before sampling: free memory $(Sys.free_memory()/1024^3) max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS"))"
counts_list = Vector{Dict{BitVector, UInt64}}(undef, num_of_iterations) # list of count_dicts of every iteration
	coarse_g_iterations = Vector{BitArray}(undef, num_of_iterations) # list of all the videos at different levels of coarse graining
	# further variables for coarse-graining
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
	cutoff = volume / 2 # sets the cutoff for the majority rule 

	old_vid = bin_vid # stores iteration 0 #THIS WILL BECOME OLD VID and THE OTHER NEW VID
	bin_vid = nothing
	for iter_idx ∈ 1:num_of_iterations
		# samples the current iteration
		counts_list[iter_idx] = glider(old_vid, glider_dim) # samples the current iteration
		# coarse-graining of the current iteration
		if iter_idx < num_of_iterations
			old_dim = size(old_vid) # gets the dimensions of the current iteration
			new_dim = get_new_dimensions(old_dim, glider_coarse_g_dim) # computes the dimensions of the next iteration
			# creates a 3D tuple of vectors with the steps the coarse-graining glider will have to do
			steps_coarse_g = compute_steps_glider(glider_coarse_g_dim, old_dim) # precomputes the steps of the coarse-graining glider
			new_vid = BitArray(undef, new_dim) # preallocation of new iteration array
			fill!(new_vid, false)
			new_vid = glider_coarse_g(
				old_vid,
				new_vid,
				steps_coarse_g,
				glider_coarse_g_dim,
				cutoff,
			) # computation of new iteration array
			old_vid = new_vid
			new_vid = nothing
GC.gc()
		end # if

	@info "worker $(rank) : iter $(iter_idx), free memory: $(Sys.free_memory()/1024^3), size dict $(Base.summarysize(counts_list)/1024^3), max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS"))"
	end # for
	@info "worker $(rank) : finished sampling, free memory: $(Sys.free_memory()/1024^3), size dict $(Base.summarysize(counts_list)/1024^3), max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS"))"
	flush(stdout)
	return counts_list
end # EOF


##
if rank == root # I am root
	@info "proc $(rank): I am root"

	task_counter_root = 1 # starts from 1, takes note of the level at which we have arrived
	# initialization
	for dst in workers # loops over all the processes other than root (0th) and merger (nproc-1)
		MPI.Isend(Int32(tasks[task_counter_root]), dst, dst + 32, comm) # sends the task to each process
		global task_counter_root += 1 # updates the task_counter
		if task_counter_root > n_tasks # in case the number of processes are more than the number of tasks, we will use less processes (we escape the initialization before)
			break
		end # task_counter_root > n_tasks
	end # for dst in 1:(nproc-2)
	while task_counter_root <= n_tasks # until we exhaust all tasks
		for dst in workers # loops over all the workers (mergers excluded)
			ismessage, status = MPI.Iprobe(dst, dst + 32, comm) # root checks if it has received any message from the dst (in this case dst is the source of the feedback message, but originally it was the dst of the task allocation)
			if ismessage # if there is any message to receive
				ack = Vector{Int32}(undef, 1) # preallocates recv buffer
				MPI.Irecv!(ack, dst, dst + 32, comm) # receives the message, to reset MPI.Iprobe
				if task_counter_root > n_tasks # in case we surpass n_tasks within the for loop
					break
				end # if task_counter > n_tasks
				MPI.Isend(Int32(tasks[task_counter_root]), dst, dst + 32, comm) # sends the new task to the free process
				global task_counter_root += 1
				@info "root: $task_counter_root"
			end # if ismessage
		end # for dst in 1:(nproc-2)
	end # while task_counter_root <= n_tasks
	# termination 
	for dst in workers # sends a message to all the workers
		MPI.Isend(Int32(-1), dst, dst + 32, comm) # signal to stop
	end # for dst in 1:(nproc-2)
elseif rank == master_merger # I am master merger
	@info "proc $(rank): I am master merger"
	global traffic_light = ones(Bool, n_mergers)
	@info "$traffic_light"
	global task_counter_merger = 1 # initializes a task counter in the merger, such that I don't have to handle root-merger operations
	global tot_dicts = nothing
	work_merge = vcat(workers, mergers)
	while task_counter_merger <= n_tasks # loops over all the processes
		for src in work_merge # probes/ receives from all the workers and the mergers
			ismessage, status = MPI.Iprobe(src, src + 100, comm)
			if ismessage
				ask = Vector{Int32}(undef, 1) # preallocates recv buffer
				req_ask = MPI.Irecv!(ask, src, src + 100, comm)
				ask = ask[1]
				if ask == 0 # comes from worker that requires a merger
					# @info "master merger received a req from worker $(src)"
					idx_free_merger = findfirst(traffic_light)
					if idx_free_merger == nothing # if there is none free
						MPI.Isend(Int32(-1), src, src + 101, comm)
					else
						free_merger = mergers[idx_free_merger]
						MPI.Isend(Int32(src), free_merger, free_merger + 200, comm) # sends a signal to the free merger
						MPI.Isend(Int32(free_merger), src, src + 101, comm) # sends the num of the free merger to the worker
						global traffic_light[idx_free_merger] = false
						@info "traffic_light $traffic_light"
					end # if free_merger == nothing
				elseif ask == 1 # comes from a merger that has become free
					@info "master merger received a req from merger $(src), free mem: $(Sys.free_memory()/1024^3),  max size by now: $(Sys.maxrss()/1024^3) $(Dates.format(now(), "HH:MM:SS"))"
					idx_new_free_merger = findfirst(src .== mergers) # takes the index of the merger that is now free
					@info "new_free_merger $(idx_new_free_merger)"
					global traffic_light[idx_new_free_merger] = true # makes the merger available
					@info "traffic_light now $(traffic_light)"
					global task_counter_merger += 1
					@info "task_counter_merger $(task_counter_merger)"
				end # if ask == 0
			end # if ismessage
		end # for src in work_merge
	end # while task_counter_merger <= n_tasks
	for mer in mergers
		MPI.Isend(Int32(-1), mer, mer + 200, comm)
	end # for mer in mergers
#FIXME add stopping condition


elseif in(rank, mergers) # I am merger
	@info "proc $(rank): I am merger"
	stop = 0
	global tot_dicts = nothing
	global task_counter_merger = 1
	while stop == 0
		ismessage, status = MPI.Iprobe(master_merger, rank + 200, comm) # while free probes for a signal to merge
		if ismessage
			src_worker = Vector{Int32}(undef, 1) # preallocates recv buffer
			req_src_worker = MPI.Irecv!(src_worker, master_merger, rank + 200, comm) # it's receiving the worker that will send the dict
			MPI.Wait(req_src_worker)
			@info "merger $(rank):received a req from master"
			src_worker = src_worker[1]
			if src_worker == -1 # end signal from master_merger
				global stop = 1
			else
				length_mex = Vector{Int32}(undef, 1) # preallocates recv buffer
				MPI.Probe(src_worker, rank + 64, comm) # waits until the dict arrives from the worker
				req_len = MPI.Irecv!(length_mex, src_worker, rank + 64, comm) # it's receiving the length of the dict
				MPI.Wait(req_len)
				dict_buffer = Vector{UInt8}(undef, length_mex[1])
				dict_arrives = MPI.Irecv!(dict_buffer, src_worker, rank + 32, comm)
				MPI.Wait(dict_arrives)
				@info "merger $(rank): received dict from $(src_worker)   $(Dates.format(now(), "HH:MM:SS"))"
				if tot_dicts === nothing
					dict_decomp = transcode(ZlibDecompressor, dict_buffer)
					global tot_dicts = MPI.deserialize(dict_decomp)
					@info "merger $(rank): processed $(task_counter_merger) chunks out of $(n_tasks)   $(Dates.format(now(), "HH:MM:SS"))"
					flush(stdout)
					global task_counter_merger += 1
					MPI.Isend(Int32(1), master_merger, rank + 100, comm)
				else
					dict_buffer = transcode(ZlibDecompressor, dict_buffer)
					dict_buffer = MPI.deserialize(dict_buffer)
					merge_vec_dicts(tot_dicts, dict_buffer, num_of_iterations)
					@info "merger $(rank): processed $(task_counter_merger) chunks out of $(n_tasks)   $(Dates.format(now(), "HH:MM:SS"))"
					global task_counter_merger += 1
					@info "merger $(rank) : $task_counter_merger"
					MPI.Isend(Int32(1), master_merger, rank + 100, comm)
dict_buffer = nothing
                                @info "merger $(rank): free memory $(Sys.free_memory()/1024^3), size dict $((Base.summarysize(tot_dicts))/1024^3), max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS"))"
                                GC.gc()
                                @info "merger $(rank): free memory $(Sys.free_memory()/1024^3), size dict $((Base.summarysize(tot_dicts))/1024^3) after GC, max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS"))"

					flush(stdout)
				end # if isnothing(tot_data)
			end # if src_worker == -1
		end # if ismessage
	end # while stop == 0

	if isdefined(Main, :tot_dicts) && tot_dicts !== nothing # checkpoints
		for iter_idx in 1:num_of_iterations
			open("$(results_folder)/counts_random_iter$(iter_idx)_rank$(rank).json", "w") do file # the folder has to be already present 
				JSON.print(file, tot_dicts[iter_idx])
			end # open counts
		end # for iter_idx in 1:num_of_iterations
	end # if isdefined(Main, :tot_dicts)

	mergers_convergence(rank, mergers, tot_dicts, num_of_iterations, results_folder, "random", comm)
else # I am worker
	@info "proc $(rank): I am worker"
	global stop = 0
	while stop == 0 # loops until its broken
		ismessage, status = MPI.Iprobe(root, rank + 32, comm) # checks if there is a message from root
		if ismessage # if there is something to receive
			current_data = Vector{Int32}(undef, 1) # receive buffer
			MPI.Irecv!(current_data, root, rank + 32, comm) # receives tasks
			current_data = current_data[1] # takes just the first element of the vector (it's a vector because it's a receive buffer)
			@info "rank $(rank): generating new data free memory: $(Sys.free_memory()/1024^3), max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS"))"
			if current_data != -1 # if the message isn't the termination message
				current_dict = generate_rand_dict(27, 2000000, num_of_iterations)				
	@info "worker $(rank) : finished sampling, free memory: $(Sys.free_memory()/1024^3), size dict $(Base.summarysize(current_dict)/1024^3), max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS"))"
current_dict = MPI.serialize(current_dict)
				current_dict = transcode(ZlibCompressor, current_dict)
				length_dict = Int32(length(current_dict))
				no_merger = true
				while no_merger == true # loops until it gets a free merger (this is because the mergers may be busy)
					ask_req = MPI.Isend(Int32(0), master_merger, rank + 100, comm) # sends request to master_merger # FIXME it sends the request but the master_merger doesn't receive it
					MPI.wait(ask_req) # waits until the reception of the request
					#@info "worker $(rank): request sent"
					MPI.Probe(master_merger, rank + 101, comm) # blocking operation because otherwise it keeps looping 
					#@info "worker request received"
					global target_merger = Vector{Int32}(undef, 1) # preallocates recv buffer
					MPI.Irecv!(target_merger, master_merger, rank + 101, comm)
					global target_merger = target_merger[1]
					if target_merger != -1
						no_merger = false
					end # if target_merger != -1
				end # while no_merger == true
				len_req = MPI.Isend(Ref(length_dict), target_merger, target_merger + 64, comm) # sends length of dict to merger for preallocation but with another tag (on another frequency)
				MPI.wait(len_req)
				dict_req = MPI.Isend(current_dict, target_merger, target_merger + 32, comm) # sends dict to merger
				MPI.wait(dict_req)
				@info "worker $(rank) sent mex to $(target_merger)"
				MPI.Isend(0, root, rank + 32, comm) # sends message to root
                                @info "worker $(rank): free memory $(Sys.free_memory()/1024^3), size dict after compression $((Base.summarysize(current_dict))/1024^3), max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS")) "
current_dict = nothing                                
GC.gc()
                                @info "worker $(rank): free memory $(Sys.free_memory()/1024^3) , max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS")) after GC"

					flush(stdout)
			else # if it's -1 
				global stop = 1
				current_dict = nothing
				GC.gc()
			end # if current_data[1] != -1
		end # if ismessage
	end # while true
end # if rank == root

@info "proc $(rank) finished"
MPI.Finalize()
