function flip_element(win, position)
"""
Takes a vectorized win of pixels and flips the element 
in the target position. It should modify the input win.
Used for computing the local maxima of PMFs
Inputs :
- win -> the vectorized window of pixels
- position -> the position of the target pixels

output :
- win -> the modified window
"""
    win[position] = 1 - win[position] # flips the value
    return win
end # EOF
