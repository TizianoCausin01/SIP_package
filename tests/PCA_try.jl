using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using SIP_package
using Images
using VideoIO
using Random
#using ImageIO
using Images
using LinearAlgebra
using Statistics
using MultivariateStats
name_vid = "test_venice_long"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split"
split_files = "$(split_folder)/$(name_vid)001.mp4"
##
##
seek(reader, 4)
frame = VideoIO.read(reader)
##
VideoIO.testvideo(reader)
##
n_vids = 10 # num of samples
ratio_denom = 50
frame_seq = 2 # concatenates n frames
gray_array = prepare_for_ICA(split_files, n_vids, ratio_denom, frame_seq)
##
n_comps = 4
model = MultivariateStats.fit(PCA, gray_array'; maxoutdim = n_comps)
##
evecs = projection(model)
##
reader = VideoIO.openvideo(split_files)
frame = VideoIO.read(reader)
##
height_sm, width_sm = size(imresize(frame, ratio = 1 / ratio_denom))
##
to_vis = Gray.(reshape(evecs[:, 4], height_sm, width_sm, frame_seq))
for i in 1:frame_seq
	display(to_vis[:, :, i])
	sleep(0.5)
end

##