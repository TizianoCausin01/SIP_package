using Pkg
cd("/home/tcausin/SIP_package/SIP_dev")
Pkg.activate(".")
using VideoIO
using SIP_package
file_name = "ukraine"
path2vid = "/home/tcausin/data/SIP_data/$(file_name)_split/$(file_name)000.mp4"
##
reader = VideoIO.openvideo(path2vid)
global count = 0
while !eof(reader) # it loops until the last frame has been read
    global count += 1 # updates the count
    frame = VideoIO.read(reader)  # reads the movie
    @info "frame $(count)"
end # while 
##
using Images
ba = video_conversion(path2vid)
@info "video converted successfully"
