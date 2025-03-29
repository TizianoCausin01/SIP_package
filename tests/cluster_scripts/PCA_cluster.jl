# ARGS = [ file_name, n_chunks, vids_x_chunk, ratio_denom, frame_seq, n_comps]
## initialization
using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")

using SIP_package
using MPI
using Random
using Serialization
using Dates
using Statistics
using MultivariateStats
using Images
using VideoIO
using CodecZlib
##
# vars for parallel
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
@info "hello I am proc $(rank)"
root = 0
merger = nproc - 1
name_vid = ARGS[1]
split_folder = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/$(name_vid)_split"
results_path = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_results/PCs"
files_names = readdir(split_folder)
n_tasks = length(files_names) # also the length of it
tasks = collect(1:n_tasks)
shuffle!(tasks) # randomly picks the tasks
n_chunks = parse(Int, ARGS[2])
tasks = Int32.(tasks[1:n_chunks]) # randomly selects only up to n chunks
vids_x_chunk = parse(Int, ARGS[3])
tot_n_vids = n_chunks * vids_x_chunk
ratio_denom = parse(Int, ARGS[4])
frame_seq = parse(Int, ARGS[5])
n_comps = parse(Int, ARGS[6])
##
if rank == root # I am root
	@info "I am root"
	task_counter_root = 1 # starts from 1, takes note of the level at which we have arrived

	# initialization
	for dst in 1:(nproc-2) # loops over all the processes other than root (0th) and merger (nproc-1)
		MPI.Isend(tasks[task_counter_root], dst, dst + 32, comm) # sends the task to each process
		global task_counter_root += 1 # updates the task_counter
		if task_counter_root > n_chunks # in case the number of processes are more than the number of chunks to process, we will use less processes (we escape the initialization before)
			break
		end # task_counter_root > n_chunks
	end # for dst in 1:(nproc-2)
	while task_counter_root <= n_chunks # until we exhaust all chunks to process 
		for dst in 1:(nproc-2) # loops over all the workers (merger excluded)
			ismessage, status = MPI.Iprobe(dst, dst + 32, comm) # root checks if it has received any message from the dst (in this case dst is the source of the feedback message, but originally it was the dst of the task allocation)
			if ismessage # if there is any message to receive
				ack = Vector{Int32}(undef, 1) # preallocates recv buffer
				MPI.Irecv!(ack, dst, dst + 32, comm) # receives the message, to reset MPI.Iprobe
				if task_counter_root > n_chunks # in case we surpass n_chunks within the for loop
					break
				end # if task_counter > n_chunks
				MPI.Isend(tasks[task_counter_root], dst, dst + 32, comm) # sends the new task to the free process
				global task_counter_root += 1
			end # if ismessage
		end # for dst in 1:(nproc-2)
	end # while task_counter_root <= n_chunks
	# termination 
	for dst in 1:(nproc-2) # sends a message to all the workers
		MPI.Isend(Int32(-1), dst, dst + 32, comm) # signal to stop
	end # for dst in 1:(nproc-2)
elseif rank == merger  # I am merger ('ll merge the arrays)
	@info "I am merger"
	task_counter_merger = 1 # initializes a task counter in the merger, such that I don't have to handle root-merger operations
	global tot_arrays = nothing
	while task_counter_merger <= n_chunks # loops over all the processes
		for src in 1:(nproc-2) # probes/ receives from all the workers
			ismessage_len, status = MPI.Iprobe(src, rank + 64, comm)
			ismessage, status = MPI.Iprobe(src, rank + 32, comm)
			if ismessage & ismessage_len # if there is something to be received
				length_mex = Vector{Int32}(undef, 1) # preallocates recv buffer
				req_len = MPI.Irecv!(length_mex, src, rank + 64, comm)
				array_buffer = Vector{UInt8}(undef, length_mex[1])
				MPI.Wait(req_len)
				array_arrives = MPI.Irecv!(array_buffer, src, rank + 32, comm)
				MPI.Wait(array_arrives) # we have to wait that the array fully arrives before attempting to do anything else
				if tot_arrays === nothing
					array_decomp = transcode(ZlibDecompressor, array_buffer)
					global tot_arrays = MPI.deserialize(array_decomp)
					@info "merger: processed $(task_counter_merger) chunks out of $(n_chunks)   $(Dates.format(now(), "HH:MM:SS"))"
					task_counter_merger += 1
				else
					array_decomp = transcode(ZlibDecompressor, array_buffer)
					tot_arrays = hcat(tot_arrays, MPI.deserialize(array_decomp))
					@info "merger: processed $(task_counter_merger) chunks out of $(n_chunks)   $(Dates.format(now(), "HH:MM:SS"))"
					flush(stdout)
					global task_counter_merger += 1
				end # if isnothing(tot_data)
			end # if ismessage
		end # for src in 1:(nproc-2)
	end # while task_counter_merger <= n_chunks
	# whitened_arr = centering_whitening(tot_arrays, 1e-5)
	@info "starting PCA proper"
	model = MultivariateStats.fit(PCA, tot_arrays; maxoutdim = n_comps)
	comps = projection(model)
	reader2 = VideoIO.openvideo(joinpath(split_folder, files_names[1]))
	frame1, height1, width1, frame_num = get_dimensions(reader2) # reads one frame to get the dimensions of it resized
	frame_sm = imresize(frame1, ratio = 1 / ratio_denom) # resizes the frame
	height_sm, width_sm = size(frame_sm) # gets the dimensions
	global vid_comp = []
	for i_comp in 1:n_comps
		if i_comp == 1
			global vid_comp = [reshape(comps[:, i_comp], height_sm, width_sm, frame_seq)] # stores the first comp as a vec(Array{Float32, 3})
		else
			curr_comp = reshape(comps[:, i_comp], height_sm, width_sm, frame_seq)
			push!(vid_comp, curr_comp)
		end # if i_comp==1
	end # for i_comp in n_comps
	#open("$(results_path)/ICs_$(name_vid)_$(tot_n_vids)vids_$(ratio_denom)resize_$(frame_seq)frames.json", "w") do file
	#	JSON.print(file, vid_comp)
	# end
	file2save = "$(results_path)/PCs_$(name_vid)_$(tot_n_vids)vids_$(ratio_denom)resize_$(frame_seq)frames.jls"
	serialize(file2save, vid_comp)
else # I am worker
	@info "I am worker"
	while true # loops until its broken
		ismessage, status = MPI.Iprobe(root, rank + 32, comm) # checks if there is a message 
		if ismessage # if there is something to receive
			current_data = Vector{Int32}(undef, 1) # receive buffer
			MPI.Irecv!(current_data, root, rank + 32, comm) # receives stuff
			current_data = current_data[1] # takes just the first element of the vector (it's a vector because it's a receive buffer)
			if current_data != -1 # if the message isn't the termination message
				array_vids = prepare_for_ICA(joinpath(split_folder, files_names[current_data]), vids_x_chunk, ratio_denom, frame_seq)
				serialized_array = MPI.serialize(array_vids)
				comp_array = transcode(ZlibCompressor, serialized_array)
				length_array = Int32(length(comp_array))
				len_req = MPI.Isend(Ref(length_array), merger, merger + 64, comm) # sends length of array to merger for preallocation but with another tag (on another frequency)
				MPI.wait(len_req)
				array_req = MPI.Isend(comp_array, merger, merger + 32, comm) # sends array to merger
				MPI.wait(array_req)
				MPI.Isend(Int32(0), root, rank + 32, comm) # sends message to root
			else # if it's -1 
				break
			end # if current_data[1] != -1
		end # if ismessage
	end # while true

end # if rank == root
print("\n proc $(rank) finished ")
exit(0)
