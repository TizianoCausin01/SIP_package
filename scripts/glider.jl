function glider(bin_vid, glider_dim)
    """Creates a glider that slides over the given binarized video 
       and counts the configuration occurrences.
       Inputs : 
       - bin_vid -> the binarized (Bool) video
       - glider_dim -> a tuple with the three dimensions of the glider
       
       Outputs :
       - counts -> it's a dict with vec{Bool} as keys and Int as values. 
                   It stores the counts of windows configurations"""

counts = Dict{Vector{Bool}, Int}()
vid_dim = size(bin_vid)
for i_time = 1 : vid_dim[3] - glider_dim[3] # step of sampling glider = 1
    idx_time = i_time : i_time + glider_dim[3] - 1 # you have to subtract one, otherwise you will end up getting a bigger glider
    for i_rows = 1 : vid_dim[1] - glider_dim[1]
        idx_rows = i_rows : i_rows + glider_dim[1] - 1
        for i_cols = 1 : vid_dim[2] - glider_dim[2]
            idx_cols = i_cols : i_cols + glider_dim[2] - 1
            window = vec(bin_vid[idx_rows, idx_cols, idx_time]) # index in video, gets the current window and immediately vectorizes it. 
            counts = update_count(counts, window)
        end # cols
    end # rows
end # time
return counts
end # EOF