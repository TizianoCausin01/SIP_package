# examples/05-job_schedule.jl
# This example demonstrates a job scheduling through adding the
# number 100 to every component of the vector data. The root
# assigns one element to each worker to compute the operation.
# When the worker is finished, the root sends another element
# until each element is added 100
# Inspired on
# https://www.hpc.ntnu.no/ntnu-hpc-group/vilje/user-guide/software/mpi-and-mpi-io-training-tutorial/basic-mpi/job-queue

using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using MPI

function job_queue(data, f)
	# normal initialization
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)
	world_size = MPI.Comm_size(comm)
	nworkers = world_size - 1

	root = 0

	MPI.Barrier(comm)
	T = eltype(data)
	N = size(data)[1]
	send_mesg = Array{T}(undef, 1) # preallocates the mex to send
	recv_mesg = Array{T}(undef, 1) # # preallocates the mex to receive

	if rank == root # I am root

		# initializes some variables
		idx_recv = 0
		idx_sent = 1
		new_data = Array{T}(undef, N)
		# Array of workers requests
		sreqs_workers = Array{MPI.Request}(undef, nworkers) # MPI.Request is a type returned by non blocking operations like Isend and Irecv
		# -1 = start, 0 = channel not available, 1 = channel available
		status_workers = fill(-1, nworkers) # all the workers are initialized

		# Send message to workers for the first time -> puts at work all the procs for the first time
		for dst in 1:nworkers # loops through all the workers other than the 0 process
			if idx_sent > N # when the jobs passed are more than the jobs already done, it exits the loop (the strict inequality bc it's at the top of the loop)
				break
			end
			send_mesg[1] = data[idx_sent] # allocates mex to send here within the data array 
			sreq = MPI.Isend(send_mesg, dst, dst + 32, comm) # 3rd arg "dst + 32" is the message tag, it has to be an non negative integer. The +32 is a convention
			idx_sent += 1 # updates idx sent
			sreqs_workers[dst] = sreq # sreq is the output of MPI.Isend (2 lines above) and is used to see if the communication was successufully completed
			status_workers[dst] = 0 # the worker is now occupied
			print("Root: Sent number $(send_mesg[1]) to Worker $dst\n")
		end

		# Send and receive messages until all elements are added
		while idx_recv != N # once the last element has been received, the loop breaks
			# Check to see if there is an available message to receive
			for dst in 1:nworkers
				if status_workers[dst] == 0
					(flag, status) = MPI.Test!(sreqs_workers[dst]) # checks if the operation has been completed (MPI.Request type updates online as the receiver receives the mex), flag is a boolean abt the status of the operation (T or F), status contains additional information about the completed communication (like source, tag, 
					if flag # as soon as something has been received
						status_workers[dst] = 1 # the proc is available again
					end
				end
			end
			for dst in 1:nworkers
				if status_workers[dst] == 1
					ismessage, status = MPI.Iprobe(dst, dst + 32, comm) # dst here is the source because the function is probing whether something has actually been sent (as a feedback by the process that received the message (dst)). ismessage is a boolean (T if there is a mex to be received, F if there isn't), status is information about the message
					if ismessage
						# Receives message
						MPI.Recv!(recv_mesg, dst, dst + 32, comm) # the root is receiving a message from the dst 
						idx_recv += 1
						new_data[idx_recv] = recv_mesg[1]
						print("Root: Received number $(recv_mesg[1]) from Worker $dst\n")
						if idx_sent <= N
							send_mesg[1] = data[idx_sent]
							# Sends new message
							sreq = MPI.Isend(send_mesg, dst, dst + 32, comm) # root sends a new message to dst
							idx_sent += 1
							sreqs_workers[dst] = sreq
							status_workers[dst] = 1
							print("Root: Sent number $(send_mesg[1]) to Worker $dst\n")
						end
					end
				end
			end
		end

		for dst in 1:nworkers
			# Termination message to worker
			send_mesg[1] = -1
			sreq = MPI.Isend(send_mesg, dst, dst + 32, comm)
			sreqs_workers[dst] = sreq
			status_workers[dst] = 0
			print("Root: Finish Worker $dst\n")
		end

		MPI.Waitall!(sreqs_workers) # waits for all pending send operations before proceeding
		print("Root: New data = $new_data\n")
	else # If rank == worker
		# -1 = start, 0 = channel not available, 1 = channel available
		status_worker = -1
		while true
			sreqs_workers = Array{MPI.Request}(undef, 1)
			ismessage, status = MPI.Iprobe(root, rank + 32, comm)

			if ismessage
				# Receives message
				MPI.Recv!(recv_mesg, root, rank + 32, comm)
				# Termination message from root
				if recv_mesg[1] == -1 # if the message it has received is -1, just terminate 
					print("Worker $rank: Finish\n")
					break
				end
				print("Worker $rank: Received number $(recv_mesg[1]) from root\n")
				# Apply function (add number 100) to array
				send_mesg = f(recv_mesg)
				sreq = MPI.Isend(send_mesg, root, rank + 32, comm) # sends the results back to root
				sreqs_workers[1] = sreq
				status_worker = 0
			end
			# Check to see if there is an available message to receive
			if status_worker == 0
				(flag, status) = MPI.Test!(sreqs_workers[1]) # if the message has been sent, changes the flag of the worker
				if flag
					status_worker = 1
				end
			end
		end
	end
	MPI.Barrier(comm)
	MPI.Finalize()
end

f = x -> x .+ 100 # this is a function definition
data = collect(1:10)
job_queue(data, f)
