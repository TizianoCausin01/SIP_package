## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/")
Pkg.activate("SIP")

## imports useful packages
using Images
using VideoIO
using Statistics
using HDF5

##
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/video_conversion.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/color2BW.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/get_dimensions.jl")
file_name = "/Users/tizianocausin/Desktop/backUp20240609/summer2024/dondersInternship/images_for_presentation/Moviesnippet_quick.mp4"
path2save = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/results/test_1.h5"
vid = video_conversion(file_name)
h5write(path2save, "test_1", vid_bool)
##

imshow(Gray.(vid[:,:, 650]))
522*1280 / sum(vid[:,:, 650])

##




