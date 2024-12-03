function del_wins(myDict, win)
"""
Deletes all the windows within myDict that are one step away 
from the target window win. It flips twice because I always want to 
start with the initial win and copying it would be less efficient.

Inputs:
- myDict -> the dict with the respective counts 
- win -> the extracted win (typically the current max of myDict)

Output:
- myDict -> modified, i.e. with non local maxima elements deleted
"""
    for position = 1 : length(win) # changes one element at the time
       win = flip_element(win, position) # flips the window element in "position" 
       if haskey(myDict, win)   # it might have been already deleted or not present 
           delete!(myDict, win) # if it's still there, deletes the elements with lower probability 
       end # if haskey
       win = flip_element(win, position) # returns the initial win (it was less expensive than copying the key)
    end # for position 
    return myDict
end # EOF