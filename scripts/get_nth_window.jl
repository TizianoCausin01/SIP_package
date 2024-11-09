function get_nth_window(idx, sorted_counts, glider_dim)
"""From Vector{Pair{Vector{Bool}, Int}} which is the counts_dict 
   after it has been sorted, this function gets the nth top window, 
   unflattens it and turns it into gray values to be visualized 
   inputs : 
   - idx -> the rank of the window, in descending order
   - sorted_counts -> the counts_dict after it has been sorted, 
     type: Vector{Pair{Vector{Bool}, Int}}
   - glider_dim -> the dimensions of the glider, to unflatten the vectorized window"""
   
window = sorted_counts[idx].first # gets the window from the dict
r_window = reshape(window, glider_dim) # reshapes it according to the glider dimensions
gray_window = Gray.(r_window) # turns it into gray to visualize it
count = sorted_counts[idx].second
return gray_window, count
end # EOF