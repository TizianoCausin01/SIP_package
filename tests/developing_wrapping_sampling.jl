using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using SIP_package
using Dates
##

function wrapper_sampling_parallel(video_path, num_of_iterations, glider_coarse_g_dim, glider_dim)
	# video conversion into BitArray
	@info "proc $(rank): running binarization   $(Dates.format(now(), "HH:MM:SS"))"
	bin_vid = whole_video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
	counts_list = Vector{Dict{BitVector, UInt64}}(undef, num_of_iterations) # list of count_dicts of every iteration
	coarse_g_iterations = Vector{BitArray}(undef, num_of_iterations) # list of all the videos at different levels of coarse graining
	# further variables for coarse-graining
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
	cutoff = volume / 2 # sets the cutoff for the majority rule 

	old_vid = bin_vid # stores iteration 0 #THIS WILL BECOME OLD VID and THE OTHER NEW VID
	bin_vid = nothing
	# @info "proc $(rank): running sampling   $(Dates.format(now(), "HH:MM:SS"))"
	for iter_idx ∈ 1:num_of_iterations
		# samples the current iteration
		counts_list[iter_idx] = glider(old_vid, glider_dim) # samples the current iteration
		# coarse-graining of the current iteration
		if iter_idx < num_of_iterations
			old_dim = size(old_vid) # gets the dimensions of the current iteration
			new_dim = get_new_dimensions(old_dim, glider_coarse_g_dim) # computes the dimensions of the next iteration
			# creates a 3D tuple of vectors with the steps the coarse-graining glider will have to do
			steps_coarse_g = compute_steps_glider(glider_coarse_g_dim, old_dim) # precomputes the steps of the coarse-graining glider
			new_vid = BitArray(undef, new_dim) # preallocation of new iteration array
			fill!(new_vid, false)
			new_vid = glider_coarse_g(
				old_vid,
				new_vid,
				steps_coarse_g,
				glider_coarse_g_dim,
				cutoff,
			) # computation of new iteration array
			old_vid = new_vid
			new_vid = nothing
		end # if 
	end # for
	return counts_list
end # EOF
##
path2vid = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_data/short_split/short000.mp4"
num_of_iterations = 3
cg_dim = (3, 3, 3)
win_dim = (2, 2, 1)
##
wrapper_sampling_parallel(path2vid, num_of_iterations, cg_dim, win_dim)
