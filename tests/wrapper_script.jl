## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")

using SIP_package

##
using Images
using VideoIO
using Statistics
using HDF5
using ImageView
using PlutoUI
using Revise
using JSON


## configuration variables assignment
# paths for preprocessing
# data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
# file_name = "test_venice" # file name across different manipulations
# file_path = "$data_dir/$file_name.mp4" # file path to the yt video
# bin_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid" # directory where we store binarized videos
# bin_file = "$bin_dir/$file_name.h5"

# # variable assignment for coarse graining
# glider_coarse_g_dim = (3, 3, 3) # rows, cols, depth
# volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
# cutoff = volume / 2 # sets the cutoff for the majority rule 

# # variables for sampling
# glider_dim = (2, 2, 2) # rows, cols, depth
# percentile = 30 # top nth part of the distribution taken into account to compute loc_max	

##
function wrapper_sampling(video_path::String, results_path::String, file_name::String, num_of_iterations::Int, glider_coarse_g_dim::Tuple{Int, Int, Int}, glider_dim::Tuple{Int, Int, Int}, percentile::Int)
	# video conversion into BitArray
	bin_vid = SIP_package.video_conversion(video_path) # converts a target yt video into a binarized one

	# sampling and computation of local maxima  
	# preallocation of dictionaries
	counts_list = Vector{Dict{BitVector, Int}}(undef, num_of_iterations) # list of count_dicts of every iteration
	loc_max_list = Vector{Vector{BitVector}}(undef, num_of_iterations) # list of loc_max of every iteration
	coarse_g_iterations = Vector{BitArray}(undef, num_of_iterations) # list of all the videos at different levels of coarse graining
	# further variables for coarse-graining
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
	cutoff = volume / 2 # sets the cutoff for the majority rule 

	coarse_g_iterations[1] = bin_vid # stores iteration 0
	for iter_idx ∈ 1:num_of_iterations
		@info "running iteration $iter_idx"
		@time begin
			if iter_idx > 0
				# samples the current iteration
				counts_list[iter_idx] = glider(coarse_g_iterations[iter_idx], glider_dim) # samples the current iteration
				loc_max_list[iter_idx] = get_loc_max(counts_list[iter_idx], percentile) # computes the local maxima
				open("$(results_path)/counts_$(file_name)_iter$(iter_idx).json", "w") do file
					JSON.print(file, counts_list[iter_idx])
				end # open counts
				open("$(results_path)/loc_max_$(file_name)_iter$(iter_idx).json", "w") do file
					JSON.print(file, loc_max_list[iter_idx])
				end # open loc_max
			end # ifS
			# coarse-graining of the current iteration
			if iter_idx < num_of_iterations
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
		end # @time
	end # for
	return counts_list, loc_max_list
end # EOF

##
data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_venice" # file name across different manipulations
video_path = "$data_dir/$file_name.mp4" # file path to the yt video
num_of_iterations = 5 # counting the 0th iteration
glider_coarse_g_dim = (3, 3, 3) # rows, cols, depth
glider_dim = (2, 2, 2) # rows, cols, depth
percentile = 30 # top nth part of the distribution taken into account to compute loc_max	
results_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results"
##
SIP_package.wrapper_sampling(video_path, results_dir, file_name, num_of_iterations, glider_coarse_g_dim, glider_dim, percentile)
##
Profile.print()
##
pprof()

