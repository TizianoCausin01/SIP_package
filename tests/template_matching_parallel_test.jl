##
# to run:
# mpiexec -np 6 julia /Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/tests/template_matching_parallel_test.jl
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
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
##
if rank == root
	@info "--------------------- \n \n \n \n \n STARTING TEMPLATE MATCHING \n $(Dates.format(now(), "HH:MM:SS")) \n \n \n \n \n ---------------------"
end #if rank==root
##
name_vid = ARGS[1]
glider_coarse_g_dim = Tuple(parse(Int, ARGS[i]) for i in 2:4)
glider_dim = Tuple(parse(Int, ARGS[i]) for i in 5:7)
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split"
results_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/$(name_vid)_counts_cg_$(glider_coarse_g_dim[1])x$(glider_coarse_g_dim[2])x$(glider_coarse_g_dim[3])_win_$(glider_dim[1])x$(glider_dim[2])x$(glider_dim[3])"
loc_max_path = "$(results_path)/loc_max_$(name_vid)"
num_of_iterations = 1
iter_idx = 1 #add a for loop if I'll need to do more than one iteration
extension_surr = 2
dict_max_path = "$(loc_max_path)/loc_max_$(name_vid)_iter$(iter_idx).json"
loc_max_dict = json2dict(dict_max_path)
##
split_files = "$(split_folder)/$(name_vid)%03d.mp4"
files_names = readdir(split_folder)
n_tasks = length(files_names) # also the length of it
tasks = 1:n_tasks

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
	global tot_dicts = nothing
	while task_counter_merger <= n_tasks # loops over all the processes
		for src in 1:(nproc-2) # probes/ receives from all the workers
			ismessage_len, status = MPI.Iprobe(src, rank + 64, comm)
			ismessage, status = MPI.Iprobe(src, rank + 32, comm)
			if ismessage & ismessage_len # if there is something to be received
				length_mex = Vector{Int32}(undef, 1) # preallocates recv buffer
				req_len = MPI.Irecv!(length_mex, src, rank + 64, comm)
				MPI.Wait(req_len)
				dict_buffer = Vector{UInt8}(undef, length_mex[1])
				dict_arrives = MPI.Irecv!(dict_buffer, src, rank + 32, comm)
				MPI.Wait(dict_arrives) # we have to wait that the dictionary fully arrives before attempting to do anything else
				if tot_dicts === nothing
					dict_ser = transcode(ZlibDecompressor, dict_buffer)
					global tot_dicts = MPI.deserialize(dict_ser)
					@info "merger: processed $(task_counter_merger) out of $(n_tasks)   $(Dates.format(now(), "HH:MM:SS"))"
					task_counter_merger += 1
				else
					dict_ser = transcode(ZlibDecompressor, dict_buffer)
					mergewith!(+, tot_dicts, MPI.deserialize(dict_ser)) # merges the new dict to the tot
					# global tot_dicts = mergewith!(+, tot_dicts, MPI.deserialize(dict_buffer)) # merges the different dicts from the different iterations together
					@info "merger: processed $(task_counter_merger) out of $(n_tasks)   $(Dates.format(now(), "HH:MM:SS"))"
					global task_counter_merger += 1
				end # if isnothing(tot_data)
			end # if ismessage
		end # for src in 1:(nproc-2)
	end # while task_counter_merger <= n_tasks
	tm_folder = "$(results_path)/template_matching_$(name_vid)"
	if !isdir(tm_folder) # checks if the directory already exists
		mkpath(tm_folder) # if not, it creates the folder where to put the split_files
	end # if !isdir(dir_path)

	for iter_idx in 1:num_of_iterations
		open("$(tm_folder)/template_matching_ext_$(extension_surr)_$(name_vid).json", "w") do file
			JSON.print(file, vectorize_surrounding_patches(tot_dicts))
		end # open counts
	end # for iter_idx in 1:num_of_iterations
else # I am worker
	while true # loops until its broken
		ismessage, status = MPI.Iprobe(root, rank + 32, comm) # checks if there is a message 
		if ismessage # if there is something to receive
			current_data = Vector{Int32}(undef, 1) # receive buffer
			MPI.Irecv!(current_data, root, rank + 32, comm) # receives stuff
			current_data = current_data[1] # takes just the first element of the vector (it's a vector because it's a receive buffer)
			if current_data != -1 # if the message isn't the termination message
				@info "proc $(rank): starting binarization   $(Dates.format(now(), "HH:MM:SS"))"
				bin_vid = whole_video_conversion(joinpath(split_folder, files_names[current_data]))
				@info "proc $(rank): video converted, starting template matching   $(Dates.format(now(), "HH:MM:SS"))"
				current_dict = template_matching(bin_vid[:, :, 1:10], loc_max_dict, glider_dim, extension_surr)
				@info "proc $(rank): template matching finished, sending results...   $(Dates.format(now(), "HH:MM:SS"))"
				serialized_dict = MPI.serialize(current_dict)
				comp_dict = transcode(ZlibCompressor, serialized_dict)
				length_dict = Int32(length(comp_dict))
				len_req = MPI.Isend(Ref(length_dict), merger, merger + 64, comm) # sends length of dict to merger for preallocation but with another tag (on another frequency)
				MPI.wait(len_req)
				dict_req = MPI.Isend(comp_dict, merger, merger + 32, comm) # sends dict to merger
				MPI.wait(dict_req)
				MPI.Isend(0, root, rank + 32, comm) # sends message to root
			else # if it's -1 
				break
			end # if current_data[1] != -1
		end # if ismessage
	end # while true

end # if rank == root
@info "proc $(rank) finished"