function color2BW(frame)
"""converts an RGB array into a bool array"""

    gray_frame = Gray.(frame) # converts the frame from RGB to grayscale
    gray_median = median(gray_frame) # do we have to handle differently the case in which the pix is equal to the median?
    BW_frame= gray_frame .> gray_median # it is true(=1=white) only where the grayscale value is greater than the median. Then it broadcasts the ones in the correct positions of the array. The zeros are already there.
return BW_frame
end # EOF