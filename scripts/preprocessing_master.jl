## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/")
Pkg.activate("SIP")

## imports useful packages
using Images
using VideoIO
using Statistics
using HDF5
using ImageView

## including functions
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/video_conversion.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/color2BW.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/get_dimensions.jl")
#file_name = "/Users/tizianocausin/Desktop/backUp20240609/summer2024/dondersInternship/images_for_presentation/Moviesnippet_quick.mp4"

## configuration variables assignment
data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_nature" # file name across different manipulations
file_path = "$data_dir/$file_name.mp4" # file path to the yt video
bin_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid/" # directory where we store binarized videos
bin_file = "$bin_dir/$file_name.h5"

## video conversion and storing
vid_bool = video_conversion(file_path) # converts a target yt video into a binarized one
h5write(bin_file, "test_nature", vid_bool) # saves the video (complete_file_path, name_of_variable_when_retrieved, current variable name)

## sampling patches



##






