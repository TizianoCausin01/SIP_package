# to run this script:
# mpiexec -np 4 julia /Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/tests/wrapper_parallel_test.jl
## initialization
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using MPI
using SIP_package

# vars for parallel
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0 # the master
merger = 1 # the procs that will merge all the dicts iteratively
# paths and file_names
name_vid = "test_venice_long"
path2original = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid).mp4"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split"
split_files = "$(split_folder)/$(name_vid)%03d.mp4"

# vars for sampling
num_of_iterations = 5 # counting the 0th iteration
glider_coarse_g_dim = (3, 3, 3) # rows, cols, depth
glider_dim = (2, 2, 2) # rows, cols, depth

# -------------------------------------------
# ----- split video part (to be added) -----
# -------------------------------------------

# initialization
# root sends the str to each process
# each process loads, samples the video, once it has finished it sends the result to the merger
# the merger continuously merges the dicts
# once there are no more videos in the folder, the master sends the termination messages to everybody


# initialization
if rank == root
	file_names = readdir(split_folder) # reads the files present in split_folder
	for dst in 2:nprocs # skip the 0th video because of possible text in the cover or something
		MPI.Isend(file_names[dst-1], dst, dst + 32, comm)
	end # for sending initialization
elseif rank == 1
	tot_counts_dict = None
else
	MPI.recv!(recv_mesg, dst, dst + 32, comm)
end # if sending initialization

while true
	if rank != 0 & rank != 1
		joinpath
		load(path2vid)
		counts_dict = wrapper_sampling
		MPI.Isend(MPI.serialize(counts_dict), merger, comm) # sends the samples to the merger
		MPI.Isend(rank, root, comm) # notifies the root that it is free
		counter += 1
		if counter == length(file_names)
			MPI.broadcast(signal_of_temination)
		end
	elseif rank == 0
		MPI.recv!(message_that_somebody_is_free)
		MPI.Isend(new_file_sent_to_that_process)
	elseif rank == 1
		new_dict = MPI.recv(src, tag, comm)
		if ~esits(tot_counts_dict)
			tot_counts_dict = MPI.deserialize(new_dict)
		else
			mergewith!(tot_counts_dict, MPI.deserialize(new_dict))
		end # if ~esits(tot_counts_dict)
	end # if
end # while




# root sends the str to each process
# each process loads, samples the video, once it has finished it sends the result to the merger
# the merger continuously merges the dicts
# once there are no more videos in the folder, the master sends the termination messages to everybody


if rank == root
	# initialize_stuff
	while task_counter <= n_tasks
		for dst in n_procs
			ismessage, status = MPI.Iprobe(etc...)
			if ismessage
				task_counter += 1
				MPI.Isend(tasks[task_counter], etc...)

			end
		end
	end
elseif rank
end
