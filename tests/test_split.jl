## initialization
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using SIP_package
##
file_name = "test_venice_long"
path2original = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(file_name).mp4"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/test_venice_long_split"
split_files = "$(split_folder)/$(file_name)%03d.mp4"
##
split_vid(path2original, split_files, 10)
##
function ssplit_vid(path2data::String, file_name::String, segment_duration::Int)
	original_data = "$(path2data)/$(file_name).mp4"
	split_folder = "$(path2data)/$(file_name)_split"
	split_files = "$(split_folder)/$(file_name)%03d.mp4"
	if !isdir(split_folder) # checks if the directory already exists
		mkpath(split_folder) # if not, it creates the folder where to put the split_files
	end # if !isdir(dir_path)

	cmd = `
	/opt/homebrew/bin/ffmpeg
	-i $original_data
	-an
	-c:v copy
	-f segment
	-segment_time $segment_duration
	-reset_timestamps 1
	$split_files
`
	run(cmd) # runs the command
end # EOF
##
path2data = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/"
SIP_package.split_vid(path2data, "test_venice_long", 10)
## 
