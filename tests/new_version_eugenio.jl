using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package")
using SIP_package
##
function wrapper_sampling_parallel(video_path, num_of_iterations, glider_coarse_g_dim, glider_dim)
	# video conversion into BitArray
	@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank): running binarization,  free memory $(Sys.free_memory()/1024^3) max size by now: $(Sys.maxrss()/1024^3)"
	flush(stdout)
	bin_vid = whole_video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
	@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank) before sampling: free memory $(Sys.free_memory()/1024^3) max size by now: $(Sys.maxrss()/1024^3)"
	counts_list = Vector{Dict{SBitSet{B}, UInt64}}(undef, num_of_iterations) # list of count_dicts of every iteration
	coarse_g_iterations = Vector{BitArray}(undef, num_of_iterations) # list of all the videos at different levels of coarse graining
	# further variables for coarse-graining
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
	cutoff = volume / 2 # sets the cutoff for the majority rule 

	old_vid = bin_vid # stores iteration 0 #THIS WILL BECOME OLD VID and THE OTHER NEW VID
	bin_vid = nothing
	for iter_idx ∈ 1:num_of_iterations
		# samples the current iteration
		counts_list[iter_idx] = glider(old_vid, glider_dim) # samples the current iteration
		#counts_list[iter_idx] = fake_glider(old_vid, glider_dim)
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
			GC.gc()
		end # if

		@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank) : iter $(iter_idx), free memory: $(Sys.free_memory()/1024^3), size dict $(Base.summarysize(counts_list)/1024^3), max size by now: $(Sys.maxrss()/1024^3)"
	end # for
	@info "$(Dates.format(now(), "HH:MM:SS")) worker $(rank) : finished sampling, free memory: $(Sys.free_memory()/1024^3), size dict $(Base.summarysize(counts_list)/1024^3), max size by now: $(Sys.maxrss()/1024^3)"
	flush(stdout)
	return counts_list
end # EOF

##
path2vid = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/short_split/short000.mp4"
num_of_iterations = 5
bit_vid = whole_video_conversion(path2vid)
##
d = glider(bit_vid, (2, 2, 1))
##
