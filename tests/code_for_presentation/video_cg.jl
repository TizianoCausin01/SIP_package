using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
using SIP_package
using Images, ImageView, GR

function wrapper_sampling_parallel(video_path, num_of_iterations, glider_coarse_g_dim)
	# video conversion into BitArray
	bin_vid = whole_video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
	bin_vid = bin_vid[:, :, 1:100]

	# further variables for coarse-graining
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
	cutoff = volume / 2 # sets the cutoff for the majority rule 

	old_vid = bin_vid # stores iteration 0 #THIS WILL BECOME OLD VID and THE OTHER NEW VID
	bin_vid = nothing
	for iter_idx ∈ 1:num_of_iterations
		# coarse-graining of the current iteration
		if iter_idx < num_of_iterations
			old_dim = size(old_vid) # gets the dimensions of the current iteration
			new_dim = get_new_dimensions(old_dim, glider_coarse_g_dim) # computes the dimensions of the next iteration
			# creates a 3D tuple of vectors with the steps the coarse-graining glider will have to do
			steps_coarse_g = compute_steps_glider(glider_coarse_g_dim, old_dim) # precomputes the steps of the coarse-graining glider
			new_vid = BitArray(undef, new_dim) # preallocation of new iteration array
			fill!(new_vid, false)


			new_vid = SIP_package.glider_coarse_g(old_vid, new_vid, steps_coarse_g, glider_coarse_g_dim, cutoff) # computation of new iteration array
			new_vid = Gray.(N0f8.(new_vid))
			if iter_idx == 1
				img_to_show = Array{Gray{N0f8}}(new_vid[:, :, 1])
				imshow(img_to_show)
				sleep(30)
			end
			vec_vid = Vector{Matrix{Gray{N0f8}}}()
			for i in 1:size(new_vid, 3) # makes the video a vector of 2d arrays to save it
				push!(vec_vid, new_vid[:, :, i])
			end # for i in 1:size(vid_BW, 3)
			for i in 1:length(vec_vid) # makes it multiple of two
				frame = vec_vid[i]
				dims = size(frame)
				if dims[1] % 2 != 0 || dims[2] % 2 != 0
					# Crop to even dimensions
					new_dims = (dims[1] - dims[1] % 2, dims[2] - dims[2] % 2)
					vec_vid[i] = frame[1:new_dims[1], 1:new_dims[2]]
				end
			end
			#VideoIO.save("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/presentation/bryce_canyon048_BW_iter_$(iter_idx).mp4", vec_vid)
			old_vid = new_vid
			new_vid = nothing
		end # if 
	end # for
end # EOF
##


video_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_data/presentation/bryce_canyon048_gray.mp4"
num_of_iterations = 5
glider_dim = (3, 3, 3)
wrapper_sampling_parallel(video_path, num_of_iterations, glider_dim)


