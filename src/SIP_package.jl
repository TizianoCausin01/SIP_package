module SIP_package

# =========================
# EXPORTED FUNCTIONS    
# =========================

export split_vid,
	video_conversion,
	get_new_dimensions,
	get_cutoff,
	compute_steps_glider,
	glider_coarse_g,
	glider,
	get_nth_window,
	get_loc_max,
	plot_loc_max

# =========================
# IMPORTED PACKAGES
# =========================

using Images,
	VideoIO,
	FFMPEG,
	Statistics,
	HDF5,
	ImageView,
	GR,
	Plots


# =========================
# PREPROCESSING
# =========================

"""
split_vid
Splits the video in pieces of the specified segment_duration 
and then saves them in the specified output_name
Inputs :
- file_name -> complete path to the file
- output_name -> complete path for the output 
				(must have %03d to save them in progressive order
				starting from 000 like in python)
- segment_duration -> how long should the computed segment be in seconds
						(the last could inevitably be shorter)

breakdown of cmd
cmd =`        # backtick to start the command
ffmpeg        
-i file_name # input
-an           # excludes the audio channel : not needed
-c:v copy     # codec only video, copy directly from the compressed one (without encoding and decoding)
-f segment    # format : segment of video
-segment_time segment_duration # duration of each segment
-reset_timestamps 1 # every segment will have independent timestamps starting from 00:00:00
output_name  
`
"""
function split_vid(file_name, output_name, segment_duration)

	cmd = `
	/opt/homebrew/bin/ffmpeg
	-i $file_name
	-an
	-c:v copy
	-f segment
	-segment_time $segment_duration
	-reset_timestamps 1
	$output_name
`
	run(cmd) # runs the command
end # EOF


"""
video_conversion
reads and converts the video starting from the file name
uses color2BW and get_dimensions as functions
"""
function video_conversion(file_name)
	# loads and opens the video
	# video_load = VideoIO.load(file_name) # to add if you will convert directly the videos from the internet
	reader = VideoIO.openvideo(file_name)
	# stores quantities for preallocation
	frame_1, height, width, frame_num = get_dimensions(reader) # reads the first frame to get the dimensions of the movie and returns what you see in variable assignment
	BW_vid = BitArray(undef, height, width, frame_num) # preallocates a boolean matrix of zeros, s.t. we then substitute ones where gray_frame > gray_median is true 
	fill!(BW_vid, false)
	#BW_vid = BitArray(BW_vid_bool);
	count = 1 # index for later storing frames, starts from one because we already read the first frame
	BW_vid[:, :, count] = color2BW(frame_1) # special treatment for frame_1 because we have already read it

	while !eof(reader) # it loops until the last frame has been read
		count += 1 # updates the count
		frame = VideoIO.read(reader)  # reads the movie
		BW_vid[:, :, count] = color2BW(frame) # assigns the binarized frame to the array
	end # while 
	close(reader) # closes the reader
	# bit_vid = BitArray(BW_vid) # converts the bool vid into a BitArray for optimization
	return BW_vid
end # EOF


"""
get_dimensions
reads the first frame of the frame of the movie and gets the dimensions of the movie
"""
function get_dimensions(reader)
	frame_num = VideoIO.counttotalframes(reader) # total number of frames
	frame_1 = VideoIO.read(reader) # stores the first frame to get the height and width
	height, width = size(frame_1)
	return frame_1, height, width, frame_num
end # EOF


"""
color2BW
converts an RGB array into a BitArray
"""
function color2BW(frame)
	gray_frame = Gray.(frame) # converts the frame from RGB to grayscale
	gray_median = median(gray_frame)
	BW_frame = gray_frame .> gray_median # it is true(=1=white) only where the grayscale value is greater than the median. Then it broadcasts the ones in the correct positions of the array. The zeros are already there.
	return BW_frame
end # EOF

# =========================
# COARSE-GRAINING
# =========================

"""
get_new_dimensions
Derives the new dimensions of the coarse grained video.
Inputs :
- video_dim -> the dimensions of the previous iteration 
- coarse_g_dim -> the dimensions of the coarse graining to be done
Outputs :
- new_dim -> the new dimensions of the coarse grained video
"""
function get_new_dimensions(video_dim, coarse_g_dim)
	new_dim = (                                     # floor s.t it won't overindex
		floor(Int, video_dim[1] / coarse_g_dim[1]),
		floor(Int, video_dim[2] / coarse_g_dim[2]),
		floor(Int, video_dim[3] / coarse_g_dim[3]),
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
function get_cutoff(glider_coarse_g_dim)
	volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
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
function glider_coarse_g(bin_vid, new_vid, tot_steps, glider_coarse_g_dim, cutoff)
	counter_new_mat = [0, 0, 0] # rows, cols, depth initializes a new counter for indexing in the new matrix
	for i_time ∈ tot_steps[3]
		idx_time = i_time:i_time+glider_coarse_g_dim[3]-1 # you have to subtract one, otherwise you will end up getting a bigger glider
		counter_new_mat[3] += 1 # updates the counter accordingly
		counter_new_mat[1] = 0 # sets the counter of the inner loop to zero s.t. it doesn't overindex
		for i_rows ∈ tot_steps[1]
			idx_rows = i_rows:i_rows+glider_coarse_g_dim[1]-1
			counter_new_mat[1] += 1
			counter_new_mat[2] = 0 # sets the counter of the inner loop to zero s.t. it doesn't overindex
			for i_cols ∈ tot_steps[2]
				idx_cols = i_cols:i_cols+glider_coarse_g_dim[2]-1
				counter_new_mat[2] += 1
				white_count = sum(bin_vid[idx_rows, idx_cols, idx_time]) # index in video, gets the current window and immediately sums over it. 
				new_vid[counter_new_mat[1], counter_new_mat[2], counter_new_mat[3]] = majority_rule(white_count, cutoff) # assigns the pixel of the coarse grained video in the correct position
			end # cols
		end # rows
	end # time
	return new_vid
end # EOF


"""
compute_steps_glider
Creates a tuple with the steps the glider will have to do in each dimension. 
Each number in the list is the initial element in the new window. 
It subtracts the glider_dim such that we won't overindex
"""
function compute_steps_glider(glider_dim, video_dim)
	tot_steps = (
		1:glider_dim[1]:video_dim[1]-glider_dim[1],
		1:glider_dim[2]:video_dim[2]-glider_dim[2],
		1:glider_dim[3]:video_dim[3]-glider_dim[3],
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


# =========================
# SAMPLING
# =========================

"""
glider
Creates a glider that slides over the given binarized video 
and counts the configuration occurrences. Step=1
Inputs : 
- bin_vid -> the binarized (BitArray) video
- glider_dim -> a tuple with the three dimensions of the glider

Outputs :
- counts -> it's a dict with BitVector as keys and Int as values. 
			It stores the counts of windows configurations
"""
function glider(bin_vid, glider_dim)
	counts = Dict{BitVector, Int}()
	vid_dim = size(bin_vid)
	for i_time ∈ 1:vid_dim[3]-glider_dim[3] # step of sampling glider = 1
		idx_time = i_time:i_time+glider_dim[3]-1 # you have to subtract one, otherwise you will end up getting a bigger glider
		for i_rows ∈ 1:vid_dim[1]-glider_dim[1]
			idx_rows = i_rows:i_rows+glider_dim[1]-1
			for i_cols ∈ 1:vid_dim[2]-glider_dim[2]
				idx_cols = i_cols:i_cols+glider_dim[2]-1
				window = vec(bin_vid[idx_rows, idx_cols, idx_time]) # index in video, gets the current window and immediately vectorizes it. 
				counts = update_count(counts, window)
			end # cols
		end # rows
	end # time
	return counts
end # EOF


"""
update_count
updates the dictionary of counts such that if the window was already
present, it adds 1 to the value (to count it), otherwise it creates it
and initializes its value with a 1
"""
function update_count(counts_dict, window)
	counts_dict[window] = get!(counts_dict, window, 0) + 1
	return counts_dict
end #EOF


"""
get_nth_window
From Vector{Pair{BitVector, Int}} which is the counts_dict 
after it has been sorted, this function gets the nth top window, 
unflattens it and turns it into gray values to be visualized 
inputs : 
- idx -> the rank of the window, in descending order
- sorted_counts -> the counts_dict after it has been sorted, 
	type: Vector{Pair{BitVector, Int}}
- glider_dim -> the dimensions of the glider, to unflatten the vectorized window
"""
function get_nth_window(idx, sorted_counts, glider_dim)
	window = sorted_counts[idx].first # gets the window from the dict
	r_window = reshape(window, glider_dim) # reshapes it according to the glider dimensions
	gray_window = Gray.(r_window) # turns it into gray to visualize it
	count = sorted_counts[idx].second
	return gray_window, count
end # EOF


# =========================
# COMPUTING LOCAL MAXIMA
# =========================


"""
get_loc_max
Given a dictionary with the corresponding counts of the sampled windows, 
it returns the local max, i.e. those windows that, if you flip one (only one)
pixel (in any of the positions), the probability won't increase.
Details about the algorithm: 
- sorts the dict converting it into sorted_counts::Vector{Pair{BitVector, Int}}
- for each key in sorted_counts
	- flip any element in the key separately
	- see if the frequency increases
	- if so, stop comparing
- add if it didn't stop before

input:
- myDict -> Dict{BitVector, Int}, a dictionary with the frequency of sampled windows
- percentile -> Int, the percentile of top wins to consider in the maximum

output:
- loc_max -> Vector{BitVector} with the local maxima in order of frequency

Dict{BitVector, Int}
"""
function get_loc_max(myDict, percentile)
	loc_max = Vector{BitVector}(undef, 0) # initializes as a vector of BitVectors
	sorted_counts = sort(collect(myDict), by = x -> x[2], rev = true) # sorts the dictionary of counts according to the values and converts it into a Vector{Pair{}}
	top_nth = Int(round(2^length(sorted_counts[1].first) * percentile / 100)) # computes the top nth elements
	for element in Iterators.take(sorted_counts, top_nth) # loops through the top nth-elements
		win = element.first # extracts the key
		max = is_max(myDict, win) # inspects if it's a max
		if ~(max === nothing) # if max exists, updates loc_max
			push!(loc_max, max)
		end # if max exists
	end # for every element
	return loc_max # returns the loc_max
end # EOF

"""
is_max
Flips the target "win" to see if there is one with higher frequency,
if there is it returns nothing, if there isn't we have found a local maximum

Inputs:
- myDict -> the dict with the respective counts 
- win -> the extracted win (typically the current max of myDict)

Output:
- if it's local maximum : win 
- if it's not : nothing
"""
function is_max(myDict, win)
	win_freq = get(myDict, win, -1) # if the key doesn't exit, assign -1
	for position ∈ 1:length(win) # changes one element at the time
		flipped_win = flip_element(win, position) # flips the window element in "position" 
		if get(myDict, flipped_win, 0) > win_freq # new win might have been not present, that's why we use get 
			return nothing # don't include win in local maxima if it breaks the loop (counter<length(win))
		end # if get(myDict, win, 0) > win_freq
	end # for position 
	return win # only if it is a local max
end # EOF


"""
flip_element
Takes a vectorized win of pixels and flips the element 
in the target position by negating it. It doesn't modify the input win.
Used for computing the local maxima of PMFs
Inputs :
- win -> the vectorized window of pixels
- position -> the position of the target pixels

output :
- win -> the modified window
"""
function flip_element(win::BitVector, position::Int)
	flipped_win = copy(win) # creates a copy to not mutate the win
	flipped_win[position] = ~flipped_win[position]  # flips the value by negating it
	return flipped_win
end # EOF


"""
plot_loc_max
Plots local maxima in an array (automatic subplot layout) @gif to visualize better
Inputs :
- loc_max::Array{BitVector} -> array with vectorized patches that ended up being local maxima
- glider_dim::Tuple{Int, Int, Int} -> 3D tuple with the dimensions of the sampled patch
- fps_gif::Int -> the frame rate at which we present the plots

Outputs :
- plot_list::Vector{Plot{GRBackend}} -> returns the plots in case they were useful

subfunctions :
- bitVec2imgs
"""
function plot_loc_max(loc_max::Array{BitVector}, glider_dim::Tuple, fps_gif::Int)
	theme(:default) # settings to default all Plots.jl parameters 
	default(background_color = :lightgray) # gray background otherwise patches are not distinguishable
	array_of_patches = bitVec2imgs(loc_max, glider_dim)
	@gif for t_idx in 1:glider_dim[3] # t_idx is the temporal idx of the patch
		plot_list = [Plots.plot(
			Plots.heatmap(el[:, :, t_idx], color = :grays, axis = false),
		) for el in array_of_patches]  # Enumerate for titles
		Plots.plot(plot_list...)  # ... is splat operator (to unpack the elements of plot_list) 
		# the size of each plot and the layot of the subplots is automatically decided
	end every 1 fps = fps_gif # @gif for
end


"""
bitVec2imgs
translates loc_max into an array of unflattened grayscale patches (of values 0 or 255).
Inputs :
- loc_max::Array{BitVector} -> array with vectorized patches that ended up being local maxima
- glider_dim::Tuple{Int, Int, Int} -> 3D tuple with the dimensions of the sampled patch

Outputs :
- array_of_patches::Vector{Array{ColorTypes.Gray{Bool}, 3}} -> vector of unflattened, grayscaled local maxima

Main function :
- plot_loc_max
"""
function bitVec2imgs(loc_max, glider_dim)
	array_of_patches = Vector{Array{ColorTypes.Gray{Bool}, 3}}(undef, size(loc_max)) # initialization
	counter = 0
	for el in loc_max
		counter += 1 # updates the count
		patch = Gray.(reshape(el, glider_dim)) # unflattens the vectorized patches and turns them into grayscale
		array_of_patches[counter] = patch # stores the new patch
	end # for el in loc_max
	return array_of_patches
end

end # module SIP_package
