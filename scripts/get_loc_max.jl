function get_loc_max(myDict)
"""
Given a dictionary with the corresponding counts of the sampled windows, 
it returns the local max, i.e. those windows that, if you flip one (only one)
pixel (in any of the positions), the probability won't increase.
Details about the algorithm: 
- for each key in the dict
    - flip any element in the key separately
    - see if the frequency increases
    - if so, stop comparing
    - otherwise add

input:
- myDict -> Dict{BitVector, Int}, a dictionary with the frequency of sampled windows

output:
- loc_max -> Array{Vector{Bool}} with the local maxima in order of frequency

Dict{BitVector, Int}
"""
    loc_max = Array{Vector{Bool}}(undef,0) # initializes as a Bool because you can't expand BitArray
    for element in myDict # loops through every element
        win = element.first # extracts the key
        max = is_max(myDict, win) # inspects if it's a max
        if ~(max===nothing) # if max exists, updates loc_max
            push!(loc_max, max)
        end # if max exists
    end # for every element
return loc_max # returns the loc_max
end # EOF