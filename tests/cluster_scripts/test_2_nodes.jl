
using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
using MPI

# Initialize MPI
MPI.Init()

comm = MPI.COMM_WORLD
# Get the rank (process ID) and size (number of processes)
rank = MPI.Comm_rank(comm)
nproc = MPI.Comm_size(comm) # to establish the total number of processes used

# Get the name of the node (machine) this process is running on
hostname = MPI.Get_processor_name()

root = 0
master_merger = 1
n_mergers = parse(Int, ARGS[1])
mergers = 2:(1+n_mergers)
workers = (1+mergers[end]):(nproc-1)
# Print the rank and the node it's running on
if rank==root
@info "root $rank $(hostname): mem $(Sys.free_memory()/1024^3)"
elseif rank==master_merger
@info "master_merger $rank $(hostname): mem $(Sys.free_memory()/1024^3)"
elseif in(rank, mergers)
@info "merger $rank $(hostname): mem $(Sys.free_memory()/1024^3)"
else
@info "worker $rank $(hostname): mem $(Sys.free_memory()/1024^3)"
end
# Finalize MPI
MPI.Finalize()
