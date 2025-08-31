## select correct virtual environment
using Pkg
cd("/home/tcausin/SIP_package/SIP_dev")
Pkg.activate(".")
using VideoIO
using Images
using Statistics

##
path2vid = "/home/tcausin/data/SIP_data/virtual_treadmill_split/virtual_treadmill002.mp4"
#reader = VideoIO.openvideo(path2vid)
global frame_count=0
using VideoIO
path2vid = "/home/tcausin/data/SIP_data/virtual_treadmill_split/virtual_treadmill002.mp4" 
reader = VideoIO.openvideo(path2vid)

using VideoIO

# Define the path globally 
global path2vid = "/home/tcausin/data/SIP_data/virtual_treadmill_split/virtual_treadmill002.mp4"
global reader = nothing
try
    # First, let's try opening with explicit format settings
    global reader = VideoIO.openvideo(path2vid, target_format=VideoIO.AV_PIX_FMT_RGB24)
    
    # Pre-allocate buffer based on the known dimensions
    width = 3840   # From the ffmpeg output
    height = 2160  # From the ffmpeg output
    buffer = Array{UInt8}(undef, height, width, 3)
    
    # Try reading with careful memory management
    try
        # Read just one frame to test
        frame = read(reader)
        println("Successfully read frame")
        println("Frame dimensions: ", size(frame))
        
    catch frame_err
        println("Frame reading error: ", frame_err)
        
        # If that didn't work, we might need to transcode the video first
        println("Consider transcoding the video to a more compatible format:")
        println("ffmpeg -i $path2vid -c:v libx264 -preset medium output.mp4")
    end
    
catch e
    println("Error opening video: ", e)
end
while !eof(reader) # it loops until the last frame has been read
                global frame_count += 1 # updates the count
                @info "frame $(frame_count)"
                frame = VideoIO.read(reader)  # reads the movie
end # while 


function get_frame_num(file_name)
	cmd = `/usr/bin/ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 $(file_name)`
	frame_n = readchomp(cmd)	
	frame_n = parse(Int, strip(frame_n))
	@info "frame_num: $frame_n"
	@info typeof(frame_n)
	return frame_n
end # EOF


##
function video_conversionn(file_name)
        # loads and opens the video
        # video_load = VideoIO.load(file_name) # to add if you will convert directly the videos from the internet
        reader = VideoIO.openvideo(file_name)
        # stores quantities for preallocation
        frame_1, height, width, frame_num = get_dimensions(reader, file_name) # reads the first frame to get the dimensions of the movie and returns what you see in variable assignment
        BW_vid = BitArray(undef, height, width, frame_num) # preallocates a boolean matrix of zeros, s.t. we then substitute ones where gray_frame > gray_median is true 
        fill!(BW_vid, false)
        #BW_vid = BitArray(BW_vid_bool);
        count = 1 # index for later storing frames, starts from one because we already read the first frame
        BW_vid[:, :, count] = color2BW(frame_1) # special treatment for frame_1 because we have already read it

        while !eof(reader) # it loops until the last frame has been read
                count += 1 # updates the count
		@info "frame $(count)"
		frame = VideoIO.read(reader)  # reads the movie
                BW_vid[:, :, count] = color2BW(frame) # assigns the binarized frame to the array
        end # while 
        close(reader) # closes the reader
        # bit_vid = BitArray(BW_vid) # converts the bool vid into a BitArray for optimization
        return BW_vid
end # EOF


function get_dimensions(reader, file_name)
	frame_num = get_frame_num(file_name) # total number of frames
        frame_1 = VideoIO.read(reader) # stores the first frame to get the height and width
        height, width = size(frame_1)
        return frame_1, height, width, frame_num
end # EOF


function color2BW(frame)
        gray_frame = Gray.(frame) # converts the frame from RGB to grayscale
	gray_median = median(gray_frame)
        BW_frame = gray_frame .> gray_median # it is true(=1=white) only where the grayscale value is greater than the median. Then it broadcasts the ones in the correct positions of the array. The zeros are already there.
        return BW_frame
end # EOF


##
print(typeof(get_frame_num(path2vid)))
sleep(2)
video_conversionn(path2vid)

