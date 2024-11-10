##
using HDF5
##
bin_file = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid/test_nature.h5"

## loads the file
bin_vid = h5read(bin_file, "test_nature"); #data = h5read("/tmp/test2.h5", "mygroup2/A", (2:3:15, 3:5))
##

##
video_dim = size(bin_vid) # rows, cols, depth
glider_coarse_g_dim = (3,3,1) # rows, cols, depth
new_dim = get_new_dimensions(video_dim, glider_coarse_g_dim)

##
new_vid = zeros(Bool,new_dim) # preallocation
tot_steps = compute_steps_glider(glider_coarse_g_dim, video_dim)
volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
cutoff = volume / 2 # sets the cutoff for the majority rule 
##
counter_new_mat = [0, 0, 0] # rows, cols, depth initializes a new counter for indexing in the new matrix
for i_time = tot_steps[3]
    idx_time = i_time : i_time + glider_coarse_g_dim[3] - 1 # you have to subtract one, otherwise you will end up getting a bigger glider
    counter_new_mat[3] += 1 # updates the counter accordingly
    counter_new_mat[1] = 0 # sets the counter of the inner loop to zero s.t. it doesn't overindex
    for i_rows = tot_steps[1]
        idx_rows = i_rows : i_rows + glider_coarse_g_dim[1] - 1
        counter_new_mat[1] += 1
        counter_new_mat[2] = 0 # sets the counter of the inner loop to zero s.t. it doesn't overindex
        for i_cols = tot_steps[2]
            idx_cols = i_cols : i_cols + glider_coarse_g_dim[2] - 1
            counter_new_mat[2] += 1
            white_count = sum(bin_vid[idx_rows, idx_cols, idx_time]) # index in video, gets the current window and immediately sums over it. 
            new_vid[counter_new_mat[1], counter_new_mat[2], counter_new_mat[3]] = majority_rule(white_count, cutoff) # assigns the pixel of the coarse grained video in the correct position
        end # cols
    end # rows
end # time

##
using Images
using ImageView
img = Gray.(new_vid)
imshow(new_vid)
##

