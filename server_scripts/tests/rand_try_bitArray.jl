# time1 = @elapsed begin
# aa = zeros(Bool,10000,10000,50)

# end
# ##
# time2 = @elapsed begin 
# bb = BitArray(undef, 10000,10000,50)
# fill!(bb, false)
# end
##
aa= nothing
bb = nothing
##
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/video_conversion.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/get_dimensions.jl")
##
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/color2BW.jl")
using Colors, Images, VideoIO, Statistics, HDF5
##
aa = rand(RGB, 256,256)
## 
a = color2BW(aa)
##
Gray.(a)
##
fn = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/test_venice.mp4"
##
new_vid = video_conversion(fn)
##
typeof(new_vid)
##
Base.summarysize(new_vid)
##
new_vid = vec(new_vid)
##
# loads and opens the video
# video_load = VideoIO.load(file_name) # to add if you will convert directly the videos from the internet

reader = VideoIO.openvideo(fn)

# stores quantities for preallocation
frame_1, height, width, frame_num = get_dimensions(reader) # reads the first frame to get the dimensions of the movie and returns what you see in variable assignment
jump = 100
BW_vid = BitArray(undef, height, width, jump) # preallocates a boolean matrix of zeros, s.t. we then substitute ones where gray_frame > gray_median is true 
fill!(BW_vid,false)
#BW_vid = BitArray(BW_vid_bool);
count = 1 # index for later storing frames, starts from one because we already read the first frame
BW_vid[:,:,count] = color2BW(frame_1) # special treatment for frame_1 because we have already read it
##
start_frame = 1
seek(reader, start_frame)
##
 count = 0
for i = 1 : jump
    count += 1 # updates the count
    frame = VideoIO.read(reader)  # reads the movie
    BW_vid[:,:,count] = color2BW(frame) # assigns the binarized frame to the array
end # while 
close(reader) # closes the reader


