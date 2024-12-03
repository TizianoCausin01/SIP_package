function get_loc_max(myDict)
"""
Given a dictionary with the corresponding counts of the sampled windows, 
it returns the local max, i.e. those windows that, if you flip one (only one)
pixel (in any of the positions), the probability won't increase.
Details about the algorithm: 
- pick the key with the max value
- store it in loc_max
- remove all the keys obtained by flipping any one (only one) pixel
- remove the key with the max value
- reiterate until the dict is empty (with a while loop)

input:
- myDict -> Dict{BitVector, Int}, a dictionary with the frequency of sampled windows

output:
- loc_max -> Array{Vector{Bool}} with the local maxima in order of frequency

Dict{BitVector, Int}
"""
    loc_max = Array{Vector{Bool}}(undef, 0) # initializes it with 0 elements
    while ~isempty(myDict) # until all elements are considered
        freq, key = findmax(myDict) # finds the win associated with the highest value in myDict
        push!(loc_max, collect(key)) # stores the win
        delete!(myDict, key) # removes the win from the dict
        del_wins(myDict, key) # removes all the adjacent wins (lower probabilities)
    end # while until myDict is empty
return loc_max # returns the loc_max
end # EOF