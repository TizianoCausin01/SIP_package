using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")

using SIP_package
using MPI
using JSON
using Dates
using CodecZlib
using VideoIO
using Images
using Statistics
using Random
##
video_path = "/Users/tizianocausin/Desktop/bolt_moviechunk.mp4"
vid = whole_video_conversion(video_path)
##
function local_scrambling(vid)

end #EOF
##
range = 10
num_steps = fld(size(vid)[3], range)
global count = 0
for i in 1:num_steps
	curr_start = range * count + 1
	@info "curr_start $curr_start"
	curr_perm = (curr_start - 1) .+ randperm(range)
	@info "curr_perm $curr_perm"
	vid[:, :, curr_start:curr_start+range-1] = vid[:, :, curr_perm]
	global count += 1
end # for i in 1:num_steps
##
using Images, ImageView

function play_bitarray_video(bitarray::BitArray{3}; fps = 10)
	delay = 1 / fps
	for i in 1:size(bitarray, 3)
		imshow(bitarray[:, :, i])
		sleep(delay)
	end
end

##
play_bitarray_video(vid)
