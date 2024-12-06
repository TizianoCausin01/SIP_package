function is_max(myDict, win)
"""
Flips the target "win" to see if there is one with higher frequency,
if there is it returns nothing, if there isn't we have found a local maximum

Inputs:
- myDict -> the dict with the respective counts 
- win -> the extracted win (typically the current max of myDict)

Output:
- if it's local maximum : win 
- if it's not : nothing

"""
win_freq = myDict[win]
    for position = 1 : length(win) # changes one element at the time
       win = flip_element(win, position) # flips the window element in "position" 
       if haskey(myDict, win) &&  myDict[win] > win_freq # new win might have been not present 
            win = flip_element(win, position) # flips the element again to return the initial window
            return nothing # don't include win in local maxima if it breaks the loop (counter<length(win))
       end # if haskey & win_flipped > win
       win = flip_element(win, position) # flips the element again
    end # for position 
    return win # only if it is a local max
end # EOF