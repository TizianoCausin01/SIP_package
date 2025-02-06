## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using Revise
using SIP_package
using Images
##
data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_venice" # file name across different manipulations
video_path = "$data_dir/$file_name.mp4" # file path to the yt video
##
data = whole_video_conversion(video_path)
##
A = trues(3, 3, 3)
A[:, 2, :] .= 0

##
arr, count = SIP_package.template_matching(data[:, :, 1:100], A, 3)
##
aa = arr / count
for i in 1:9
	display(Gray.(aa[:, :, i]))
	sleep(0.5)
end
