function glider(bin_vid, glider_dim, tot_steps)
    """Creates a glider that slides over the given binarized video 
       and counts the configuration occurrences.
       Inputs : 
       - bin_vid -> the binarized (Bool) video
       - glider_dim -> a tuple with the three dimensions of the glider
       - tot_steps -> a tuple with three arrays, i.e. the starting points of the steps 
                      the glider will have to do
       Outputs :
       - counts -> it's a dict with vec{Bool} as keys and Int as values. 
                   It stores the counts of windows configurations"""

counts = Dict{Vector{Bool}, Int}()
for i_time = tot_steps[3]
    idx_time = i_time : i_time + glider_dim[3] - 1 # you have to subtract one, otherwise you will end up getting a bigger glider
    for i_rows = tot_steps[1]
        idx_rows = i_rows : i_rows + glider_dim[1] - 1
        for i_cols = tot_steps[2]
            idx_cols = i_cols : i_cols + glider_dim[2] - 1
            window = vec(bin_vid[idx_rows, idx_cols, idx_time]) # index in video, gets the current window and immediately vectorizes it. 
            counts = update_count(counts, window)
        end # cols
    end # rows
end # time
return counts
end # EOF