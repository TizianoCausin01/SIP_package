# master, workers, mergers, master_merger
# master: allocates jobs
#using Pkg
#cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
#Pkg.activate(".")

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
master_merger = 1
n_mergers = parse(Int, ARGS[8])
mergers = 2:(1+n_mergers)
workers = (1+mergers[end]):(nproc-1)
name_vid = ARGS[1]
split_folder = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/$(name_vid)_split"
results_path = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_results"#"/leonardo_scratch/fast/Sis25_piasini/epiasini/tiziano_test_results"
split_files = "$(split_folder)/$(name_vid)%03d.mp4"
files_names = readdir(split_folder)#[1:53]
n_tasks = length(files_names) # also the length of it
tasks = 1:n_tasks
# vars for sampling
num_of_iterations = 5 # counting the 0th iteration
glider_coarse_g_dim = Tuple(parse(Int, ARGS[i]) for i in 2:4)
glider_dim = Tuple(parse(Int, ARGS[i]) for i in 5:7) # rows, cols, depth
results_folder = "$(results_path)/$(name_vid)_counts_cg_$(glider_coarse_g_dim[1])x$(glider_coarse_g_dim[2])x$(glider_coarse_g_dim[3])_win_$(glider_dim[1])x$(glider_dim[2])x$(glider_dim[3])"
if !isdir(results_folder) # checks if the directory already exists
	mkpath(results_folder) # if not, it creates the folder where to put the split_files
end # if !isdir(dir_path)
##
if rank == root
	@info "--------------------- \n \n \n \n \n STARTING SAMPLING \n $(Dates.format(now(), "HH:MM:SS")) \n \n \n \n \n ---------------------"
end #if rank==root

##


function generate_rand_dict(size_str, size_dict)

	if 2^size_str < size_dict
		@warn "the possible combinations of bits are less than the desired size of the dictionary"
	end
		my_dict = Dict{BitVector, UInt64}()
		for i in 1:size_dict
			key = BitVector(rand(Bool, size_str))
			val = UInt64(rand(1:10000000))
			my_dict[key] = val
		end # for i in 1:size_dict
	return my_dict
end # EOF

function fake_glider(bin_vid, glider_dim)
	# counts = Dict{BitVector, Int}()
	# vid_dim = size(bin_vid)
	# for i_time ∈ 1:vid_dim[3]-glider_dim[3] # step of sampling glider = 1 
	# 	idx_time = i_time:i_time+glider_dim[3]-1 # you have to subtract one, otherwise you will end up getting a bigger glider
	# 	for i_cols ∈ 1:vid_dim[2]-glider_dim[2]
	# 		idx_cols = i_cols:i_cols+glider_dim[2]-1
	# 		for i_rows ∈ 1:vid_dim[1]-glider_dim[1]
	# 			idx_rows = i_rows:i_rows+glider_dim[1]-1
	# 			window = view(bin_vid, idx_rows, idx_cols, idx_time) # index in video, gets the current window and immediately vectorizes it. 
	# 			#counts = update_count(counts, vec(window))
	# 			vec_window = vec(window)
	# 			counts[vec_window] = get!(counts, vec_window, 0) + 1
	# 		end # cols
	# 	end # rows
	# end # time
	# bin_vid = nothing
	# GC.gc()
        counts = generate_rand_dict(27,500)
	return counts
end # EOF


function wrapper_sampling_parallel(video_path, num_of_iterations, glider_coarse_g_dim, glider_dim)
	# video conversion into BitArray
	@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): running binarization,  free memory $(Sys.free_memory()/1024^3) max size by now: $(Sys.maxrss()/1024^3)"
	flush(stdout)
	bin_vid = whole_video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
	@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank) before sampling: free memory $(Sys.free_memory()/1024^3) max size by now: $(Sys.maxrss()/1024^3)"
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
                #counts_list[iter_idx] = fake_glider(old_vid, glider_dim)
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
			#GC.gc()
		end # if

		@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank) : iter $(iter_idx), free memory: $(Sys.free_memory()/1024^3), size dict $(Base.summarysize(counts_list)/1024^3), max size by now: $(Sys.maxrss()/1024^3)"
	end # for
	@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank) : finished sampling, free memory: $(Sys.free_memory()/1024^3), size dict $(Base.summarysize(counts_list)/1024^3), max size by now: $(Sys.maxrss()/1024^3)"
	flush(stdout)
	return counts_list
end # EOF


##
if rank == root # I am root
	@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank): I am root"

	task_counter_root = 1 # starts from 1, takes note of the level at which we have arrived
	
	while task_counter_root <= n_tasks
		# this is probably just an MPI.Scatter??

		# wait till one worker tells me they are ready to do work
		ack, status = MPI.Recv(Int32, comm, MPI.Status; source=MPI.ANY_SOURCE, tag=32)
		# give some work to do to that worker
		@info "$(Dates.format(now(), "HH:MM:SS")) root: going to give a chunk of work $task_counter_root to worker $(status.source)"
		MPI.Send(Int32(task_counter_root), comm; dest=status.source, tag=32)
		global task_counter_root += 1
	end
	
	# # initialization
	# for dst in workers # loops over all the processes other than root (0th) and merger (nproc-1)
	# 	MPI.Send(Int32(task_counter_root), comm; dest=dst, tag=32) # sends the task to each process
	# 	global task_counter_root += 1 # updates the task_counter
	# 	if task_counter_root > n_tasks # in case the number of processes are more than the number of tasks, we will use less processes (we escape the initialization before)
	# 		break
	# 	end # task_counter_root > n_tasks
	# end # for dst in 1:(nproc-2)
        # while task_counter_root <= n_tasks # until we exhaust all tasks
        #         ack, status = MPI.Recv(Int32, comm, MPI.Status; source=MPI.ANY_SOURCE, tag=32) # tag 32 is reserved for communications between root and workers
	# 	global task_counter_root += 1
	# 	if task_counter_root > n_tasks
	# 		break
	# 	end
	# 	MPI.Send(Int32(task_counter_root), comm; dest=status.source, tag=32)
	# end
		
	# 	for dst in workers # loops over all the workers (mergers excluded)
	# 		ismessage, status = MPI.Iprobe(dst, dst + 32, comm) # root checks if it has received any message from the dst (in this case dst is the source of the feedback message, but originally it was the dst of the task allocation)
	# 		if ismessage # if there is any message to receive
	# 			ack = Vector{Int32}(undef, 1) # preallocates recv buffer
	# 			MPI.Irecv!(ack, dst, dst + 32, comm) # receives the message, to reset MPI.Iprobe
	# 			if task_counter_root > n_tasks # in case we surpass n_tasks within the for loop
	# 				break
	# 			end # if task_counter > n_tasks
	# 			MPI.Isend(Int32(tasks[task_counter_root]), dst, dst + 32, comm) # sends the new task to the free process
	# 			global task_counter_root += 1
	# 			@info "root: $task_counter_root"
	# 		end # if ismessage
	# 	end # for dst in 1:(nproc-2)
	# end # while task_counter_root <= n_tasks
	# termination 
	for dst in workers # sends a message to all the workers
		MPI.Send(Int32(-1), comm; dest=dst, tag=32) # signal to stop
	end # for dst in 1:(nproc-2)

	
elseif rank == master_merger # I am master merger
	@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank): I am master merger"
	global traffic_light = ones(Bool, n_mergers)
	@info "$(Dates.format(now(), "HH:MM:SS")) $traffic_light"
	#global task_counter_merger = 1 # initializes a task counter in the merger, such that I don't have to handle root-merger operations
	global tot_dicts = nothing
	global completed_tasks = Vector{Int32}(undef, 0)
	work_merge = vcat(workers, mergers)
	while length(completed_tasks) < n_tasks #task_counter_merger <= n_tasks + 1 # loops over all the processes (+1 to catch the last merger that will become available, but which we do not have to assign a new task)
		idx_free_merger = findfirst(traffic_light)
		
		if idx_free_merger !== nothing  # we have at least one merger available and the workers still have tasks to do
			@info "$(Dates.format(now(), "HH:MM:SS")) master_merger: I have an available merger $idx_free_merger; waiting for a worker"
			msg, status = MPI.Recv(Int32, comm, MPI.Status; source=MPI.ANY_SOURCE, tag=100)
			push!(completed_tasks, msg)
			@info "$(Dates.format(now(), "HH:MM:SS")) master_merger: a new worker finished. Here are the tasks completed till now: $(sort(completed_tasks))"
			
		# for src in work_merge # probes/ receives from all the workers and the mergers
		# 	ismessage, status = MPI.Iprobe(src, src + 100, comm)
		# 	if ismessage
		# 		ask = Vector{Int32}(undef, 1) # preallocates recv buffer
		# 		req_ask = MPI.Irecv!(ask, src, src + 100, comm)
		#		ask = ask[1]
		#if ask == 0 # comes from worker that requires a merger
			# @info "master merger received a req from worker $(src)"
			idx_free_merger = findfirst(traffic_light) # TODO: shouldn't this be picked at random?
			free_merger = mergers[idx_free_merger]
			MPI.Send(Int32(status.source), comm; dest=free_merger, tag=200) # sends a signal to the free merger
			MPI.Send(Int32(free_merger), comm; dest=status.source, tag=100) # sends the num of the free merger to the worker
			global traffic_light[idx_free_merger] = false

			@info "$(Dates.format(now(), "HH:MM:SS")) found an available merger $free_merger and gave it something to do from worker $(status.source)"
		else
			# this is the case where all mergers are
			# busy. In this case we simply wait for a
			# merger to signal that it's done.
			msg, status = MPI.Recv(Int32, comm, MPI.Status; source=MPI.ANY_SOURCE, tag=300) # wait for a merger to become free
			@info "$(Dates.format(now(), "HH:MM:SS")) master merger received a req from merger $(status.source), free mem: $(Sys.free_memory()/1024^3),  max size by now: $(Sys.maxrss()/1024^3)"
			idx_new_free_merger = findfirst(status.source .== mergers);
			@info "$(Dates.format(now(), "HH:MM:SS")) new_free_merger $(idx_new_free_merger)"
			global traffic_light[idx_new_free_merger] = true # makes the merger available
			@info "$(Dates.format(now(), "HH:MM:SS")) traffic_light now $(traffic_light)"
			#global task_counter_merger += 1
			#@info "$(Dates.format(now(), "HH:MM:SS")) task_counter_merger $(task_counter_merger)"
		
		end # if free_merger == nothing
		#@info "$(Dates.format(now(), "HH:MM:SS")) traffic_light $traffic_light; task_counter_merger $task_counter_merger"
	end # while task_counter_merger <= n_tasks
	#@info "$(Dates.format(now(), "HH:MM:SS")) done with the mergers, I did more than $n_tasks. traffic_light $traffic_light; task_counter_merger $task_counter_merger"
	for mer in mergers
		MPI.Send(Int32(-1), comm; dest=mer, tag=200)
	end # for mer in mergers
#FIXME add stopping condition


elseif in(rank, mergers) # I am merger
	@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank): I am merger"
	stop = false
	global tot_dicts = nothing
	global task_counter_merger = 1
	while !stop
		src_worker = MPI.Recv(Int32, comm; source=master_merger, tag=200)
		# ismessage, status = MPI.Iprobe(master_merger, rank + 200, comm) # while free probes for a signal to merge
		# if ismessage
		# 	src_worker = Vector{Int32}(undef, 1) # preallocates recv buffer
		# 	req_src_worker = MPI.Irecv!(src_worker, master_merger, rank + 200, comm) # it's receiving the worker that will send the dict
		# 	MPI.Wait(req_src_worker)
		#	src_worker = src_worker[1]
		@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank):received a req from master"
		if src_worker == -1 # end signal from master_merger
			global stop = true
		else
			length_mex = MPI.Recv(Int32, comm; source=src_worker, tag=64)
			#length_mex = Vector{Int32}(undef, 1) # preallocates recv buffer
			#MPI.Probe(src_worker, rank + 64, comm) # waits until the dict arrives from the worker
			#req_len = MPI.Irecv!(length_mex, src_worker, rank + 64, comm) # it's receiving the length of the dict
			#MPI.Wait(req_len)
			if @isdefined dict_buffer
				# we recycle the memory allotted to dict_buffer from one iteration to the next
				resize!(dict_buffer, length_mex)
			else
				global dict_buffer = Vector{UInt8}(undef, length_mex)
			end
				
			MPI.Recv!(dict_buffer, comm; source=src_worker, tag=32)
			#MPI.Wait(dict_arrives)
			@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank): received dict from $(src_worker)"
			dict_decomp = transcode(ZlibDecompressor, dict_buffer)
			dict_decomp = MPI.deserialize(dict_decomp)
			if tot_dicts === nothing
				global tot_dicts = dict_decomp
				@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank): processed $(task_counter_merger) chunks out of $(n_tasks)"
				flush(stdout)
			else
				merge_vec_dicts(tot_dicts, dict_decomp, num_of_iterations)
				@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank): processed $(task_counter_merger) chunks out of $(n_tasks)"
				# dict_buffer = nothing
                                #GC.gc()
				#@info "merger $(rank): free memory $(Sys.free_memory()/1024^3), size dict $((Base.summarysize(tot_dicts))/1024^3) after GC, max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS"))"
				flush(stdout)
			end # if src_worker == -1
			global task_counter_merger += 1
			MPI.Send(Int32(1), comm; dest=master_merger, tag=300)
			@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank): free memory $(Sys.free_memory()/1024^3), size dict $((Base.summarysize(tot_dicts))/1024^3), max size by now: $(Sys.maxrss()/1024^3)"

		end # if ismessage
	end # while stop == 0

	if (@isdefined tot_dicts) && tot_dicts !== nothing # checkpoints
		for iter_idx in 1:num_of_iterations
			open("$(results_folder)/counts_$(name_vid)_iter$(iter_idx)_rank$(rank).json", "w") do file # the folder has to be already present 
				JSON.print(file, tot_dicts[iter_idx])
			end # open counts
		end # for iter_idx in 1:num_of_iterations
	end # if isdefined(Main, :tot_dicts)

	mergers_convergence(rank, mergers, tot_dicts, num_of_iterations, results_folder, name_vid, comm)

	
else # I am worker
	@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank): I am worker"

	# initialize: let root know that I am ready to start working
	MPI.Send(Int32(0), comm; dest=root, tag=32)
	
	global stop = false
	while !stop # loops until its broken
		current_data = MPI.Recv(Int32, comm; source=root, tag=32)
		@info "$(Dates.format(now(), "HH:MM:SS")) rank $(rank): current_data $current_data"
		
		# ismessage, status = MPI.Iprobe(root, rank + 32, comm) # checks if there is a message from root
		# if ismessage # if there is something to receive
		# 	current_data = Vector{Int32}(undef, 1) # receive buffer
		# 	MPI.Irecv!(current_data, root, rank + 32, comm) # receives tasks
		# 	current_data = current_data[1] # takes just the first element of the vector (it's a vector because it's a receive buffer)
		# 	@info "rank $(rank): current_data $(current_data[1])"
		if current_data != -1 # if the message isn't the termination message
			current_dict = wrapper_sampling_parallel(joinpath(split_folder, files_names[current_data]), num_of_iterations, glider_coarse_g_dim, glider_dim)
			current_dict = MPI.serialize(current_dict)
			current_dict = transcode(ZlibCompressor, current_dict)
			length_dict = Int32(length(current_dict))
			#no_merger = true
                            
			#while no_merger == true # loops until it gets a free merger (this is because the mergers may be busy)
			MPI.Send(Int32(current_data), comm; dest=master_merger, tag=100) # sends request to master_merger # FIXME it sends the request but the master_merger doesn't receive it
			#MPI.wait(ask_req) # waits until the reception of the request
			#@info "worker $(rank): request sent"
			#MPI.Probe(master_merger, rank + 101, comm) # blocking operation because otherwise it keeps looping 
			#@info "worker request received"
			#global target_merger = Vector{Int32}(undef, 1) # preallocates recv buffer
                        target_merger = MPI.Recv(Int32, comm; source=master_merger, tag=100)
                        #MPI.Irecv!(target_merger, master_merger, rank + 101, comm)
			#global target_merger = target_merger[1]
				# if target_merger != -1
				# 	no_merger = false
				#end # if target_merger != -1
			#end # while no_merger == true
			MPI.Send(length_dict, comm; dest=target_merger, tag=64) # sends length of dict to merger for preallocation but with another tag (on another frequency)
			#MPI.wait(len_req)
			MPI.Send(current_dict, comm; dest=target_merger, tag=32) # sends dict to merger
			#MPI.wait(dict_req)
			@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank) sent mex to $(target_merger)"
			MPI.Send(Int32(0), comm; dest=root, tag=32) # sends message to root
			@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): free memory $(Sys.free_memory()/1024^3), size dict $((Base.summarysize(current_dict))/1024^3), max size by now: $(Sys.maxrss()/1024^3)"
			current_dict = nothing
			#GC.gc()
			#@info "worker $(rank): free memory $(Sys.free_memory()/1024^3), max size by now: $(Sys.maxrss()/1024^3)   $(Dates.format(now(), "HH:MM:SS")) after GC"

			flush(stdout)
		else # if it's -1 
			global stop = true
			current_dict = nothing
			#GC.gc()
		end # if current_data[1] != -1
	end # while true
end # if rank == root

@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank) finished"
MPI.Finalize()
