using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using SIP_package
using Images
using VideoIO
using ImageIO
using Images
using MultivariateStats
name_vid = "test_venice_long"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split"
split_files = "$(split_folder)/$(name_vid)001.mp4"
##
# bin_vid = whole_video_conversion(split_files)
## since it's not exported from SIP_package
function get_dimensions(reader)
	frame_num = VideoIO.counttotalframes(reader) # total number of frames
	frame_1 = VideoIO.read(reader) # stores the first frame to get the height and width
	height, width = size(frame_1)
	return frame_1, height, width, frame_num
end # EOF
##
reader = VideoIO.openvideo(split_files)
##
n_vids = 2
ratio_denom = 50
frame_seq = 3 # concatenates n frames
frames2skip = 5
frame, height, width, depth = get_dimensions(reader)
frame_sm = imresize(frame, ratio = 1 / ratio_denom);
height_sm, width_sm = size(frame_sm)
gray_float_array = Array{Float64}(undef, n_vids, height_sm * width_sm * frame_seq) # preallocates an array of grayscale values
# copyto!(view(gray_float_array, 1, :), Float64.(vec(Gray.(frame_sm)))) # copies the first frame into the first element of the gray_array
count = 1
vid_temp = Array{Float64}(undef, height_sm, width_sm, frame_seq)
#while !eof(reader)
for i_vid in 1:n_vids
	for i_frame in 1:frame_seq
		frame = VideoIO.read(reader)
		frame_sm = imresize(frame, ratio = 1 / ratio_denom)
		vid_temp[:, :, i_frame] = Gray.(frame_sm)
	end
	frame_vec = vec(vid_temp)
	gray_float_array[i_vid, :] = frame_vec
	for _ in 1:frames2skip # to have distance across frames
		VideoIO.read(reader)
	end
end # end while !eof(reader)
##
# here ICA wants the datamatrix X as samples x features
model = MultivariateStats.fit(ICA, gray_float_array, 1) # use dot notation because otherwise it's in conflict with the original fit function 
##
comps = transform(model, gray_float_array)
##
ICFs = model.W
##
vid_comp = Gray.(reshape(comps[1, :], height_sm, width_sm, frame_seq))
for i in 1:frame_seq
	display(Gray.(vid_comp[:, :, i]))
	sleep(0.5)
end
##
