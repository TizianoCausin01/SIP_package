using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using VideoIO
##
path2vid = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/short.mp4"
reader = VideoIO.openvideo(path2vid)
##
typeof(get_frame_count(reader))

##
function get_frame_count(reader)
	path_name = reader.avin.io
	cmd = `ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of csv=p=0 $(path_name)`
	out = String(read(cmd)) # outputs something like 512,\n
	cleaned_out = replace(strip(out), "," => "")  # Remove the trailing comma
	frame_count = parse(Int, cleaned_out)
	return frame_count
end # EOF
##
typeof(reader)
