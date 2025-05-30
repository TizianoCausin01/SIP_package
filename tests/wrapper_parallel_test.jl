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
root = 0
# vars for paths
name_vid = "test_venice_long"
path2original = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid).mp4"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split"
split_files = "$(split_folder)/$(name_vid)%03d.mp4"
# vars for sampling
num_of_iterations = 5 # counting the 0th iteration
glider_coarse_g_dim = (3, 3, 3) # rows, cols, depth
glider_dim = (2, 2, 2) # rows, cols, depth

## defines the usual function without loc_max computation (because we have split the video)
function wrapper_sampling_parallel(video_path::String, num_of_iterations::Int, glider_coarse_g_dim::Tuple{Int, Int, Int}, glider_dim::Tuple{Int, Int, Int})
	# video conversion into BitArray
	@info "running binarization"
	bin_vid = video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
	counts_list = Vector{Dict{BitVector, Int}}(undef, num_of_iterations) # list of count_dicts of every iteration
	# loc_max_list = Vector{Vector{BitVector}}(undef, num_of_iterations) # list of loc_max of every iteration
	coarse_g_iterations = Vector{BitArray}(undef, num_of_iterations) # list of all the videos at different levels of coarse graining
	# further variables for coarse-graining
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
	cutoff = volume / 2 # sets the cutoff for the majority rule 

	coarse_g_iterations[1] = bin_vid # stores iteration 0
	for iter_idx ∈ 1:num_of_iterations
		@info "running iteration $(iter_idx)"
		@info "running sampling"
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


## split video
duration = 39 # in seconds
split_vid_duration = duration / nproc
if rank == root
	split_vid(path2original, split_files, split_vid_duration)
end
MPI.Barrier(comm) # everyone has to wait the video splitting
## distribute files
file_names = readdir(split_folder) # reads the files present in split_folder
my_files = file_names[rank+1:nproc:length(file_names)] # cyclic distribution (like dealing cards) -> each process has a different rank so it will be assigned different files
fn = joinpath(split_folder, my_files[1]) # comprehension for loop to join more than one file in fn
## perform counts
myDict = wrapper_sampling_parallel(fn, num_of_iterations, glider_coarse_g_dim, glider_dim) # here we do all the job

## gather and merge
send_buf = MPI.serialize(myDict) # serializing Dict
# Gather the sizes of the serialized buffers
send_size = length(send_buf)
if rank == root # to pass the sizes
	recv_sizes = Vector{Int}(undef, nproc)  # Preallocate an array to receive the gathered data
	MPI.Gather!(Ref(send_size), recv_sizes, comm; root) # this sends only the sizes, not the whole file
else
	MPI.Gather!(Ref(send_size), nothing, comm; root) # this sends only the sizes, not the whole file
end # if rank == root to pass the sizes

if rank == root # to pass and merge the dicts
	total_size = sum(recv_sizes) # computes the total size of allocation
	recv_buf = Vector{UInt8}(undef, total_size) # preallocates
	offsets = (cumsum([0; recv_sizes[1:end-1]])) # computes the offsets of the sizes
	recv_vbuf = VBuffer(recv_buf, recv_sizes) # somehow with this buffer works but otherwise it doesn't
	MPI.Gatherv!(send_buf, recv_vbuf, root, comm) # Gatherv! because we have files of variable sizes. This is a blocking operation, hence it's first waiting for everyone to gather
	deserialized_dicts = [MPI.deserialize(recv_buf[offsets[i]+1:offsets[i]+recv_sizes[i]]) for i in 1:length(recv_sizes)]
	merged_dict = [
		mergewith(+, [deserialized_dicts[j][i] for j in 1:nproc]...)
		for i in 1:num_of_iterations
	] # merging the same levels of different dicts from different processes (double for loop comprehension and splatting)

else
	MPI.Gatherv!(send_buf, nothing, root, comm) # when rank != root the recv_buf is set to nothing
end # end if rank == root ot pass and merge the dicts

MPI.Finalize()


# broadcast to compute local maxima

# gather again


## temp function
print(rank)

