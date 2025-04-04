## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using JSON
using Revise
using SIP_package
using Images
##
data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_venice_long" # file name across different manipulations
video_path = "$(data_dir)/$(file_name)_split/$(file_name)000.mp4" # file path to the yt video
results_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results"
loc_max_path = "$(results_dir)/$(file_name)_counts/loc_max_$(file_name)/loc_max_$(file_name)_iter1.json"
##
data = whole_video_conversion(video_path)
##
loc_max_dict = json2dict(loc_max_path)
dict_surr = template_matching(data[:, :, 1:10], loc_max_dict, (2, 2, 2), 2)
##
print(typeof(dict_surr[BitVector([1, 1, 1, 1, 1, 1, 1, 1])][2]))
##
key = BitVector([0, 0, 0, 0, 1, 1, 0, 0])
to_visualize = dict_surr[key][1] ./ dict_surr[key][2]
##
for i in 1:6
	display(Gray.(to_visualize[:, :, i]))
	sleep(0.5)
end

##
new_dict = mergewith(+, dict_surr, dict_surr)
##
loc_max_dict
##
for key in keys(loc_max_dict)
	to_vis = dict_surr[key][1] ./ dict_surr[key][2]

	for i in 1:6
		display(Gray.(to_vis[:, :, i]))
		sleep(0.5)
	end
end
##
to_vis == to_visualize
##

##
path2desk = "/Users/tizianocausin/Desktop/prova_dict.json"
open(path2desk, "w") do file
	JSON.print(file, dict_surr_vec)
end

surr_dims = (6, 6, 6)
a = load_dict_surroudings(path2desk, surr_dims)
to_vis = a[key][1] ./ a[key][2]
for i in 1:6
	display(Gray.(to_vis[:, :, i]))
	sleep(0.5)
end
##
surr_dims = (6, 6, 6)
arr_dict = Dict{BitVector, Tuple{Array{Integer}, Integer}}()
for key in keys(dict_surr_vec_new)
	arr_dict[key] = (reshape(dict_surr_vec_new[key][1], surr_dims), dict_surr_vec_new[key][2])
end
##
arr_dict[key][1]
##
key = BitVector([0, 0, 0, 0, 1, 1, 0, 0])
dict_surr[key]
##
