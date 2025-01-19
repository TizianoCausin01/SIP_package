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
tasks = 1:25
n_tasks = length(tasks)
f = x -> x .+ 100 # this is a function definition
if rank == root
	task_counter = 1
	# initialization
	for dst in 1:(nproc-2)
		MPI.Isend(tasks[task_counter], dst, dst + 32, comm)
		global task_counter += 1
	end
	while task_counter < n_tasks
		for dst in 1:(nproc-2)
			ismessage, status = MPI.Iprobe(dst, dst + 32, comm)
			if ismessage
				if task_counter > n_tasks
					break
				end
				MPI.Isend(tasks[task_counter], dst, dst + 32, comm)
				global task_counter += 1
			end
		end
	end
	for dst in 1:(nproc-1)
		MPI.Isend(-1, dst, dst + 32, comm) # signal to stop
	end
elseif rank == merger
	should_break = false
	tot_data = nothing
	while true
		for src in 0:(nproc-2)
			ismessage, status = MPI.Iprobe(src, rank + 32, comm)
			if ismessage
				println("\n Merger received message from process $src")
				if src != root
					message_received = Vector{Int}(undef, 1)
					MPI.Irecv!(message_received, src, src + 32, comm)
					if isnothing(tot_data)
						global tot_data = message_received
					else
						push!(tot_data, message_received[1])
					end
				else
					#save(tot_data)
					global should_break = true
					break
				end
			end
		end
		if should_break
			break
		end
	end
else
	while true
		ismessage, status = MPI.Iprobe(root, rank + 32, comm)
		if ismessage
			current_data = Vector{Int}(undef, 1)
			MPI.Irecv!(current_data, root, rank + 32, comm)
			if current_data[1] != -1
				current_data = f(current_data)
				MPI.Isend(current_data, merger, rank + 32, comm)
				MPI.Isend(0, root, rank + 32, comm)
			else
				break
			end
		end
	end
end
print("\n proc $(rank) finished ")