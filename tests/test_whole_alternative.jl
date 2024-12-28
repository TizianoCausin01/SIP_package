## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using SIP_package
using Images
using VideoIO
using Statistics
using HDF5
using ImageView
using PlutoUI
using Revise
## configuration variables assignment
# paths for preprocessing

data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_venice" # file name across different manipulations
file_path = "$data_dir/$file_name.mp4" # file path to the yt video
# bin_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid" # directory where we store binarized videos
# bin_file = "$bin_dir/$file_name.h5"

##
bin_vid = video_conversion(file_path); # converts a target yt video into a binarized one
##
# variable assignment for coarse graining
glider_coarse_g_dim = (3, 3, 3) # rows, cols, depth
volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid

cutoff = volume / 2 # sets the cutoff for the majority rule 
#coarse_g_path = "$bin_dir/$file_name_iteration_$iteration_num"

# variables for sampling
glider_dim = (3, 3, 3) # rows, cols, depth

##
# Iterative cycle in which the previous coarse-graining iteration is the base for the next one


old_dim = size(bin_vid) # rows, cols, depth # local so that I can use them inside the for loop
prev_iteration = bin_vid
tot_iterations = Dict{Int, BitArray{3}}() # different coarse-graining iterations
tot_counts = Dict{Int, Dict{BitVector, Int}}() # counts of patches
tot_sorted_counts = Vector{Vector{Pair{BitVector, Int}}}() # sorted count of patches
##
for i ∈ 1:5
	@info "starting iteration $i"
	@time begin
		new_dim = get_new_dimensions(old_dim, glider_coarse_g_dim) # gets new dimensions of video for preallocation coarse graining
		steps_coarse_g = compute_steps_glider(glider_coarse_g_dim, old_dim) # creates a tuple with the steps the coarse-graining glider will have to do
		new_iteration = BitArray(undef, new_dim) # preallocation of current iteration array
		fill!(new_iteration, false)
		new_iteration = glider_coarse_g(prev_iteration, new_iteration, steps_coarse_g, glider_coarse_g_dim, cutoff) # computation of new iteration array
		tot_iterations[i] = new_iteration # storing it into the dict with all iterations
		# sampling
		counts = glider(new_iteration, glider_dim) # hoovers over the current iteration video and counts the instances of the pixels configurations
		sorted_counts = sort(collect(counts), by = x -> x[2], rev = true) # sorts the counts 
		tot_counts[i] = counts # stores the current counts into the total ones
		push!(tot_sorted_counts, sorted_counts) # stores the current sorted counts into the total ones (as a vector this time)
		old_dim = new_dim # updates the video dimensions for the next iteration
		prev_iteration = new_iteration # updates the video for the next iteration
	end
end

## just to save it

using JSON
open("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/counts_test.json", "w") do file
	JSON.print(file, tot_counts[1])
end


myDict = copy(tot_counts[iteration_idx])
loc_max = get_loc_max(myDict, 70)


