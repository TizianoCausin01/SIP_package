## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using VideoIO
using SIP_package
##
path2vid = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/virtual_treadmill001.mp4"
#path2vid = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/ukraine000.mp4"
reader = VideoIO.openvideo(path2vid)
##
SIP_package.video_conversion(path2vid)
##
count = 0
while !eof(reader) # it loops until the last frame has been read
	count += 1 # updates the count
	@info "frame: $(count)"
	frame = VideoIO.read(reader)  # reads the movie
end # while 
