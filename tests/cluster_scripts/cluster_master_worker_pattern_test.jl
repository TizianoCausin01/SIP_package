
# to run mpiexec -np 4 julia tests/master_worker_pattern_test.jl short 3 3 3 2 2 2 # 1st arg=file_name, 2-4 cg_dimensions, 5-7 glider_dimensions
# use dicts to speed up before real sampling and presend the sizes for preallocation
## initialization
using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
using InteractiveUtils
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
merger = nproc - 1
name_vid = ARGS[1]
split_folder = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/$(name_vid)_split"
results_path = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_results"
files_names = readdir(split_folder)
n_tasks = length(files_names) # also the length of it
tasks = Int32.(1:n_tasks)
# vars for sampling
num_of_iterations = 5 # counting the 0th iteration
glider_coarse_g_dim = Tuple(parse(Int, ARGS[i]) for i in 2:4)
glider_dim = Tuple(parse(Int, ARGS[i]) for i in 5:7) # rows, cols, depth
##
if rank == root
	@info "--------------------- \n \n \n \n \n STARTING SAMPLING \n $(Dates.format(now(), "HH:MM:SS")) \n \n \n \n \n ---------------------"
end #if rank==root

##

function wrapper_sampling_parallel(video_path, num_of_iterations, glider_coarse_g_dim, glider_dim)
	# video conversion into BitArray
	@info "proc $(rank): running binarization   $(Dates.format(now(), "HH:MM:SS"))"
	@info "proc $(rank) before sampling: free memory $(Sys.free_memory()/1024^3)"
	@info "proc $(rank) before sampling: used memory $(Sys.total_memory()/1024^3)"
	flush(stdout)
	bin_vid = whole_video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
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
		end # if 
	end # for
	@info "proc $(rank) after sampling: free memory $(Sys.free_memory()/1024^3)"
	for (key, val) in Base.@locals
		@info "proc $(rank) inside func: \n $(key): \n size: $(Base.summarysize(val)/1024^3)"
	end
	flush(stdout)
	return counts_list
end # EOF

##

if rank == root # I am root
	task_counter_root = 1 # starts from 1, takes note of the level at which we have arrived

	# initialization
	for dst in 1:(nproc-2) # loops over all the processes other than root (0th) and merger (nproc-1)
		MPI.Isend(tasks[task_counter_root], dst, dst + 32, comm) # sends the task to each process
		global task_counter_root += 1 # updates the task_counter
		if task_counter_root > n_tasks # in case the number of processes are more than the number of tasks, we will use less processes (we escape the initialization before)
			break
		end # task_counter_root > n_tasks
	end # for dst in 1:(nproc-2)
	while task_counter_root <= n_tasks # until we exhaust all tasks
		for dst in 1:(nproc-2) # loops over all the workers (merger excluded)
			ismessage, status = MPI.Iprobe(dst, dst + 32, comm) # root checks if it has received any message from the dst (in this case dst is the source of the feedback message, but originally it was the dst of the task allocation)
			if ismessage # if there is any message to receive
				ack = Vector{Int32}(undef, 1) # preallocates recv buffer
				MPI.Irecv!(ack, dst, dst + 32, comm) # receives the message, to reset MPI.Iprobe
				if task_counter_root > n_tasks # in case we surpass n_tasks within the for loop
					break
				end # if task_counter > n_tasks
				MPI.Isend(tasks[task_counter_root], dst, dst + 32, comm) # sends the new task to the free process
				global task_counter_root += 1
			end # if ismessage
		end # for dst in 1:(nproc-2)
	end # while task_counter_root <= n_tasks
	# termination 
	for dst in 1:(nproc-2) # sends a message to all the workers
		MPI.Isend(Int32(-1), dst, dst + 32, comm) # signal to stop
	end # for dst in 1:(nproc-2)
elseif rank == merger  # I am merger ('ll merge the dicts)

	task_counter_merger = 1 # initializes a task counter in the merger, such that I don't have to handle root-merger operations
	global tot_dicts = nothing
	while task_counter_merger <= n_tasks # loops over all the processes
		for src in 1:(nproc-2) # probes/ receives from all the workers
			ismessage_len, status = MPI.Iprobe(src, rank + 64, comm)
			ismessage, status = MPI.Iprobe(src, rank + 32, comm)
			if ismessage & ismessage_len # if there is something to be received
				@info "merger: received dict from $(src)   $(Dates.format(now(), "HH:MM:SS"))"
				length_mex = Vector{Int32}(undef, 1) # preallocates recv buffer
				req_len = MPI.Irecv!(length_mex, src, rank + 64, comm)
				dict_buffer = Vector{UInt8}(undef, length_mex[1])
				MPI.Wait(req_len)
				dict_arrives = MPI.Irecv!(dict_buffer, src, rank + 32, comm)
				MPI.Wait(dict_arrives) # we have to wait that the dictionary fully arrives before attempting to do anything else
				if tot_dicts === nothing
					dict_decomp = transcode(ZlibDecompressor, dict_buffer)
					global tot_dicts = MPI.deserialize(dict_decomp)
					@info "merger: processed $(task_counter_merger) chunks out of $(n_tasks)   $(Dates.format(now(), "HH:MM:SS"))"
					@info "merger: free memory $(Sys.free_memory()/1024^3)"
					flush(stdout)
					task_counter_merger += 1
				else
					dict_decomp = transcode(ZlibDecompressor, dict_buffer)
					[mergewith!(+, tot_dicts[iter], MPI.deserialize(dict_decomp)[iter]) for iter in 1:num_of_iterations] # merges the different dicts from the different iterations together
					@info "merger: processed $(task_counter_merger) chunks out of $(n_tasks)   $(Dates.format(now(), "HH:MM:SS"))"
					@info "merger: size first dict $(Base.summarysize(tot_dicts[1])/1024^3)Gb"
					@info "merger: size all dicts $(Base.summarysize(tot_dicts)/1024^3)Gb"
					@info "merger: free memory $(Sys.free_memory()/1024^3)"
					for (key, val) in Base.@locals
						@info "merger: \n $(key): \n size: $(Base.summarysize(val)/1024^3)"
					end
					flush(stdout)
					global task_counter_merger += 1
				end # if isnothing(tot_data)
			end # if ismessage
		end # for src in 1:(nproc-2)
	end # while task_counter_merger <= n_tasks

	results_folder = "$(results_path)/$(name_vid)_counts_cg_$(glider_coarse_g_dim[1])x$(glider_coarse_g_dim[2])x$(glider_coarse_g_dim[3])_win_$(glider_dim[1])x$(glider_dim[2])x$(glider_dim[3])"
	if !isdir(results_folder) # checks if the directory already exists
		mkpath(results_folder) # if not, it creates the folder where to put the split_files
	end # if !isdir(dir_path)

	for iter_idx in 1:num_of_iterations
		open("$(results_folder)/counts_$(name_vid)_iter$(iter_idx).json", "w") do file
			JSON.print(file, tot_dicts[iter_idx])
		end # open counts
	end # for iter_idx in 1:num_of_iterations
else
	while true # loops until its broken
		ismessage, status = MPI.Iprobe(root, rank + 32, comm) # checks if there is a message 
		if ismessage # if there is something to receive
			current_data = Vector{Int32}(undef, 1) # receive buffer
			MPI.Irecv!(current_data, root, rank + 32, comm) # receives stuff
			current_data = current_data[1] # takes just the first element of the vector (it's a vector because it's a receive buffer)
			if current_data != -1 # if the message isn't the termination message
				current_dict = wrapper_sampling_parallel(joinpath(split_folder, files_names[current_data]), num_of_iterations, glider_coarse_g_dim, glider_dim)
				@info "proc $(rank): real dict $(Base.summarysize(current_dict)/1024^3)Gb"
				serialized_dict = MPI.serialize(current_dict)
				@info "proc $(rank): serialized dict $(Base.summarysize(serialized_dict)/1024^3)Gb"
				dict_comp = transcode(ZlibCompressor, serialized_dict)
				@info "proc $(rank): compressed dict $(Base.summarysize(dict_comp)/1024^3)Gb"

				for (key, val) in Base.@locals
					@info "proc $(rank) outside func: \n $(key): \n size: $(Base.summarysize(val)/1024^3)"
				end
				flush(stdout)
				length_dict = Int32(length(dict_comp))
				@info "proc $(rank): sent len dict    $(Dates.format(now(), "HH:MM:SS"))"
				flush(stdout)
				len_req = MPI.Isend(Ref(length_dict), merger, merger + 64, comm) # sends length of dict to merger for preallocation but with another tag (on another frequency)
				MPI.wait(len_req)
				dict_req = MPI.Isend(dict_comp, merger, merger + 32, comm) # sends dict to merger
				MPI.wait(dict_req)
				MPI.Isend(0, root, rank + 32, comm) # sends message to root                         
			else # if it's -1 
				break
			end # if current_data[1] != -1
		end # if ismessage
	end # while true
end # if rank == root
@info "proc $(rank) finished"
