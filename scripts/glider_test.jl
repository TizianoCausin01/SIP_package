##
using HDF5
##
bin_file = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid/test_nature.h5"

## loads the file
bin_vid = h5read(bin_file, "test_nature"); #data = h5read("/tmp/test2.h5", "mygroup2/A", (2:3:15, 3:5))

## gets the dimensions of the file
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/compute_steps_glider.jl")
video_dim = size(bin_vid) # rows, cols, depth
glider_dim = (2, 2, 1) # rows, cols, depth
tot_steps = compute_steps_glider(glider_dim, video_dim) # creates a tuple with the steps the glider will have to do in each dimension. Each number in the list is the initial element in the new window. It subtracts the glider_dim such that we won't overindex

## creates the dict and populates it with the glider
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/update_count.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/glider.jl")
counts = glider(bin_vid, glider_dim, tot_steps)

##
sorted_counts = sort(collect(counts), by=x -> x[2], rev=true)
##
idx = 1
window = sorted_counts[idx].first # gets the window from the dict
r_window = reshape(window, glider_dim) # reshapes it according to the glider dimensions
gray_wind = Gray.(r_window) # turns it into gray to visualize it

##

##
#nxt steps:

# make glider a function
# learn how to sort/unflatten keys
# git commit
# start coarse graining 