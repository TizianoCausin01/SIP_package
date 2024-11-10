function glider_coarse_g(bin_vid, tot_steps, glider_coarse_g_dim, cutoff)
"""It's the glider for coarse graining. Loops over all the steps 
   and returns a new video which is the old video coarse grained. 
   Inputs :
   - bin_vid -> the binarized video from the previous iteration
   - tot_steps -> a tuple created with get_steps which has 3 
                  arrays of numbers, one for each dimension. It 
                  indicates the onset of each new step
   - glider_coarse_g_dim -> tuple with the dimensions of the coarse graining
   - cutoff -> given the dimensions of the glider, the cutoff for the majority rule"""
   

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
    return new_vid
    end # EOF