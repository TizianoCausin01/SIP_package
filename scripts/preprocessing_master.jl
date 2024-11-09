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
using HDF5
##
# for the preprocessing
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/video_conversion.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/color2BW.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/get_dimensions.jl")
# for sampling
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/update_count.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/compute_steps_glider.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/glider.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/function get_nth_window.jl")
#file_name = "/Users/tizianocausin/Desktop/backUp20240609/summer2024/dondersInternship/images_for_presentation/Moviesnippet_quick.mp4"

## configuration variables assignment
# paths for preprocessing
data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_nature" # file name across different manipulations
file_path = "$data_dir/$file_name.mp4" # file path to the yt video
bin_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid" # directory where we store binarized videos
bin_file = "$bin_dir/$file_name.h5"

# variables for sampling
glider_dim = (2, 2, 1) # rows, cols, depth

## video conversion and storing
vid_bool = video_conversion(file_path) # converts a target yt video into a binarized one
h5write(bin_file, "test_nature", vid_bool) # saves the video (complete_file_path, name_of_variable_when_retrieved, current variable name)

## sampling patches
# loads the file
bin_vid = h5read(bin_file, "test_nature"); #data = h5read("/tmp/test2.h5", "mygroup2/A", (2:3:15, 3:5))

# gets the dimensions of the file
video_dim = size(bin_vid) # rows, cols, depth
tot_steps = compute_steps_glider(glider_dim, video_dim) # creates a tuple with the steps the glider will have to do in each dimension. Each number in the list is the initial element in the new window. It subtracts the glider_dim such that we won't overindex

# creates the counts_dict and populates it with the glider
counts = glider(bin_vid, glider_dim, tot_steps)
sorted_counts = sort(collect(counts), by=x -> x[2], rev=true) # sorts the counts dictionary by values (by=x -> x[2]) in reverse order. To achieve this, it converts the dict in a Vector{Pair{Vector{Bool}, Int64}} in the first place 
##
window, count = get_nth_window(4, sorted_counts,glider_dim)
imshow(window)
##
