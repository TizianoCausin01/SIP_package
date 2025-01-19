## initialization
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
#Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
#using SIP_package
using MPI
const Int = Int32
# vars for parallel
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
merger = nproc - 1
tasks = 1:100 # the task list is known to everybody
n_tasks = length(tasks) # also the length of it
function f(x::Int32)::Int32 # this is the little function to perform
	#sleep(1)
	return x + 100
end  # EOF
if rank == root # I am root
	task_counter = 1 # starts from 1, takes note of the level at which we have arrived

	# initialization
	for dst in 1:(nproc-2) # loops over all the processes other than root (0th) and merger (nproc-1)
		MPI.Isend(tasks[task_counter], dst, dst + 32, comm) # sends the task to each process
		global task_counter += 1 # updates the task_counter
		if task_counter > n_tasks # in case the number of processes are more than the number of tasks, we will use less processes (we escape the initialization before)
			break
		end # task_counter > n_tasks
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
	tot_data = nothing # preallocates tot_data
	task_counter_merger = 1 # initializes a task counter in the merger, such that I don't have to handle root-merger operations
	while task_counter_merger <= n_tasks # loops over all the processes
		for src in 1:(nproc-2) # probes/ receives from all the workers
			ismessage, status = MPI.Iprobe(src, rank + 32, comm)
			if ismessage # if there is something to be received
				message_received = Vector{Int}(undef, 1)
				MPI.Irecv!(message_received, src, rank + 32, comm)
				if isnothing(tot_data)
					global tot_data = message_received
					task_counter_merger += 1
				else
					push!(tot_data, message_received[1])
					global task_counter_merger += 1
				end # if isnothing(tot_data)
			end # if ismessage
		end # for src in 1:(nproc-2)
	end # while task_counter_merger <= n_tasks
	print(length(tot_data)) # inspects tot_data 
else
	while true # loops until its broken
		ismessage, status = MPI.Iprobe(root, rank + 32, comm) # checks if there is a message 
		if ismessage # if there is something to receive
			current_data = Vector{Int32}(undef, 1) # receive buffer
			MPI.Irecv!(current_data, root, rank + 32, comm) # receives stuff
			if current_data[1] != -1 # if the message isn't the termination message
				current_data = f(current_data[1])
				MPI.Isend(current_data, merger, merger + 32, comm)
				MPI.Isend(0, root, rank + 32, comm)
			else # if it's -1 
				break
			end # if current_data[1] != -1
		end # if ismessage
	end # while true
end # if rank == root
print("\n proc $(rank) finished ")