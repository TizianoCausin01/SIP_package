module SIP_package

# =========================
# EXPORTED FUNCTIONS    
# =========================

export wrapper_sampling,
	split_vid,
	video_conversion,
	whole_video_conversion,
	get_dimensions,
	get_new_dimensions,
	get_cutoff,
	compute_steps_glider,
	glider_coarse_g,
	glider,
	get_nth_window,
	get_loc_max,
	plot_loc_max,
	get_loc_max_ham,
	parallel_get_loc_max_ham,
	counts2prob,
	prob_at_T,
	entropy_T,
	numerical_heat_capacity_T,
	json2dict,
	json2intdict,
	jsd,
	tot_sh_entropy,
	meg_sampling,
	get_top_windows,
	parallel_get_loc_max,
	template_matching,
	vectorize_surrounding_patches,
	load_dict_surroundings,
	prepare_for_ICA,
	get_fps,
	centering_whitening,
	mergers_convergence,
	tm_mergers_convergence,
	merge_vec_dicts,
	jsd_workers,
	jsd_master,
	master_json2intdict,
	workers_json2intdict,
        local_scrambling,
        block_scrambling

# =========================
# IMPORTED PACKAGES
# =========================

using Images,
	VideoIO,
	FFMPEG,
	Statistics,
	JSON,
	LinearAlgebra,
	MPI,
	CodecZlib,
	Dates,
        Random

#include("./SBitSet.jl")


#const B = 1 # number of 64-bits chunks for SBitSet
# =========================
# WRAPPER ALL
# =========================
"""
wrapper_sampling
Wraps up all the functions below. From the splitted video.mp4 it converts it into BitArray, samples it, saves 
the dict of the counts and local maxima and coarse-grains it for the next iteraiton (in this order). 
TODO : include video splitting and final merging of all the dicts
Inputs : 
- video_path::String -> where the initial video.mp4 is stored
- results_path::String -> where the results will be saved
- file_name::String -> the name of the video
- num_of_iterations::Int -> how many times we will sample and coarse-grain the movie 
							(includes the 1st, which is the initially binarized video)
- glider_coarse_g_dim::Tuple{3} -> three dimensional tuple that tells us how the coarse-graining is done
- glider_dim::Tuple{3} -> three dimensional tuple that tells us how the sampling is done
- percentile::Int -> top (most frequent) % of loc_max that will be stored
"""

function wrapper_sampling(video_path::String, results_path::String, file_name::String, num_of_iterations::Int, glider_coarse_g_dim::Tuple{Int, Int, Int}, glider_dim::Tuple{Int, Int, Int}, percentile::Int)
	# video conversion into BitArray
	bin_vid = video_conversion(video_path) # converts a target yt video into a binarized one

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
		@info "$(Dates.format(now(), "HH:MM:SS")) running iteration $iter_idx"
		@time begin
			# samples the current iteration
			counts_list[iter_idx] = glider(coarse_g_iterations[iter_idx], glider_dim) # samples the current iteration
			loc_max_list[iter_idx] = get_loc_max(counts_list[iter_idx], percentile) # computes the local maxima
			open("$(results_path)/counts_$(file_name)_iter$(iter_idx).json", "w") do file
				JSON.print(file, counts_list[iter_idx])
			end # open counts
			open("$(results_path)/loc_max_$(file_name)_iter$(iter_idx).json", "w") do file
				JSON.print(file, loc_max_list[iter_idx])
			end # open loc_max
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


# =========================
# PREPROCESSING
# =========================

"""
split_vid
Splits the video in pieces of the specified segment_duration 
and then saves them in the specified output_name
Inputs :
- path2data::String -> complete path to the folder where all the videos are stored
- file_name::String -> name of the video 				
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
output_name  # (must have %03d to save them in progressive order
				starting from 000 like in python)
`
"""
function split_vid(path2data::String, file_name::String, segment_duration::Int)
	original_data = "$(path2data)/$(file_name).mp4" # path to the original video	
	split_folder = "$(path2data)/$(file_name)_split" # folder where the chunks will go 
	split_files = "$(split_folder)/$(file_name)%03d.mp4" # name of the chunks (see above)
	if !isdir(split_folder) # checks if the directory already exists
		mkpath(split_folder) # if not, it creates the folder where to put the split_files
	end # if !isdir(dir_path)

	cmd = `
		/leonardo/home/userexternal/tcausin0/bin/ffmpeg
		-i $original_data
	-an
	-c:v libx264
		-preset fast
		-flush_packets 1
	-f segment
	-segment_time $segment_duration
	-reset_timestamps 1
	$split_files
`
	run(cmd) # runs the command
end # EOF



"""
whole_video_conversion
Converts the video from RGB to BitArray by thresholding it along its median luminance value.
Converts each frame into grayscale, then computes the median and converts the whole grayscale 
array into a BitArray.
INPUT:
- path2file::String -> the path to the file to convert

OUTPUT:
- array_bits::BitArray{3} -> the binarized video
"""

function whole_video_conversion(path2file::String)::BitArray{3}
	reader = VideoIO.openvideo(path2file)
	frame, height, width, depth = get_dimensions(reader)
	gray_array = Array{Gray{N0f8}}(undef, height, width, depth) # preallocates an array of grayscale values
	array_bits = BitArray(undef, height, width, depth) # preallocates a BitArray
	copyto!(view(gray_array, :, :, 1), frame) # copies the first frame into the first element of the gray_array
	count = 1
	while !eof(reader)
		count += 1
		frame = VideoIO.read(reader)
		gray_array[:, :, count] = Gray.(frame)
	end # end while !eof(reader)
	median_value = median(gray_array)
	@. array_bits = gray_array > median_value # broadcasts the value in the preallocated array
	gray_array = nothing
	#GC.gc()
	return array_bits
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
	frame_num = get_frame_count(reader) # total number of frames
	frame_1 = VideoIO.read(reader) # stores the first frame to get the height and width
	height, width = size(frame_1)
	return frame_1, height, width, frame_num
end # EOF

"""
get_frame_count
To get the total number of frames without reader.counttotalframes, that sometimes doesn't work.
INPUT:
- reader::VideoIO.VideoReader{true, VideoIO.SwsTransform, String} -> the reader of the video obtained with VideoIO.openvideo

OUTPUT:
- frame_count::Int64 -> the number of frames

"""
function get_frame_count(reader)
	path_name = reader.avin.io
	cmd = `ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of csv=p=0 $(path_name)`
	out = String(read(cmd)) # outputs something like 512,\n
	cleaned_out = replace(strip(out), "," => "")  # Remove the trailing comma
	frame_count = parse(Int, cleaned_out) # converts into Int
	return frame_count
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
	rows_steps, cols_steps, time_steps = tot_steps
	new_rows, new_cols, new_time = [0, 0, 0] # rows, cols, depth initializes a new counter for indexing in the new matrix
	for i_time ∈ time_steps
		idx_time = i_time:i_time+glider_coarse_g_dim[3]-1 # you have to subtract one, otherwise you will end up getting a bigger glider
		new_time += 1 # updates the counter accordingly
		new_cols = 0 # sets the counter of the inner loop to zero s.t. it doesn't overindex
		for i_cols ∈ cols_steps
			idx_cols = i_cols:i_cols+glider_coarse_g_dim[2]-1
			new_cols += 1
			new_rows = 0 # sets the counter of the inner loop to zero s.t. it doesn't overindex
			for i_rows ∈ rows_steps
				idx_rows = i_rows:i_rows+glider_coarse_g_dim[1]-1
				new_rows += 1
				white_count = sum(bin_vid[idx_rows, idx_cols, idx_time]) # index in video, gets the current window and immediately sums over it. 
				new_vid[new_rows, new_cols, new_time] = majority_rule(white_count, cutoff) # assigns the pixel of the coarse grained video in the correct position
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
- counts -> it's a dict with the UInt64 corresponding to the bit windows as keys and UInt64 as values. 
			It stores the counts of windows configurations
"""
function glider(bin_vid::BitArray{3}, glider_dim)::Dict{Int64, UInt64}
	counts = Dict{Int64, UInt64}()
	vid_dim = size(bin_vid)
	win_el = glider_dim[1] * glider_dim[2] * glider_dim[3]
	progression = reverse(0:win_el-1)
	pow_of_2 = 2 .^ progression
	for i_time ∈ 1:vid_dim[3]-glider_dim[3] # step of sampling glider = 1
		idx_time = i_time:i_time+glider_dim[3]-1
		for i_cols ∈ 1:vid_dim[2]-glider_dim[2]
			idx_cols = i_cols:i_cols+glider_dim[2]-1
			for i_rows ∈ 1:vid_dim[1]-glider_dim[1]
				idx_rows = i_rows:i_rows+glider_dim[1]-1
				win_slice = bin_vid[idx_rows, idx_cols, idx_time]
				int_win = bin2int(win_slice, pow_of_2)
				counts[int_win] = get!(counts, int_win, 0) + 1 # updates the count
			end # cols
		end # rows
	end # time
	bin_vid = nothing
	#GC.gc()
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
bin2int
Converts BitArray (the window) onto Int64
"""
function bin2int(win::BitArray{3}, pow_of_2)::Int64
	win_vec = vec(win)
	int_repr = Int64(dot(win_vec, pow_of_2))
	return int_repr
end # EOF

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
function get_loc_max(myDict, percentile, length_win)
	loc_max = Vector{Int64}(undef, 0) # initializes as a vector of BitVectors
	sorted_counts = sort(collect(myDict), by = x -> x[2], rev = true) # sorts the dictionary of counts according to the values and converts it into a Vector{Pair{}}
	top_nth = Int(round(2^length(sorted_counts[1].first) * percentile / 100)) # computes the top nth elements
	for element in Iterators.take(sorted_counts, top_nth) # loops through the top nth-elements
		win = element.first # extracts the key
		max = is_max(myDict, win, length_win) # inspects if it's a max
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
function is_max(myDict, win, length_win)
	win_freq = get(myDict, win, -1) # if the key doesn't exit, assign -1
	#@info "win: $win , win freq : $(get(myDict, win, 0)), $(reshape(BitVector(c=='1' for c in bitstring(win)[end-27+1:end]), (3,3,3)))"
	# @info "win: $win , win freq: $win_freq"
	for position ∈ 1:length_win # changes one element at the time
		flipped_win = flip_element(win, position, length_win) # flips the window element in "position"
		#@info "flipped_win: $flipped_win , win freq : $(get(myDict, flipped_win, 0)) $(reshape(BitVector(c=='1' for c in bitstring(flipped_win)[end-27+1:end]), (3,3,3)))"
		if get(myDict, flipped_win, 0) > win_freq # new win might have been not present, that's why we use get 
			#@info "returning nothing"
			return nothing # don't include win in local maxima if it breaks the loop (counter<length(win))

		end # if get(myDict, win, 0) > win_freq
	end # for position
	#@info "returning something"
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
function flip_element(win, position, length_win)
	pow_of_2 = 2^(length_win - position)
	flipped_win = xor(win, pow_of_2)
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
	for t_idx in 1:glider_dim[3] # t_idx is the temporal idx of the patch
		plot_list = [Plots.plot(
			Plots.heatmap(el[:, :, t_idx], color = :grays, axis = false),
		) for el in array_of_patches]  # Enumerate for titles
		Plots.plot(plot_list...)  # ... is splat operator (to unpack the elements of plot_list) 
		# the size of each plot and the layot of the subplots is automatically decided
	end # for
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



# =========================
# LOCAL MAXIMA IN PARALLEL
# =========================

"""
parallel_get_loc_max
Function to run the local maxima of a PD in parallel (i.e. by splitting a sorted array of pairs in many small steps).
We just flip every element in the BitVectorto see if it's a maximum, and if so we store it. The for loop iterates through a portion of the
array, such that every worker will do just a part of the work.

INPUT:
- myDict::Dict{BitVector, Int} -> the dictionary with the counts of a target coarse-graining iteration
- top_nth_sorted_counts::Vector{Pair{BitVector, Int64}} -> the sorted "dictionary" (it's not a dict anymore!) with the top n% most occurring windows
- start::Int -> the last element to skip, it'll start to iterate at start+1, if it surpasses the length of top_nth_sorted_counts it'll just not loop
- iterations::Int -> the number of elements it will iterate through, typically it's the result of a ceiling division length(top_nth_sorted_counts)/nproc , if it surpasses the length of top_nth_sorted_counts it'll just stop looping

OUTPUT:
- loc_max::Vector{BitVector} -> an array with all the local maxima in that portion of myDict
"""
function parallel_get_loc_max(myDict, top_nth_sorted_counts, start, iterations, length_win)
	loc_max = Vector{Int64}(undef, 0) # initializes as a vector of BitVectors
	for element in Iterators.take(Iterators.drop(top_nth_sorted_counts, start), iterations) # loops through top_nth_sorted_counts from start to start + iterations, if the array finishes before, it ends before
		win = element.first # extracts the key
		max = is_max(myDict, win, length_win) # inspects if it's a max
		if ~(max === nothing) # if max exists, updates loc_max
			push!(loc_max, max)
		end # if max exists
	end # for every element
	return loc_max # returns the loc_max
end # EOF

function parallel_get_loc_max_ham(myDict, top_nth_sorted_counts, start, iterations, dist_required, win_dims)
	length_win = prod(win_dims)
	loc_max = Vector{Int64}(undef, 0) # initializes as a vector of BitVectors
	if dist_required == length_win
		@warn "you are just asking for the global maximum"
	elseif dist_required > length_win
		@error "you asked for an hamming distance which is greater than the bitstring itself"
	end
	for element in Iterators.take(Iterators.drop(top_nth_sorted_counts, start), iterations) # loops through the top nth-elements
		win = element.first # extracts the key
		max = is_max_ham_init(myDict, win, dist_required, length_win) # inspects if it's a max
		if ~(max === nothing) # if max exists, updates loc_max
			push!(loc_max, max)
		end # if max exists
	end # for every element
	return loc_max # returns the loc_max
end # EOF



"""
get_top_windows
Sorts myDict and keeps only percentile% of it.

INPUT:
- myDict::Dict{BitVector, Int} -> the dict with the counts
- percentile::Int -> to select the top percentile% of windows (according to the counts)

OUTPUT:
- top_counts::Vector{Pair{BitVector, Int64}} -> the top percentile% counts sorted in decreasing order
"""
function get_top_windows(myDict, percentile)
	sorted_counts = sort(collect(myDict), by = x -> x[2], rev = true) # sorts the dictionary of counts according to the values and converts it into a Vector{Pair{}}
	top_nth = Int(round(length(sorted_counts) * percentile / 100)) # computes the top nth elements
	top_counts = sorted_counts[1:top_nth]
	return top_counts
end


# =========================
# LOCAL MAXIMA HAM > 1
# =========================

function get_loc_max_ham(myDict, percentile, dist_required, win_dims)
	loc_max = Vector{BitVector}(undef, 0) # initializes as a vector of BitVectors
	sorted_counts = sort(collect(myDict), by = x -> x[2], rev = true) # sorts the dictionary of counts according to the values and converts it into a Vector{Pair{}}
	length_win = prod(win_dims)
	if dist_required == length_win
		@warn "you are just asking for the global maximum"
	elseif dist_required > length_win
		@error "you asked for an hamming distance which is greater than the bitstring itself"
	end
	top_nth = Int(round(2^length(sorted_counts[1].first) * percentile / 100)) # computes the top nth elements
	for element in Iterators.take(sorted_counts, top_nth) # loops through the top nth-elements
		win = element.first # extracts the key
		max = is_max_ham_init(myDict, win, dist_required, length_win) # inspects if it's a max
		if ~(max === nothing) # if max exists, updates loc_max
			push!(loc_max, max)
		end # if max exists
	end # for every element
	return loc_max # returns the loc_max
end # EOF
function is_max_ham_recursive(myDict, win_freq, flipped_win1, positions_done, dist_required, length_win)
	all_positions = 1:length(flipped_win1)
	positions_left = setdiff(all_positions, positions_done)
	for position2 in positions_left
		flipped_win2 = flip_element(flipped_win1, position2, length_win) # flips the window element in "position" 
		if get(myDict, flipped_win2, 0) > win_freq
			return false
		end
		if length(positions_done) < dist_required
			state = is_max_ham_recursive(myDict, win_freq, flipped_win2, vcat(positions_done, position2), dist_required, length_win)
			if state == false
				return false
			end
		end # if position_done<dist_required
	end # for position2 in positions_left
	return true
end #EOF

function is_max_ham_init(myDict, win, dist_required, length_win)
	win_freq = get(myDict, win, -1) # if the key doesn't exist, assign -1

	for position ∈ 1:length_win # changes one element at the time
		flipped_win = flip_element(win, position, length_win) # flips the window element in "position" 
		if get(myDict, flipped_win, 0) > win_freq # new win might have been not present, that's why we use get 
			return nothing # don't include win in local maxima if it breaks the loop (counter<length(win))
		end # if get(myDict, win, 0) > win_freq
		state = is_max_ham_recursive(myDict, win_freq, flipped_win, position, dist_required, length_win)
		if state == false
			return nothing
		end # if is_max3(myDict, win_freq, flipped_win, position)==false

	end # for position 
	return win # only if it is a local max
end # EOF

# =========================
# TEMPLATE MATCHING
# =========================

"""
template_matching
Loops through the video and finds the patches that correspond to the local maxima in the dict along with
the surrounding pixels, to find the analogues of Stephens 2013 fig 4 in our experiment.
It skips the patches that are at the borders because not extendible (artifacts deriving from possible paddings are
worse than sampling less patches).
It loops through the video, finds the features that match the loc_max_dict keys, adds the matches and their surroundings 
to a storage (surr_dict[win][1]), while keeping track of how many matches were found (surr_dict[win][2]) for further averaging.
The final step would be the averaging itself (avg_patch = surr_dict[win][1] / surr_dict[win][2]), but we preferred to leave it out 
for possible parallelization (it will require merging the dicts).
INPUT:
- target_vid::BitArray -> the binarized chunk of video
- loc_max_dict::Dict{BitVector, Int} -> the dict with the extracted local maxima
- size_win::Tuple{Integer, Integer, Integer} -> the dimensions of the initial window sampled
- extension_surr::Int -> how many pixels you want as surrounding in each part of the window

OUTPUT:
- surr_dict::Dict{BitVector, Vector{Any}} -> the dict with as keys the local max, as values Vector{Any} [summed_surrounding_pixels, counts_of_occurrences] 
"""

function template_matching(target_vid::BitArray{3}, loc_max_dict, size_win::Tuple{Integer, Integer, Integer}, extension_surr::Int)
	# vars for initializationi
	target_vid = target_vid[:, :, 1:100]
	vid_dim = size(target_vid) # size of the video
	size_surr = size_win .+ extension_surr * 2 # how big are the neighbors of the target win -> obtained adding the extension (*2 because each dimension has 2 sides)
	surr_dict = Dict(k => [zeros(UInt64, prod(size_surr)), 0] for k in keys(loc_max_dict)) # # initializes a dict with the same keys as the loc_max, but as value a Vector{Any} = [summed_surrounding_pixels, count_of_instances]
	win_el = prod(size_win)
	progression = reverse(0:win_el-1)
	pow_of_2 = 2 .^ progression
	for i_time in (1+extension_surr):((vid_dim[3]+1)-size_win[3]-extension_surr) # +/- bc I don't want to idx outside the video. Since each iteration is the onset of the index, we conclude the iterator at size_pic[1] - size_win[1] - extension_surroundings (s.t. the end of the window is within the pic)
		lims_time = get_lims(i_time, size_win[3]) # computes the first and last rows of the current iteration of the glider
		idx_time = lims_time[1]:lims_time[2] # used to idx the rows of the glider
		for i_cols in (1+extension_surr):((vid_dim[2]+1)-size_win[2]-extension_surr) # - 
			lims_cols = get_lims(i_cols, size_win[2]) # computes the first and last cols of the current iteration of the glider
			idx_cols = lims_cols[1]:lims_cols[2] # used to idx the cols of the glider
			for i_rows in (1+extension_surr):((vid_dim[1]+1)-size_win[1]-extension_surr) # +/- bc I don't want to idx outside the video. Since each iteration is the onset of the index, we conclude the iterator at size_pic[1] - size_win[1] - extension_surroundings (s.t. the end of the window is within the pic)
				lims_rows = get_lims(i_rows, size_win[1]) # computes the first and last rows of the current iteration of the glider
				idx_rows = lims_rows[1]:lims_rows[2] # used to idx the rows of the glider
				current_win = target_vid[idx_rows, idx_cols, idx_time] # index in the array
				current_win_int = bin2int(current_win, pow_of_2)
				if haskey(surr_dict, current_win_int)
					lims_time_surr = (lims_time[1] - extension_surr, lims_time[2] + extension_surr) # appends the extensions over the limits to get a larger window
					lims_rows_surr = (lims_rows[1] - extension_surr, lims_rows[2] + extension_surr)
					lims_cols_surr = (lims_cols[1] - extension_surr, lims_cols[2] + extension_surr)
					current_surr = vec(target_vid[lims_rows_surr[1]:lims_rows_surr[2], lims_cols_surr[1]:lims_cols_surr[2], lims_time_surr[1]:lims_time_surr[2]])
					surr_dict[current_win_int][1] += UInt64.(current_surr)
					surr_dict[current_win_int][2] += 1
				end # if current_win==target_win
			end # for i_cols
		end # for i_rows
	end # for i_time
	# avg_patch = tot_surr / tot_matches
	return surr_dict
end # EOF

"""
get_lims
Finds the limits of a certain glider. Used in template_matching.
INPUT:
- i::Int -> the current iterator at some dimension
- size_glider::Int -> the size of the glider at some dimension

OUTPUT
- lims::Tuple{Int, 2} -> the beginning and the end of a certain glider dimension
"""

function get_lims(i, size_glider)
	lims = (i, i + (size_glider - 1)) # the -1 because otherwise you'd get one element more (e.g. if size_glider=3 , 1:4 -> 4 elements)
	return lims
end



"""
vectorize_surrounding_patches
Vectorizes surrounding patches in the dict of surroundings such that they will be easily readable once stored as .json .
INPUT:
- dict_surroundings::Dict{BitVector, Tuple{Array{Integer,3}, Integer}}() -> the dict with the surrounding patches as a 3D array

OUTPUT:
- dict_surr_vec::Dict{BitVector, Tuple{Vector{Integer}, Integer}} -> the dict with the surrounding patches as a vector
"""

function vectorize_surrounding_patches(dict_surroundings)::Dict{BitVector, Tuple{Vector{Integer}, Integer}}
	dict_surr_vec = Dict{BitVector, Tuple{Vector{Integer}, Integer}}()
	for key in keys(dict_surroundings)
		curr_vec = vec(dict_surroundings[key][1])
		dict_surr_vec[key] = (curr_vec, dict_surroundings[key][2])
	end
	return dict_surr_vec
end #EOF

"""
parse_bitvector
Function to parse the BitVector keys in the dict storing the surroundings.
INPUT:
- key::String -> the string that serves as key in the surroundings Dict after it has been saved as JSON

OUTPUT:
- BitVector(bool_values)::BitVector -> the original key 
"""
function parse_bitvector(key::String)::BitVector
	# Extract numbers from the string representation of the BitVector
	bool_values = [c == '1' for c in filter(x -> x in "01", key)] # filter extracts only the 0s and 1s, then creates a Vector{Bool} by comparing them to "1". If "1" == "1" it returns Bool(1) otherwise =="0" it returns Bool{0}
	return BitVector(bool_values)
end
##
"""
load_dict_surroudings
Function to load the dict of surroundings as it was stored.
First it loads it, then it loops through it, parses the keys and stores the values correctly, and also reshapes the vectorized array
with the extended window.
INPUT:
- path2dict::String -> the path to the surroundings Dict
- surr_dims::Tuple{3} -> a tuple with the dimensions of the extended patch

OUTPUT:
- dict_surr::Dict{BitVector, Tuple{Array{UInt64, 3}, Int64}} -> returns the original dictionary
"""


function load_dict_surroundings(path2dict::String, surr_dims::Tuple{Integer, Integer, Integer})
	str_dict = JSON.parsefile(path2dict)
	# loops through the key=>value pairs, parses the keys, assigns the values to the tuples
	dict_surr = Dict(parse_bitvector(k) => (UInt.(reshape(v[1], surr_dims)), v[2]) for (k, v) in str_dict)
	return dict_surr
end #EOF


function load_intdict_surroundings(path2dict::String, surr_dims::Tuple{Integer, Integer, Integer})
	str_dict = JSON.parsefile(path2dict)
	# loops through the key=>value pairs, parses the keys, assigns the values to the tuples
	dict_surr = Dict(parse(Int, k) => (UInt.(reshape(v[1], surr_dims)), v[2]) for (k, v) in str_dict)
	return dict_surr
end #EOF
# =========================
# SCRAMBLING 
# =========================


function local_scrambling(vid, range_scr, stride_glider)
    vid_loc_scr = copy(vid)
    num_steps = fld(size(vid)[3], stride_glider)
	global counter = 0  
	for i in 1:num_steps - cld(range_scr , stride_glider)
		curr_start = stride_glider * counter + 1
		curr_perm = (curr_start - 1) .+ randperm(range_scr)
		vid_loc_scr[:, :, curr_start:curr_start+range_scr-1] = vid_loc_scr[:, :, curr_perm]
		global counter += 1
	end # for i in 1:num_steps
	return vid_loc_scr
end #EOF


function block_scrambling(vid, scale_block)
    vid_block_scr = copy(vid)
    num_blocks = fld(size(vid)[3], scale_block)
	scrambled_indices = randperm(num_blocks) 
	global new_vid = BitArray{3}(undef,size(vid,1), size(vid,2), 0)
	for i in scrambled_indices
		start_idx = (i - 1) * scale_block + 1
        end_idx = i * scale_block
		curr_block = vid_block_scr[:,:,start_idx:end_idx]
		global new_vid = cat(new_vid, curr_block, dims=3)
	end # for i in 1:num_steps
	return new_vid
end # EOF


# =========================
# PHYSICAL QUANTITIES    
# =========================
"""
counts2prob
Converts the counts_dict into a probability dict, by normalizing the counts of the patches.
Input:
- counts_dict::Dict{BitVector, Int} -> Dictionary with the counts of the windows as values
- approx::Int -> number of digits after the comma in the prob_dict

Output:
- prob_dict::Dict{BitVector, Float32} -> Dictionary with the probabilities of the windows as values
"""
function counts2prob(counts_dict, approx::Int)
	vals_counts_dict = values(counts_dict) # extracts the values of the counts_dict
	keys_counts_dict = keys(counts_dict)
        tot_counts = sum(vals_counts_dict) # derives the normalizing factor
	vals_prob_dict = round.(vals_counts_dict ./ tot_counts, digits = approx) # derives the values of the new dict 
	prob_dict = Dict(zip(keys_counts_dict, vals_prob_dict)) # creates a new dict with probabilities as values
	return prob_dict
end # EOF


"""
prob_at_T
Creates a dictionary with new probabilities for a configuration vec{σ} at temperature T (control parameter).
P_T(vec{σ}) =[1/Z(T)]*[P(vec{σ})]^(1/T) 
Input:
- prob_dict::Dict{BitVector, Float32} -> the dictionary with normalized counts as values
- T::Int -> temperature
- approx::Int -> how much we want to approximate when counting the new probabilities

Output:
- new_prob_dict_T::Dict{BitVector, Float32} -> the new dictionary with P_T as values
"""
function prob_at_T(prob_dict, T, approx_P::Int, approx_check::Int)::Dict{BitVector, Float64}
	probs_T = (values(prob_dict)) .^ (1 / T) # P_T(vec{σ}) =[1/Z(T)]*[P(vec{σ})]^(1/T) here I am computing the second part of this equation
	Z = sum(probs_T) # calculates the partition function -> Z(T) = Σ_{vec{σ}}{[P(vec{σ})]^(1/T)}
	new_probs = round.(probs_T ./ Z, digits = approx_P) # derives the values of the new dict at T 
	new_prob_dict_T = Dict(zip(keys(prob_dict), new_probs)) # creates a new dict with probabilities as values
	if !isapprox(sum(values(new_prob_dict_T)), 1, atol = 10.0^(-approx_check)) # just checking that probabilities sum up to one
		throw(DomainError("the sum of probs is different from 1 at T = $(T) -> sum: $(sum(values(new_prob_dict_T)))"))
	end
	return new_prob_dict_T
end

"""
entropy_T
Computes the physical entropy of the system at temperature T. S(T) = - Σ_{P_T(vec{σ})} {P_T(vec{σ}*ln(P_T(vec{σ}))).
Input:
- prob_dict_T::Dict{BitVector, Float32} -> the dictionary with probabilities at temperature T (see above)

Output:
- S_T::Float32 -> the entropy at temperature T. S(T) = - Σ_{P_T(vec{σ})} {P_T(vec{σ}*ln(P_T(vec{σ})))}
"""
function entropy_T(prob_dict_T)::Float64
	log_p = log.(values(prob_dict_T))
	nan_mask = isinf.(log_p) # checks where ln(p(σ)) = -inf because p(σ) = 0
	log_p[nan_mask] .= 0 # substitues -inf with 0s, because lim_{p->0} of p*log(p) = 0
	entropy = -dot(values(prob_dict_T), log_p) # S(T) = - Σ_{P_T(vec{σ})} {P_T(vec{σ}*ln(P_T(vec{σ}))) hence we compute the dot product between vectors
	return entropy
end

"""
numerical_heat_capacity_T
Computes numerically the heat capacity [C(T) = T*(∂H(T)/∂T)] . The partial derivative is computed using the different quotient [H(T+ϵ) - H(T)]/ϵ .
INPUT:
- prob_dict::Dict{BitVector, Float32} -> the dictionary with probabilities at T=1 , so NOT yet modified.
- T -> The temperature at which you want to calculate the derivative
- approx::Int -> sig figs, how much we want to approximate when counting the new probabilities (when we create the new dictionaries)
- ϵ -> the increment when calculating the numerical derivative [H(T+ϵ) - H(T)]/ϵ . The smaller it is the more precise we are, but it MUST be paired with
a proper approx of the probability dicts, otherwise we'll see no change
"""

function numerical_heat_capacity_T(prob_dict, prob_dict_T, T, approx_P::Int, approx_check, eps)
	prob_dict_Teps = prob_at_T(prob_dict, T + eps, approx_P, approx_check)
	h_T = entropy_T(prob_dict_T)
	h_Teps = entropy_T(prob_dict_Teps)
	heat_capacity = T * (((h_Teps) - h_T) ./ eps)
	return h_T, heat_capacity
end



"""
json2dict
Loads and converts the saved dictionary from .json format.

INPUT:
- path2dict::String -> the path to the dictionary.json

OUTPUT:
- bitvector_dict::Dict{BitVector, Int} -> the dictionary in the original format
"""

function json2dict(path2dict::String)
	str_dict = JSON.parsefile(path2dict) # downloads the dict, JSON turned the dict into a Dict{String, Any} where the strings are like: "Bool[1, 0, 1, 1, 0, 1, 1, 0]"
	bitvector_dict = Dict{BitVector, Int}() # preallocates
	for (key, value) in str_dict
		# Check if the key matches the "Bool[...]" pattern
		if occursin(r"^Bool\[[01, ]+\]$", key)  # Validate the format
			# Extract the bit sequence inside the square brackets
			bit_string = replace(key, r"Bool\[" => "", r"\]" => "")  # Remove "Bool[" and "]"
			bits = parse.(Int, split(bit_string, ", "))  # Split and parse into integers
			bitvector_dict[BitVector(bits)] = value # allocates the value related to the key in the Dict{BitVector, Int}
		else
			println("Skipping invalid key: $key")  # Log invalid keys
		end
	end
	return bitvector_dict
end

"""
json2intdict
Loads and converts the saved dictionary from .json format.

INPUT:
- path2dict::String -> the path to the dictionary.json

OUTPUT:
- int_dict::Dict{Int64, UInt64} -> the dictionary in the original format
"""
function json2intdict(path2dict::String)::Dict{Int64, UInt64}
	str_dict = JSON.parsefile(path2dict)  # Parses into Dict{String, Any}
	int_dict = Dict{Int64, UInt64}()      # Preallocate target dict
	for (key, value) in str_dict
		try
			int_key = parse(Int64, key)
			int_value = UInt64(value)
			int_dict[int_key] = int_value
		catch e
			println("Skipping entry ($key => $value): ", e)
		end
	end
	return int_dict
end

"""
int2win 
Converts an int key into the respective win
"""

function int2win(key, win_dims)
	str_key = bitstring(key)
	tot_bits = prod(win_dims)
	str_key = str_key[end-tot_bits+1:end]
	bit_vec_key = BitVector(c == '1' for c in str_key)
	win = reshape(bit_vec_key, win_dims)
	return win
end # EOF


# =========================
# JSD computation and Shannon's entropy
# =========================

"""
avg_PD
Creates the average probability distribution between two dicts for computing JSD.
Sums the distributions and then divides by 2.
INPUT:
- dict1, dict2 ::Dict{BitVector, Int} -> the two dicts representing the probability distributions

OUTPUT:
- avg_dict::Dict{BitVector, Int} -> the average probability distribution
"""
function avg_PD(dict1, dict2)
	avg_dict = mergewith((a, b) -> (a + b) / 2.0, dict1, dict2)
	return avg_dict
end

"""
sing_kld
Computes KLD for a sing val of x from the probability distributions P(x) and Q(x).
INPUT:
- p, q::Float -> values of probability distribution for a certain configuration x

OUTPUT:
- 0 or p * (log2(p / q)) -> from the formula of the KLD
"""
function sing_kld(p, q)
	if p == 0
		return 0 # by convention p*log2(p) = 0 in the lim
	else
		return p * (log2(p / q))
	end # p == 0
end # EOF


"""
jsd
Computes the Jensen-Shannon divergence, defined as jsd(P||Q) = [KLD(P||M)+KLD(Q||M)]/2 . Where M(x):=[P(x)+Q(x)]/2 
It is a way to symmetrize the KLD. 
INPUT:
- dict1, dict2 ::Dict{BitVector, Int} -> the two dicts representing the probability distributions
- ϵ::Float -> small constant to add to the configurations with probability=0 to avoid getting Inf or NaN.
It's a conditional argument, to be specified like this: jsd(dict1, dict2; ϵ = 1e-12) 

OUTPUT:
- jsd::Float64 -> the result of the above operation
"""

function jsd(dict1, dict2; eps = 1e-10)
	jsd = 0
	avg_dict = avg_PD(dict1, dict2)
	for key in keys(avg_dict)
		val1 = get(dict1, key, 0)
		val2 = get(dict2, key, 0)
		avg_val = max(avg_dict[key], eps) # max ensures that we don't get avg_val = 0 thus causing NaN
		jsd += 1 / 2 * (sing_kld(val1, avg_val) + sing_kld(val2, avg_val))
	end # key in keys(avg_PD)
	return jsd
end # EOF



"""
tot_sh_entropy
Computes the Shannon's entropy of a probability distribution.
INPUT:
- dict_prob::Dict{BitVector, Integer} -> the dict of counts converted to probability

OUTPUT:
- tot_sh_entropy::AbstractFloat -> the total Shannon's entropy of the probability distribution
"""

function tot_sh_entropy(dict_prob)::Float32
	sh_entropy = 0
	for k in keys(dict_prob)
		sh_entropy -= sing_sh_entropy(dict_prob[k])
	end # for k in keys(my_dict_prob)
	return sh_entropy
end # EOF


"""
sing_sh_entropy
Computes the Shannon's entropy of a single bin of the histogram. Useful to go through the iterations.
INPUT:
- p::AbstractFloat -> the probability of a patch of pixels

OUTPUT:
- p*log2(p)::AbstractFloat -> to compute the entropy in the sum, or 0 -> if p==0 , by convention, because x goes to 0 quicker than log2(0) to -infinity
"""

function sing_sh_entropy(p::AbstractFloat)::AbstractFloat
	if p == 0
		return 0
	else
		return p * log2(p) # the minus is added later
	end # if p == 0
end # EOF


# =========================
# MEG COARSE-GRAINING AND SAMPLING
# =========================


"""
meg_sampling
It loops through the target binarized 1D time-series and samples it in windows of size glider_dim. It does so
at various iterations of coarse graining.
INPUT:
- meg_signal::BitVector -> the binarized meg signal from a target electrodes
- num_of_iterations::Int -> how many coarse-graining iterations we will do
- glider_coarse_g_dim::Int -> how big will be the window of coarse-graining at each iteration
- glider_dim::Int -> length of the window that we are sampling

OUTPUT:
- counts_list::Vector{Dict{BitVector, Int}} -> ordered vector of dicts each having as keys the windows and 
as values the counts of those windows
"""


function meg_sampling(bin_signal::BitVector, num_of_iterations::Int, glider_coarse_g_dim::Int, glider_dim::Int)::Vector{Dict{BitVector, Int}}
	# sampling and computation of local maxima  
	# preallocation of dictionaries
	counts_list = Vector{Dict{BitVector, Int}}(undef, num_of_iterations) # list of count_dicts of every iteration
	coarse_g_iterations = Vector{BitArray}(undef, num_of_iterations) # list of all the videos at different levels of coarse graining
	# further variables for coarse-graining
	cutoff = glider_coarse_g_dim / 2 # sets the cutoff for the majority rule 
	coarse_g_iterations[1] = bin_signal # stores iteration 0
	for iter_idx ∈ 1:num_of_iterations
		@info "$(Dates.format(now(), "HH:MM:SS")) running iteration $iter_idx"
		# samples the current iteration
		counts_list[iter_idx] = meg_glider(coarse_g_iterations[iter_idx], glider_dim) # samples the current iteration
		if iter_idx < num_of_iterations
			old_dim = length(coarse_g_iterations[iter_idx]) # gets the dimensions of the current iteration
			new_dim = meg_get_new_dimensions(old_dim, glider_coarse_g_dim) # computes the dimensions of the next iteration
			# creates a 3D tuple of vectors with the steps the coarse-graining glider will have to do
			steps_coarse_g = meg_compute_steps_glider(glider_coarse_g_dim, old_dim) # precomputes the steps of the coarse-graining glider
			coarse_g_iterations[iter_idx+1] = BitArray(undef, new_dim) # preallocation of new iteration array
			fill!(coarse_g_iterations[iter_idx+1], false)
			coarse_g_iterations[iter_idx+1] = meg_glider_coarse_g(
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


"""
meg_get_new_dimensions
Derives the new dimensions of the coarse grained video.
INPUT:
- signal_dim::Int -> the length of the MEG signal
- coarse_g_dim:Int -> the dimensions of the coarse graining to be done
OUTPUT:
- new_dim::Int -> the length of the new coarse-grained signal
"""
function meg_get_new_dimensions(signal_dim::Int, coarse_g_dim::Int)::Int
	new_dim = fld(signal_dim, coarse_g_dim) # floor division s.t it won't overindex
	return new_dim
end # EOF

"""
meg_glider_coarse_g
It's the glider for coarse graining. Loops over all the steps 
and returns a new video which is the old video coarse grained. 
Inputs :
- meg_signal::BitVector -> the binarized meg signal from the previous iteration
- new_signal::BitVector -> a preallocated vector for the newly coarse-grained signal
- tot_steps::Vector{Int} -> a vector indicating the onset of each new step
- glider_coarse_g_dim::Int -> dimension of the coarse graining glider
- cutoff -> given the dimensions of the glider, the cutoff for the majority rule

Outputs : 
- new_signal::BitVector -> the new coarse-grained video
"""
function meg_glider_coarse_g(meg_signal::BitVector, new_signal::BitVector, tot_steps::Vector{Int}, glider_coarse_g_dim::Int, cutoff)::BitVector
	new_time = 0 # rows, cols, depth initializes a new counter for indexing in the new matrix
	for i_time ∈ tot_steps
		idx_time = i_time:i_time+glider_coarse_g_dim-1 # you have to subtract one, otherwise you will end up getting a bigger glider
		white_count = sum(meg_signal[idx_time]) # index in video, gets the current window and immediately sums over it. 
		new_time += 1
		new_signal[new_time] = majority_rule(white_count, cutoff) # assigns the pixel of the coarse grained video in the correct position
	end # for i_time ∈ time_steps
	return new_signal
end # EOF


"""
meg_compute_steps_glider
Creates a tuple with the steps the glider will have to do in each dimension. 
Each number in the list is the initial element in the new window. 
It subtracts the glider_dim such that we won't overindex.
INPUT:
- glider_dim::Int -> dimension of the coarse graining 
- signal_dim::Int -> length of the meg signal

OUTPUT:
- tot_steps::Vector{Int} -> all the steps of the coarse graining glider
"""
function meg_compute_steps_glider(glider_dim::Int, signal_dim::Int)::Vector{Int}
	tot_steps = (1:glider_dim:signal_dim-glider_dim)
	return tot_steps
end # EOF


"""
glider
Creates a glider that slides over the given binarized video 
and counts the configuration occurrences. Step=1
Inputs : 
- bin_signal::BitVector -> the binarized (BitArray) MEG signal
- glider_dim::Int -> the length of the window that we are sampling 

Outputs :
- counts -> it's a dict with BitVector as keys and Int as values. 
			It stores the counts of windows configurations
"""

function meg_glider(bin_signal::BitVector, glider_dim::Int)::Dict{BitVector, Int}
	counts = Dict{BitVector, Int}()
	signal_dim = length(bin_signal)
	for i_time ∈ 1:signal_dim-glider_dim # step of sampling glider = 1 
		idx_time = i_time:i_time+glider_dim-1 # you have to subtract one, otherwise you will end up getting a bigger glider
		window = view(bin_signal, idx_time) # index in video, gets the current window and immediately vectorizes it. 
		counts = update_count(counts, vec(window))
	end # time
	return counts
end # EOF


# =========================
# MEG COARSE-GRAINING AND SAMPLING
# =========================


"""
prepare_for_ICA
Loads the video and prepares it to be the input to ICA. It reads the video and then loops over its frames. 
It concatenates them and then vectorizes them altogether. Between one batch of frames and the other, it skips
some frames to avoid the datapoints to be directly one after the other. 
INPUT:
- path2file::String -> the path to the file
- n_vids::Int -> number of datapoints for ICA
- ratio_denom::Int -> denominator of how much we are gonna resize the video
- frame_seq::Int -> how many frames we are gonna concatenate for each datapoints

OUTPUT:
- vid_array::Array{Float32} -> the datamatrix that'll serve as input for ICA. It's datapts x feats (i.e. vectorized videos x number of pixels)
"""
function prepare_for_ICA(path2file::String, n_vids::Int, ratio_denom::Int, frame_seq::Int, tol = 1e-5)::Array{Float64}
	reader = VideoIO.openvideo(path2file)
	frame, height, width, depth = get_dimensions(reader)
	frame_sm = imresize(frame, ratio = 1 / ratio_denom)
	height_sm, width_sm = size(frame_sm)
	vid_array = Array{Float64}(undef, height_sm * width_sm * frame_seq, n_vids) # preallocates an array of grayscale values
	vid_temp = Array{Float64}(undef, height_sm, width_sm, frame_seq) # stores temporarily the frame sequence before vectorizing it
	fps = get_fps(path2file)
	for i_vid in 1:n_vids
		frame2go = rand(1:depth-(frame_seq+2)) # draws the initial frame from a uniform distribution of all frames
		seek(reader, frame2go / fps) # goes at frame n (but since seek accepts secs we are normalizing by the fps)
		for i_frame in 1:frame_seq
			frame = VideoIO.read(reader)
			frame_sm = imresize(frame, ratio = 1 / ratio_denom)
			vid_temp[:, :, i_frame] = Gray.(frame_sm)
		end
		frame_vec = vec(vid_temp)
		vid_array[:, i_vid] = frame_vec
	end # end while !eof(reader)
	return vid_array
end # EOF


"""
get_fps
Function to get_the frame rate of a video in julia. It uses ffmpeg function and converts the output into a Float.

INPUT:
- video_path::String -> path to the video to analyze

OUTPUT:
- fps::Float64 -> frame rate of the video
"""
function get_fps(video_path::String)::Float32
	cmd1 = `ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 $video_path` # getting the fps as a fraction e.g. 30/1
	cmd2 = `bc -l` # converting fraction into float
	seq = pipeline(cmd1, cmd2) # combining the commands with a pipe |
	out = readchomp(seq) # executes commands and returns the output as a str, then removes \n
	fps = parse(Float32, out) # converts out from str to Float
	return fps
end

"""
centering_whitening
"""
function centering_whitening(X, tol)
	# Center the data (mean subtraction)
	X_centered = X .- mean(X, dims = 1)

	# Compute the covariance matrix
	C = cov(X_centered)
	@info "$(Dates.format(now(), "HH:MM:SS")) $(size(C))"

	# Eigen-decomposition of the covariance matrix
	F = eigen(C)
	evals = F.values
	neg_idx = evals .< tol
	@info "$(Dates.format(now(), "HH:MM:SS")) $neg_idx"
	evals[neg_idx] .= tol

	# Only retain positive eigenvalues (to avoid numerical issues with small negative eigenvalues)
	evals = abs.(F.values)
	whitening_matrix = F.vectors * Diagonal(1.0 ./ sqrt.(evals)) * F.vectors'
	X_whitened = X_centered * whitening_matrix

	return X_whitened
end


# =========================
# PARALLEL SCRIPTS FUNCTIONS
# =========================


"""
mergers_convergence
To converge the dicts onto one process at the end of sampling.
It does so hierarchically, each oddly-indexed process in the target level receives the dict from the evenly-indexed
process above and merges it with its dict. Its all based on blocking operations because we need that everybody to move
with the same rhythm. 
INPUT:
- rank::Int -> the rank of the process
- mergers_arr::Vector{Int} or UnitRange{Int} -> the array with the rank of all the mergers
- my_dict:: Vector{Dict{BitVector, Int}} -> the array of dicts merged up to now
- comm -> the comm from MPI

OUTPUT:
none


"""
function mergers_convergence(rank, mergers_arr, my_dict, num_of_iterations, results_folder, name_vid, comm)
	@info "not using the length"
	levels = get_steps_convergence(mergers_arr)
	@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank) before converging: free memory $(Sys.free_memory()/1024^3)"
	if rank == mergers_arr[1]
		@info "$(Dates.format(now(), "HH:MM:SS")) levels: $(levels)"
	end # if rank==0
	#new_dict_buffer = Vector{UInt32}(undef, 1)
	for lev in 1:(length(levels)-1) # stops before the last el in levels
		if in(rank, levels[lev]) # if the process is within the current levels iteration (otherwise it has already sent its dict)
			if in(rank, levels[lev+1]) # in case it is a receiver (odd-indexed, it will be present also in the nxt step)
				if rank + 1 <= levels[lev][end] # for the margins, it lets pass only the processes that have someone above, otherwise there is no merging at that step for the margin
					idx_src = findfirst(rank .== levels[lev]) + 1 # computes the index of the source process (one idx up the idx of the process)
					# new_dict, status = MPI.recv(levels[lev][idx_src], lev, comm) # receives the new dict
					new_dict = rec_large_data(levels[lev][idx_src], lev, comm)
					#new_dict_length = MPI.Recv(UInt32, comm; source = levels[lev][idx_src], tag = lev)
					# we recycle the memory allotted to dict_buffer from one iteration to the next
					#resize!(new_dict_buffer, new_dict_length)
					#MPI.Recv!(new_dict_buffer, comm; source = levels[lev][idx_src], tag = lev)	
					#new_dict_ser = MPI.Recv(UInt32, comm; source = levels[lev][idx_src], tag = lev)
					#new_dict = transcode(ZlibDecompressor, new_dict_buffer)
					#new_dict = MPI.deserialize(new_dict_buffer)					
					#rec_large_data(levels[lev][idx_src],lev , comm)
					new_dict = MPI.deserialize(new_dict)
					merge_vec_dicts(my_dict, new_dict, num_of_iterations)
					new_dict = nothing
					#GC.gc()
					@info "$(Dates.format(now(), "HH:MM:SS")) rank $(rank): merged with dict from rank $(levels[lev][idx_src])"
				end # if proc + 1 <= length(mergers) 
			else
				idx_dst = findfirst(rank .== levels[lev]) - 1 # finds the idx of the receiver (one idx below its)
				my_dict = MPI.serialize(my_dict)
				#my_dict = transcode(ZlibCompressor, my_dict)
				# MPI.send(my_dict, levels[lev][idx_dst], lev, comm) # sends its dict
				#send_large_data(my_dict, levels[lev][idx_dst], lev, comm)
				#MPI.Send(UInt32(length(my_dict)), comm; dest = levels[lev][idx_dst], tag = lev)
				#MPI.Send(my_dict, comm; dest = levels[lev][idx_dst], tag = lev)
				send_large_data(my_dict, levels[lev][idx_dst], lev, comm)
				my_dict = nothing
				#GC.gc()
				@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank) after converging: free memory $(Sys.free_memory()/1024^3)"
			end # if in(rank, lev)
		end # if in(rank, levels[lev])
	end # for lev in levels
	if rank == levels[end][1] # if it's the last process on top of the hierarchy, saves the dict
		for iter_idx in 1:num_of_iterations
			open("$(results_folder)/counts_$(name_vid)_iter$(iter_idx).json", "w") do file # the folder has to be already present 
				JSON.print(file, my_dict[iter_idx])
			end # open counts
		end # for iter_idx in 1:num_of_iterations
	end # if rank == levels[end][1]
end # EOF

function tm_mergers_convergence(rank, mergers_arr, my_dict, num_of_iterations, results_folder, name_vid, extension_surr, comm)
	@info "not using the length"
	levels = get_steps_convergence(mergers_arr)
	@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank) before converging: free memory $(Sys.free_memory()/1024^3)"
	if rank == mergers_arr[1]
		@info "$(Dates.format(now(), "HH:MM:SS")) levels: $(levels)"
	end # if rank==0
	#new_dict_buffer = Vector{UInt32}(undef, 1)
	for lev in 1:(length(levels)-1) # stops before the last el in levels
		if in(rank, levels[lev]) # if the process is within the current levels iteration (otherwise it has already sent its dict)
			if in(rank, levels[lev+1]) # in case it is a receiver (odd-indexed, it will be present also in the nxt step)
				if rank + 1 <= levels[lev][end] # for the margins, it lets pass only the processes that have someone above, otherwise there is no merging at that step for the margin
					idx_src = findfirst(rank .== levels[lev]) + 1 # computes the index of the source process (one idx up the idx of the process)
					# new_dict, status = MPI.recv(levels[lev][idx_src], lev, comm) # receives the new dict
					new_dict = rec_large_data(levels[lev][idx_src], lev, comm)
					#new_dict_length = MPI.Recv(UInt32, comm; source = levels[lev][idx_src], tag = lev)
					# we recycle the memory allotted to dict_buffer from one iteration to the next
					#resize!(new_dict_buffer, new_dict_length)
					#MPI.Recv!(new_dict_buffer, comm; source = levels[lev][idx_src], tag = lev)	
					#new_dict_ser = MPI.Recv(UInt32, comm; source = levels[lev][idx_src], tag = lev)
					#new_dict = transcode(ZlibDecompressor, new_dict_buffer)
					#new_dict = MPI.deserialize(new_dict_buffer)					
					#rec_large_data(levels[lev][idx_src],lev , comm)
					new_dict = MPI.deserialize(new_dict)
					merge_vec_dicts(my_dict, new_dict, num_of_iterations)
					new_dict = nothing
					#GC.gc()
					@info "$(Dates.format(now(), "HH:MM:SS")) rank $(rank): merged with dict from rank $(levels[lev][idx_src])"
				end # if proc + 1 <= length(mergers) 
			else
				idx_dst = findfirst(rank .== levels[lev]) - 1 # finds the idx of the receiver (one idx below its)
				my_dict = MPI.serialize(my_dict)
				send_large_data(my_dict, levels[lev][idx_dst], lev, comm)
				my_dict = nothing
				#GC.gc()
				@info "$(Dates.format(now(), "HH:MM:SS")) proc $(rank) after converging: free memory $(Sys.free_memory()/1024^3)"
			end # if in(rank, lev)
		end # if in(rank, levels[lev])
	end # for lev in levels
	tm_folder = "$(results_folder)/template_matching_$(name_vid)"
	if !isdir(tm_folder) # checks if the directory already exists
		mkpath(tm_folder) # if not, it creates the folder where to put the split_files
	end # if !isdir(dir_path)
	if rank == levels[end][1] # if it's the last process on top of the hierarchy, saves the dict
		for iter_idx in 1:num_of_iterations
			open("$(tm_folder)/template_matching_ext_$(extension_surr)_$(name_vid)_iter$(iter_idx).json", "w") do file # the folder has to be already present 
				JSON.print(file, my_dict[iter_idx])
			end # open counts
		end # for iter_idx in 1:num_of_iterations
	end # if rank == levels[end][1]
end # EOF

"""
get_steps_convergence
Function to get the steps for final convergence across mergers. It works with the indeces of each merger within
the initial mergers array and the levels afterwards, whatever is the actual number of the process. It creates a tree
s.t. there is a hierarchical convergence. The idea is that odd indeces receive dicts from even ones and merge them 
and this is iterated through multiple steps.
INPUT:
- vec::Vector{Int} or ::UnitRange{Int} -> the vector of mergers

OUTPUT:
- levels::Vector{Vector{Int}} -> a vector containing each step of convergence, e.g. [[0, 1, 2, 3, 4, 5], [0, 2, 4], [0, 4], [0]]

"""

function get_steps_convergence(vec)
	levels = [collect(vec)] # in case arr was a UnitRange{Int64}
	global count = 0 # count of the level
	@info "levels: $(levels[end])"
	while length(levels[end]) > 1 # it ends when length(nxt_lvl)==1
		global count += 1
		@info "count $count"
		current_lvl = levels[end]
		idx = 1:2:length(current_lvl) # takes all the odds indeces in current lvl
		nxt_lvl = current_lvl[idx]
		push!(levels, nxt_lvl) # updates the levels array
	end # while length(levels[end]) > 1
	return levels
end #EOF

"""
merge_vec_dicts
Function to merge vectors of dictionaries together as done before (but without comprehension format).
Uses mergewith! which is an inplace operator, so tot_dicts is modified and there is no need to assign it
again to another variable.
INPUT:
- tot_dicts::Vector{Dict{BitVector, Int}} -> dictionaries of the merger
- new_dicts::Vector{Dict{BitVector, Int}} -> dictionaries received by the merger to merge to tot_dicts
- num_of_iterations::Int -> number of iterations of coarse-graining done
"""
function merge_vec_dicts(tot_dicts, new_dicts, num_of_iterations)
	if isnothing(new_dicts) # there is no need for a condition upon tot_dicts because it can't be that the dict lower in the scale should always have something or if it doesn't have anything, the other doesn't have anything too
		return nothing # dnt care about what the function returns, it actually means nothing since it changes stuff in place
	# elseif tot_dicts == nothing && new_dicts != nothing
	# 	return new_dicts
	# elseif tot_dicts != nothing && new_dicts == nothing
	# 	return tot_dicts
	else
		for iter in 1:num_of_iterations
			mergewith!(+, tot_dicts[iter], new_dicts[iter])
		end # for iter in 1:num_of_iterations
		return tot_dicts
	end # if tot_dicts==nothing && new_dicts==nothing
end # EOF 


function send_large_data(data, dst, tag, comm)
	size_data = length(data)
	onsets = collect(0:2000000000:size_data)
	status = MPI.send(UInt32(length(onsets)), dst, tag, comm)
	append!(onsets, size_data)
	count = 0
	for ichunk in 1:length(onsets)-1
		chunk = data[onsets[ichunk]+1:onsets[ichunk+1]]
		count += 1
		status = MPI.send(chunk, dst, tag + count, comm)
	end # for ichunk in 1:length(onsets)-1
end #EOF

function rec_large_data(src, tag, comm)
	len_onsets, status = MPI.recv(src, tag, comm)
	if len_onsets == 1
		tot_steps = 1
	else
		tot_steps = len_onsets
	end # if len_onsets ==1
	data_rec = Vector{UInt8}()
	count = 0
	for ichunk in 1:tot_steps
		count += 1
		chunk, status = MPI.recv(src, tag + count, comm)
		append!(data_rec, chunk)
	end # for ichunk in 1:length_onsets-1
	return data_rec
end #EOF



"""
jsd_master
Sends to each worker its part of dict to run jsd on it and receive the parts back to sum.

INPUT:
- d1, d2::Dict{Int, UInt} -> the dicts to compare
- rank::Int -> the rank of the master
- nproc::Int -> number of processes
- comm::MPI.comm -> the communication graph

OUTPUT
- tot_jsd::Float32 -> the total jsd returned	
"""
function jsd_master(d1, d2, rank, nproc, comm)
	global tot_jsd = 0
	@info "I am root"

	k1 = collect(keys(d1))
	k2 = collect(keys(d2))
	k = union(k1, k2)
	keys_num = length(k)
	@info "num keys $keys_num"
	jump = cld(keys_num, nproc - 1)
	@info "jump: $jump"
	global current_start = Int32(0) # is the number of iterations we will drop before our target, that's why we start from 0
	global tot = 0
	for dst in 1:(nproc-1) # loops over the processors to deal the task
		@info "curr proc: $dst"
		start = current_start + 1
		global current_start += jump
		finish = current_start
		if finish > keys_num
			finish = keys_num
		end # if finish > keys_num

		@info "start: $start ; finish: $finish"
		curr_keys = k[start:finish]
		global tot += length(curr_keys)
		set_keys = Set(curr_keys)
		subset_d1 = filter(d1 -> d1[1] in set_keys, d1)
		subset_d1 = MPI.serialize(subset_d1)
		subset_d2 = filter(d2 -> d2[1] in set_keys, d2)
		subset_d2 = MPI.serialize(subset_d2)
		send_large_data(subset_d1, dst, dst + 32, comm)
		send_large_data(subset_d2, dst, dst + 32, comm)

	end # for dst in 1:(nproc-1)

	for dst in 1:(nproc-1)
		local jsd_part = MPI.recv(comm; source = dst, tag = dst)
		global tot_jsd += jsd_part
	end # for i in 1:(nproc-1)
	@info "tot jsd = $tot_jsd"
	return tot_jsd
end #EOF


"""
jsd_workers
Each worker takes its part of dict to run jsd on it.
INPUT:
- root::Int -> the master
- rank::Int -> the rank of the worker
- comm::MPI.comm -> the communication graph

OUTPUT
none
"""

function jsd_workers(root, rank, comm)
	d1 = rec_large_data(0, rank + 32, comm)
	d1 = MPI.deserialize(d1)
	d2 = rec_large_data(0, rank + 32, comm)
	d2 = MPI.deserialize(d2)
	jsd_part = Float32(jsd(d1, d2))
	@info "jsd_part $jsd_part"
	MPI.send(jsd_part, Int32(0), rank, comm)
end # EOF

"""
partial_json2intdict
Converts to a dict only a selected subset of keys
INPUT:
- str_dict::Dict{string, Int} -> dictionary converted with json
- keys::Vector{Int} -> subset of keys to convert into dict

OUTPUT:
- int_dict::Dict{Int64, UInt64} -> int dict with just the subset of keys
"""
function partial_json2intdict(str_dict, keys)::Dict{Int64, UInt64}
	int_dict = Dict{Int64, UInt64}()      # Preallocate target dict
	str_keys = Set(string.(keys))

	for key in keys
		# try
		int_key = parse(Int64, key)
		int_dict[int_key] = str_dict[key]
		# catch e
		# 	println("Skipping entry ($key => $value): ", e)
		# end
	end
	return int_dict
end

"""
master_json2intdict
Sends to the workers the different subset of keys and then merges the converted parital dicts
INPUT:
- str_dict::Dict{Int64, UInt64} -> the dict already parsed with JSON
- nproc::Int -> the number of processes to loop over
- tag::Int the communication tag to use
- comm -> communication world
"""
function master_json2intdict(str_dict, nproc, tag, comm)
	k = collect(keys(str_dict))
	keys_num = length(k)
    #sum_counts = sum(values(str_dict))
	@info "num keys $keys_num"
	jump = cld(keys_num, nproc - 1)
	global current_start = Int32(0)
	for dst in 1:(nproc-1) # loops over the processors to deal the task
		@info "curr proc: $dst"
		start = current_start + 1
		global current_start += jump
		finish = current_start
		if finish > keys_num
			finish = keys_num
		end # if finish > keys_num

		@info "start: $start ; finish: $finish"
		vec2send = [start, finish]
		MPI.send(vec2send, dst, tag + dst, comm)
	end # for dst in 1:(nproc-1)
	d = Dict{Int, UInt}()
	for i in 1:(nproc-1)
		rec_d = rec_large_data(MPI.ANY_SOURCE, tag, comm)
		rec_d = MPI.deserialize(rec_d)
		mergewith!(+, d, rec_d)
	end # for i in 1:(nproc-1)
	keys_num_int = length(collect(keys(d)))
	if keys_num_int != keys_num
		@error "the number of int keys is different from the number of str keys"
	end # if keys_num_int != keys_num
    #if sum_counts != sum(values(d))
    #    @error "the sum of the counts doesn't coincide"
    #end
	return d
end

"""
workers_json2intdict
Each worker receives a different subset of keys and then merges the converted parital dicts
INPUT:
- str_dict::Dict{Int64, UInt64} -> the dict already parsed with JSON
- rank::Int -> the rank of the worker
- root::Int -> the rank of the master
- tag::Int the communication tag to use
- comm -> communication world
"""

function workers_json2intdict(str_dict, rank, root, tag, comm)
	k = collect(keys(str_dict))
	keys_margins, status = MPI.recv(root, tag + rank, comm)
	@info "rank $rank : received margins $keys_margins"
	curr_keys = k[keys_margins[1]:keys_margins[2]]
	partial_d = partial_json2intdict(str_dict, curr_keys)
	partial_d = MPI.serialize(partial_d)
	send_large_data(partial_d, root, tag, comm)
	parital_d = nothing
end

end # module SIP_package
