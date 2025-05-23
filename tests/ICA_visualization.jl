using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")

using SIP_package
using Images
using HDF5
using JSON
using Serialization
results_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/ICs"
name_vid = "cenote_caves"
tot_n_vids = 50
ratio_denom = 50
frame_seq = 2
path2file = "$(results_path)/ICs_$(name_vid)_$(tot_n_vids)vids_$(ratio_denom)resize_$(frame_seq)frames.jls"
##
# h5open("$(results_path)/ICs_$(name_vid)_$(tot_n_vids)vids_$(ratio_denom)resize_$(frame_seq)frames.h5", "r") do file
# 	global img = read(file["comp_1"])
# end
##
data = deserialize(path2file)

##
comp = data[3]
n_frames = size(comp, 3)
for i in 1:n_frames
	@info "$i"
	display(Gray.(comp[:, :, i]))
	sleep(0.5)
end
