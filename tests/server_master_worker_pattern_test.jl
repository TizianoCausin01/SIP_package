# to run this script:
# mpiexec -np 4 julia /home/tcausin/SIP_package/tests/server_master_worker_pattern_test.jl
## initialization
using Pkg
cd("/home/tcausin/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/home/tcausin/SIP_package/")
using MPI
using SIP_package
using Dates
# vars for parallel
const Int = Int32

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
merger = nproc - 1
# vars for paths
name_vid = "10_mins"
path2original = "/home/tcausin/data/SIP_data/$(name_vid).mp4"
split_folder = "/home/tcausin/data/SIP_data/$(name_vid)_split"
#split_files = "$(split_folder)/$(name_vid)%03d.mp4"# use dicts to speed up before real sampling and presend the sizes for preallocation
files_names = readdir(split_folder)
n_tasks = length(files_names) # also the length of it
tasks = Int32.(1:n_tasks)
# vars for sampling
num_of_iterations = 5 # counting the 0th iteration
glider_coarse_g_dim = (3, 3, 3) # rows, cols, depth
glider_dim = (2, 2, 2) # rows, cols, depth
##
function wrapper_sampling_parallel(video_path, num_of_iterations, glider_coarse_g_dim, glider_dim)
	# video conversion into BitArray
	@info "running binarization   $(Dates.format(now(), "HH:MM:SS"))"
	bin_vid = video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
	counts_list = Vector{Dict{BitVector, Int32}}(undef, num_of_iterations) # list of count_dicts of every iteration
	# loc_max_list = Vector{Vector{BitVector}}(undef, num_of_iterations) # list of loc_max of every iteration
	coarse_g_iterations = Vector{BitArray}(undef, num_of_iterations) # list of all the videos at different levels of coarse graining
	# further variables for coarse-graining
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
	cutoff = volume / 2 # sets the cutoff for the majority rule 

	coarse_g_iterations[1] = bin_vid # stores iteration 0
	for iter_idx ∈ 1:num_of_iterations
		@info "running iteration $(iter_idx)   $(Dates.format(now(), "HH:MM:SS"))"
		# samples the current iteration
		counts_list[iter_idx] = glider(coarse_g_iterations[iter_idx], glider_dim) # samples the current iteration
		# coarse-graining of the current iteration
		if iter_idx < num_of_iterations
			@info "running coarse-graining"
			old_dim = size(coarse_g_iterations[iter_idx]) # gets the dimensions of the current iteration
			new_dim = get_new_dimensions(old_dim, glider_coarse_g_dim) # computes the dimensions of the next iteration
			# creates a 3D tuple of vectors with the steps the coarse-graining glider will have to do
			steps_coarse_g = compute_steps_glider(glider_coarse_g_dim, old_dim) # precomputes the steps of the coarse-graining glider
			coarse_g_iterations[iter_idx+1] = BitArray(undef, new_dim) # preallocation of new iteration array
			fill!(coarse_g_iterations[iter_idx+1], false)
			print(typeof(coarse_g_iterations[iter_idx+1]))
			coarse_g_iterations[iter_idx+1] = glider_coarse_g(
				coarse_g_iterations[iter_idx],
				coarse_g_iterations[iter_idx+1],
				steps_coarse_g,
				glider_coarse_g_dim,
				cutoff,
			) # computation of new iteration array
		end # if 
	end # for
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
		MPI.Isend(-1, dst, dst + 32, comm) # signal to stop
	end # for dst in 1:(nproc-2)
elseif rank == merger  # I am merger ('ll merge the dicts)
	task_counter_merger = 1 # initializes a task counter in the merger, such that I don't have to handle root-merger operations
	while task_counter_merger <= n_tasks # loops over all the processes
		for src in 1:(nproc-2) # probes/ receives from all the workers
			ismessage_len, status = MPI.Iprobe(src, rank + 64, comm)
			ismessage, status = MPI.Iprobe(src, rank + 32, comm)
			if ismessage & ismessage_len # if there is something to be received
				length_mex = Vector{Int32}(undef, 1) # preallocates recv buffer
				req_len = MPI.Irecv!(length_mex, src, rank + 64, comm)
				dict_buffer = Vector{UInt8}(undef, length_mex[1])
				MPI.Wait(req_len)
				dict_arrives = MPI.Irecv!(dict_buffer, src, rank + 32, comm)
				MPI.Wait(dict_arrives) # we have to wait that the dictionary fully arrives before attempting to do anything else
				if !@isdefined tot_dicts
					global tot_dicts = MPI.deserialize(dict_buffer)
					task_counter_merger += 1
				else
					global tot_dicts = [mergewith!(+, tot_dicts[iter], MPI.deserialize(dict_buffer)[iter]) for iter in 1:num_of_iterations] # merges the different dicts from the different iterations together
					# global tot_dicts = mergewith!(+, tot_dicts, MPI.deserialize(dict_buffer)) # merges the different dicts from the different iterations together
					global task_counter_merger += 1
				end # if isnothing(tot_data)
				@info "processed $(task_counter_merger) chunks out of $(n_tasks)   $(Dates.format(now(), "HH:MM:SS"))"
			end # if ismessage
		end # for src in 1:(nproc-2)
	end # while task_counter_merger <= n_tasks

else
	while true # loops until its broken
		ismessage, status = MPI.Iprobe(root, rank + 32, comm) # checks if there is a message 
		if ismessage # if there is something to receive
			current_data = Vector{Int32}(undef, 1) # receive buffer
			MPI.Irecv!(current_data, root, rank + 32, comm) # receives stuff
			current_data = current_data[1] # takes just the first element of the vector (it's a vector because it's a receive buffer)
			if current_data != -1 # if the message isn't the termination message
				current_dict = wrapper_sampling_parallel(joinpath(split_folder, files_names[current_data]), num_of_iterations, glider_coarse_g_dim, glider_dim)
				# JSON_dict = JSON.parsefile(joinpath(split_folder, files_names[current_data]))
				# current_dict = convert_to_bitvector_dict(JSON_dict)
				serialized_dict = MPI.serialize(current_dict)
				length_dict = Int32(length(serialized_dict))
				len_req = MPI.Isend(Ref(length_dict), merger, merger + 64, comm) # sends length of dict to merger for preallocation but with another tag (on another frequency)
				MPI.wait(len_req)
				dict_req = MPI.Isend(serialized_dict, merger, merger + 32, comm) # sends dict to merger
				MPI.wait(dict_req)
				MPI.Isend(0, root, rank + 32, comm) # sends message to root
			else # if it's -1 
				break
			end # if current_data[1] != -1
		end # if ismessage
	end # while true
end # if rank == root
print("\n proc $(rank) finished ")
