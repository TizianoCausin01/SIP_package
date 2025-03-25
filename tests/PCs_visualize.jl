
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using Images
using VideoIO
using Serialization
##
name_vid = "cenote_caves"
results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results/PCs"
tot_n_vids = 50
frame_seq = 2
path2file = "$(results_path)/PCs_$(name_vid)_$(tot_n_vids)vids_$(ratio_denom)resize_$(frame_seq)frames.jls"
PCs = deserialize(path2file);
# PCs_cenote_caves_50vids_50resize_2frames.jls
##
target_PC = PCs[16]
for i in 1:frame_seq
	display(Gray.(target_PC[:, :, i]) * 10)
	sleep(0.5)
end
