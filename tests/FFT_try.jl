using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
#Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using SIP_package
using FFTW
using VideoIO
using Images
using Plots
using Statistics
##
name_vid = "test_venice_long"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split/"
split_files = "$(split_folder)/$(name_vid)001.mp4"
##
# bin_vid = whole_video_conversion(split_files)
## since it's not exported from SIP_package
function get_dimensions(reader)
	frame_num = VideoIO.counttotalframes(reader) # total number of frames
	frame_1 = VideoIO.read(reader) # stores the first frame to get the height and width
	height, width = size(frame_1)
	return frame_1, height, width, frame_num
end # EOF

##
reader = VideoIO.openvideo(split_files)
frame, height, width, depth = get_dimensions(reader)
gray_float_array = Array{Float64}(undef, height, width, depth) # preallocates an array of grayscale values
# array_bits = BitArray(undef, height, width, depth) # preallocates a BitArray
copyto!(view(gray_float_array, :, :, 1), Float64.(Gray.(frame))) # copies the first frame into the first element of the gray_array
count = 1
#while !eof(reader)
for i in 1:10
	count += 1
	frame = VideoIO.read(reader)
	gray_float_array[:, :, count] = Float64.(Gray.(frame))
end # end while !eof(reader)
##
# Temporal FFT
fft_time = FFTW.fft(gray_float_array[:, :, 1:30], 3)  # Along time dimension 
##
# can I do an average of averages?
avg_fft_time = mean(abs.(fft_time), dims = (1, 2))
##
avg_fft_time_1 = dropdims(avg_fft_time, dims = (1, 2))
##
plot(log.(abs.(fft_time[1, 1, :])))
##
plot(log.(1:50), log.(avg_fft_time_1))
##
# Spatial FFT (per frame)
fft_space = fft(gray_float_array[:, :, 1], (1, 2))  # Along spatial dimensions
##

# Full 3D FFT
fft_3d = fft(bin_vid)

