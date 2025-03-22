using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using SIP_package
using Images
using VideoIO
#using ImageIO
using Images
using MultivariateStats
name_vid = "test_venice_long"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split"
split_files = "$(split_folder)/$(name_vid)001.mp4"
##
# bin_vid = whole_video_conversion(split_files)
## since it's not exported from SIP_package
# function get_dimensions(reader)
# 	frame_num = VideoIO.counttotalframes(reader) # total number of frames
# 	frame_1 = VideoIO.read(reader) # stores the first frame to get the height and width
# 	height, width = size(frame_1)
# 	return frame_1, height, width, frame_num
# end # EOF

n_vids = 15 # num of samples
ratio_denom = 50
frame_seq = 3 # concatenates n frames
frames2skip = 5
n_comps = 3
gray_array = prepare_for_ICA(split_files, n_vids, ratio_denom, frame_seq, frames2skip)
##
# here ICA wants the datamatrix X as samples x features
model = MultivariateStats.fit(ICA, gray_array, n_comps) # use dot notation because otherwise it's in conflict with the original fit function 
##
comps = transform(model, gray_array)
# ##
# ICFs = model.W
vid_comp = Gray.(reshape(comps[2, :], height_sm, width_sm, frame_seq))
# for i in 1:frame_seq
# 	display(Gray.(vid_comp[:, :, i]))
# 	sleep(0.5)
# end
##
