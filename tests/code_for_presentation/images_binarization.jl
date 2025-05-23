using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using SIP_package
using Images
using VideoIO
## to binarize a video
path2vid = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/presentation/bryce_canyon048_gray.mp4"
vid_BW = Gray.(N0f8.(whole_video_conversion(path2vid)))
vec_vid = []
for i in 1:size(vid_BW, 3) # makes the video a vector of 2d arrays to save it
	push!(vec_vid, vid_BW[:, :, i])
end # for i in 1:size(vid_BW, 3)
## to save the binarized video
VideoIO.save("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/presentation/bryce_canyon048_BW.mp4", vec_vid)
## to binarize and save an image
path2img = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/presentation/woods_img.jpeg"
img = Gray.(load(path2img))
img_BW = Gray.(SIP_package.color2BW(img))
save("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/presentation/part_img_BW.jpeg", part_img_BW)
## functions for videos reconverted for images
function wrapper_sampling_parallel_2d(img_path, num_of_iterations, glider_coarse_g_dim)
	# video conversion into BitArray
	img = Gray.(load(path2img))
	bin_img = SIP_package.color2BW(img) # converts a target yt video into a binarized one

	bin_img_3d = reshape(bin_img, size(bin_img)..., 1)

	# further variables for coarse-graining
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] #computes the volume of the solid
	cutoff = volume / 2 # sets the cutoff for the majority rule 

	old_vid = bin_img # stores iteration 0 #THIS WILL BECOME OLD VID and THE OTHER NEW VID
	bin_vid = nothing
	arr_imgs = []
	for iter_idx ∈ 1:num_of_iterations
		# coarse-graining of the current iteration
		if iter_idx < num_of_iterations
			old_dim = size(old_vid) # gets the dimensions of the current iteration
			@info "old_dim"
			new_dim = get_new_dimensions_2d(old_dim, glider_coarse_g_dim) # computes the dimensions of the next iteration
			# creates a 3D tuple of vectors with the steps the coarse-graining glider will have to do
			steps_coarse_g = compute_steps_glider_2d(glider_coarse_g_dim, old_dim) # precomputes the steps of the coarse-graining glider
			new_vid = BitArray(undef, new_dim) # preallocation of new iteration array
			fill!(new_vid, false)


			new_vid = glider_coarse_g_2d(old_vid, new_vid, steps_coarse_g, glider_coarse_g_dim, cutoff) # computation of new iteration array
			new_vid = Gray.(N0f8.(new_vid))
			vec_vid = Vector{Matrix{Gray{N0f8}}}()
			for i in 1:size(new_vid, 3) # makes the video a vector of 2d arrays to save it
				push!(vec_vid, new_vid[:, :, i])
			end # for i in 1:size(vid_BW, 3)

			# VideoIO.save("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/presentation/bryce_canyon048_BW_iter_$(iter_idx).mp4", vec_vid)
			old_vid = new_vid
			new_vid = nothing
			push!(arr_imgs, Gray.(old_vid))
		end # if 
	end # for
	return arr_imgs
end # EOF

function get_new_dimensions_2d(video_dim, coarse_g_dim)
	new_dim = (                                     # floor s.t it won't overindex
		floor(Int, video_dim[1] / coarse_g_dim[1]),
		floor(Int, video_dim[2] / coarse_g_dim[2]),
	)
	return new_dim
end # EOF


"""
get_cutoff
Gets the dimensions of the glider for coarse graining
and returns a cutoff value for the decision rule
Inputs : 
- glider_coarse_g_dim -> tuple with the dimensions of the glider for coarse graining 
"""
function get_cutoff_2d(glider_coarse_g_dim)
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] #computes the volume of the solid
	cutoff = volume / 2 # sets the cutoff for the majority rule 
	return cutoff
end # EOF


"""
glider_coarse_g
It's the glider for coarse graining. Loops over all the steps 
and returns a new video which is the old video coarse grained. 
Inputs :
- bin_vid -> the binarized video from the previous iteration
- tot_steps -> a tuple created with get_steps which has 3 
				arrays of numbers, one for each dimension. It 
				indicates the onset of each new step
- glider_coarse_g_dim -> tuple with the dimensions of the coarse graining
- cutoff -> given the dimensions of the glider, the cutoff for the majority rule

Outputs : 
- new_vid -> the new coarse-grained video
"""
function glider_coarse_g_2d(bin_vid, new_vid, tot_steps, glider_coarse_g_dim, cutoff)
	rows_steps, cols_steps = tot_steps
	new_rows, new_cols = [0, 0] # rows, cols, depth initializes a new counter for indexing in the new matrix
	for i_cols ∈ cols_steps
		idx_cols = i_cols:i_cols+glider_coarse_g_dim[2]-1
		new_cols += 1
		new_rows = 0 # sets the counter of the inner loop to zero s.t. it doesn't overindex
		for i_rows ∈ rows_steps
			idx_rows = i_rows:i_rows+glider_coarse_g_dim[1]-1
			new_rows += 1
			white_count = sum(bin_vid[idx_rows, idx_cols]) # index in video, gets the current window and immediately sums over it. 
			new_vid[new_rows, new_cols] = majority_rule(white_count, cutoff) # assigns the pixel of the coarse grained video in the correct position
		end # cols
	end # rows
	return new_vid
end # EOF


"""
compute_steps_glider
Creates a tuple with the steps the glider will have to do in each dimension. 
Each number in the list is the initial element in the new window. 
It subtracts the glider_dim such that we won't overindex
"""
function compute_steps_glider_2d(glider_dim, video_dim)
	tot_steps = (
		1:glider_dim[1]:video_dim[1]-glider_dim[1],
		1:glider_dim[2]:video_dim[2]-glider_dim[2],
	)
	return tot_steps
end # EOF


""" 
majority_rule
receives how many white pixels there are in the window 
and then turns the whole picture into either black or white
according to the majority rule 
Inputs :
- white_count -> count of white pixels in the window
- cutoff -> half of the total pixels in the window taken into account
Outputs :
- pix -> how the pixel in the coarse grained video will look like
"""
function majority_rule(white_count, cutoff)
	if white_count > cutoff
		pix = true
	else
		pix = false
	end # end if
	return pix
end # EOF

##
num_of_iterations = 5
glider_coarse_g_dim = (3, 3)
path2img = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/presentation/woods_img.jpeg"
a = wrapper_sampling_parallel_2d(path2img, num_of_iterations, glider_coarse_g_dim)
##
a[3][:, :]
##
