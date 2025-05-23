using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using Statistics
using SIP_package
##
name_vid = "test_venice_long"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split/"
split_files = "$(split_folder)/$(name_vid)001.mp4"
##
using Images
using VideoIO
##
function whole_video_conversion(path2file::String)::BitArray{3}
	reader = VideoIO.openvideo(path2file)
	frame, height, width, depth = get_dimensions(reader)
	gray_array = Array{Gray{N0f8}}(undef, height, width, depth) # preallocates an array of grayscale values
	array_bits = BitArray(undef, height, width, depth) # preallocates a BitArray
	copyto!(view(gray_array, :, :, 1), frame) # copies the first frame into the first element of the gray_array
	count = 1
	while !eof(reader)
		count += 1
		frame = VideoIO.read(reader)
		gray_array[:, :, count] = Gray.(frame)
	end # end while !eof(reader)
	median_value = median(array_gray_scale)
	@. array_bits = gray_array < median_value # broadcasts the value in the preallocated array
end # EOF
##
@time aa = whole_video_conversion(split_files);
## 
@time bb = video_conversion(split_files);
##
print(typeof(aa[:, :, 1]))
print(typeof(bb[:, :, 1]))


