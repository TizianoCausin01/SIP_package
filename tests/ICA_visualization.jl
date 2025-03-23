using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")

using SIP_package
using Images
using HDF5

results_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/ICs"
name_vid = "test_venice_long"
tot_n_vids = 16
ratio_denom = 50
frame_seq = 3
path2file = "$(results_path)/ICs_$(name_vid)_$(tot_n_vids)vids_$(ratio_denom)resize_$(frame_seq)frames.h5"
##
h5open("$(results_path)/ICs_$(name_vid)_$(tot_n_vids)vids_$(ratio_denom)resize_$(frame_seq)frames.h5", "r") do file
	global img = read(file["comp_1"])
end
##
n_frames = size(img, 3)
for i in 1:n_frames
	@info "$i"
	display(Gray.(img[:, :, i]))
	sleep(0.5)
end
