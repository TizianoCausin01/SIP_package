# master, workers, mergers, master_merger
# master: allocates jobs
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
root = 0
master_merger = 1
n_mergers = parse(Int, ARGS[8])
mergers = 2:(1+n_mergers)
workers = (1+mergers[end]):(nproc-1)
name_vid = ARGS[1]
split_folder = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/$(name_vid)_split"
results_path = "/leonardo_work/Sis25_piasini/tcausin/SIP_results"
split_files = "$(split_folder)/$(name_vid)%03d.mp4"
files_names = readdir(split_folder)
n_tasks = length(files_names) # also the length of it
tasks = 1:n_tasks
# vars for sampling
num_of_iterations = 5 # counting the 0th iteration
glider_coarse_g_dim = Tuple(parse(Int, ARGS[i]) for i in 2:4)
glider_dim = Tuple(parse(Int, ARGS[i]) for i in 5:7) # rows, cols, depth
scale_block = parse(Int, ARGS[9]) # changed for bs
results_folder = "$(results_path)/block_scrambling/$(name_vid)_counts_cg_$(glider_coarse_g_dim[1])x$(glider_coarse_g_dim[2])x$(glider_coarse_g_dim[3])_win_$(glider_dim[1])x$(glider_dim[2])x$(glider_dim[3])_scale_$(scale_block)" # changed for bs
if !isdir(results_folder) # checks if the directory already exists
	mkpath(results_folder) # if not, it creates the folder where to put the split_files
end # if !isdir(dir_path)
##
if rank == root
	@info "--------------------- \n \n \n \n \n STARTING SAMPLING \n $(Dates.format(now(), "HH:MM:SS")) \n \n \n \n \n ---------------------"
end #if rank==root

##


function wrapper_sampling_parallel_bs(video_path, num_of_iterations, glider_coarse_g_dim, glider_dim, scale_block) # changed for bs
	# video conversion into BitArray
	@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): running binarization,  free memory $(Sys.free_memory()/1024^3) max size by now: $(Sys.maxrss()/1024^3)"
	flush(stdout)
	bin_vid = whole_video_conversion(video_path) # converts a target yt video into a binarized one
        bin_vid = block_scrambling(bin_vid, scale_block) # changed for bs
	# preallocation of dictionaries
	@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank) before sampling: free memory $(Sys.free_memory()/1024^3) max size by now: $(Sys.maxrss()/1024^3)"
	counts_list = Vector{Dict{Int64, UInt64}}(undef, num_of_iterations) # list of count_dicts of every iteration
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
			GC.gc()
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
		# wait till one worker tells me they are ready to do work
		ack, status = MPI.Recv(Int32, comm, MPI.Status; source=MPI.ANY_SOURCE, tag=32)
		# give some work to do to that worker
		@info "$(Dates.format(now(), "HH:MM:SS")) root: going to give a chunk of work $task_counter_root to worker $(status.source)"
		MPI.Send(Int32(task_counter_root), comm; dest=status.source, tag=32)
		global task_counter_root += 1
	end
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
			@info "$(Dates.format(now(), "HH:MM:SS")) master_merger: a new worker $(status.source) finished. So far, we have completed $(length(completed_tasks))/$n_tasks tasks. Here are the tasks completed till now: $(sort(completed_tasks))"
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
		
		end # if free_merger == nothing

	end # while task_counter_merger <= n_tasks
	for mer in mergers
		MPI.Send(Int32(-1), comm; dest=mer, tag=200)
	end # for mer in mergers



elseif in(rank, mergers) # I am merger
	@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank): I am merger"
	stop = false
	global tot_dicts = nothing
	global task_counter_merger = 1
	while !stop
		src_worker = MPI.Recv(Int32, comm; source=master_merger, tag=200)
		@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank):received a req from master"
		if src_worker == -1 # end signal from master_merger
			global stop = true
		else
			length_mex = MPI.Recv(Int32, comm; source=src_worker, tag=64)
			if @isdefined dict_buffer
				# we recycle the memory allotted to dict_buffer from one iteration to the next
				resize!(dict_buffer, length_mex)
			else
				global dict_buffer = Vector{UInt8}(undef, length_mex)
			end
				
			MPI.Recv!(dict_buffer, comm; source=src_worker, tag=32)
			@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank): received dict from $(src_worker)"
			#dict_decomp = transcode(ZlibDecompressor, dict_buffer)
			dict_decomp = MPI.deserialize(dict_buffer)
			if tot_dicts === nothing
				global tot_dicts = dict_decomp
				@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank): processed $(task_counter_merger) chunks out of $(n_tasks)"
				flush(stdout)
			else
				merge_vec_dicts(tot_dicts, dict_decomp, num_of_iterations)
				@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank): processed $(task_counter_merger) chunks out of $(n_tasks)"
				flush(stdout)
			end # if src_worker == -1
			global task_counter_merger += 1
			MPI.Send(Int32(1), comm; dest=master_merger, tag=300)
			@info "$(Dates.format(now(), "HH:MM:SS")) merger $(rank): free memory $(Sys.free_memory()/1024^3), size dict $((Base.summarysize(tot_dicts))/1024^3), max size by now: $(Sys.maxrss()/1024^3)"

		end # if ismessage
	end # while stop == 0


	mergers_convergence(rank, mergers, tot_dicts, num_of_iterations, results_folder, name_vid, comm)

	
else # I am worker
	@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank): I am worker"

	# initialize: let root know that I am ready to start working
	MPI.Send(Int32(0), comm; dest=root, tag=32)
	
	global stop = false
	while !stop # loops until its broken
		current_data = MPI.Recv(Int32, comm; source=root, tag=32)
		@info "$(Dates.format(now(), "HH:MM:SS")) rank $(rank): current_data $current_data"
		
		if current_data != -1 # if the message isn't the termination message
			current_dict = wrapper_sampling_parallel_bs(joinpath(split_folder, files_names[current_data]), num_of_iterations, glider_coarse_g_dim, glider_dim, scale_block) # changed for bs
			current_dict = MPI.serialize(current_dict)
			#current_dict = transcode(ZlibCompressor, current_dict)
			length_dict = Int32(length(current_dict))
			MPI.Send(Int32(current_data), comm; dest=master_merger, tag=100) # sends request to master_merger
                        target_merger = MPI.Recv(Int32, comm; source=master_merger, tag=100)
			MPI.Send(length_dict, comm; dest=target_merger, tag=64) # sends length of dict to merger for preallocation but with another tag (on another frequency)
			MPI.Send(current_dict, comm; dest=target_merger, tag=32) # sends dict to merger
			@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank) sent mex to $(target_merger)"
			MPI.Send(Int32(0), comm; dest=root, tag=32) # sends message to root
			@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): free memory $(Sys.free_memory()/1024^3), size dict $((Base.summarysize(current_dict))/1024^3), max size by now: $(Sys.maxrss()/1024^3)"
			current_dict = nothing
			#GC.gc()

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
