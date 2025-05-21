# master, workers, mergers, master_merger
# master: allocates jobs
using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
# cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using SIP_package
using MPI
using JSON
using Dates
using CodecZlib
name_vid = ARGS[1]
split_folder = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/$(name_vid)_split"
# split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split"
split_files = "$(split_folder)/$(name_vid)%03d.mp4"
files_names = readdir(split_folder)
tasks = 1:n_tasks
# vars for sampling
glider_dim = (2, 2, 1) # rows, cols, depth
##
function wrapper_sampling_parallel(video_path, glider_dim)
	# video conversion into BitArray
	@info "running binarization,  free memory $(round(Sys.free_memory()/1024^3, digits=3)) max size by now: $(round(Sys.maxrss()/1024^3, digits=3))    $(Dates.format(now(), "HH:MM:SS"))"
	flush(stdout)
	bin_vid = whole_video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
	@info "before sampling: free memory $(round(Sys.free_memory()/1024^3, digits=3)) max size by now: $(round(Sys.maxrss()/1024^3, digits=3))   $(Dates.format(now(), "HH:MM:SS"))"
	counts = glider(bin_vid, glider_dim) # samples the current iteration
	@info "after sampling : free memory: $(round(Sys.free_memory()/1024^3, digits=3)) max size by now: $(round(Sys.maxrss()/1024^3, digits=3))   $(Dates.format(now(), "HH:MM:SS"))"
	flush(stdout)
	return counts
end # EOF
for file in files_names
	file_path = "$(split_folder)/$(file)"
	current_dict = wrapper_sampling_parallel(file_path, glider_dim)
	current_dict = MPI.serialize(current_dict)
	current_dict = transcode(ZlibCompressor, current_dict)
	@info "outside the function : free memory: $(round(Sys.free_memory()/1024^3, digits=3)) max size by now: $(round(Sys.maxrss()/1024^3, digits=3))   $(Dates.format(now(), "HH:MM:SS"))"
end # for file in files_names
