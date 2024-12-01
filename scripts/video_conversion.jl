function video_conversion(file_name)
"""reads and converts the video starting from the file name
uses color2BW and get_dimensions as functions"""

    # loads and opens the video
    # video_load = VideoIO.load(file_name) # to add if you will convert directly the videos from the internet
    reader = VideoIO.openvideo(file_name)
    # stores quantities for preallocation
    frame_1, height, width, frame_num = get_dimensions(reader) # reads the first frame to get the dimensions of the movie and returns what you see in variable assignment
    BW_vid = BitArray(undef, height, width, frame_num) # preallocates a boolean matrix of zeros, s.t. we then substitute ones where gray_frame > gray_median is true 
    fill!(BW_vid,false)
    #BW_vid = BitArray(BW_vid_bool);
    count = 1 # index for later storing frames, starts from one because we already read the first frame
    BW_vid[:,:,count] = color2BW(frame_1) # special treatment for frame_1 because we have already read it

    while !eof(reader) # it loops until the last frame has been read
        count += 1 # updates the count
        frame = VideoIO.read(reader)  # reads the movie
        BW_vid[:,:,count] = color2BW(frame) # assigns the binarized frame to the array
    end # while 
    close(reader) # closes the reader
    # bit_vid = BitArray(BW_vid) # converts the bool vid into a BitArray for optimization
    return BW_vid
end # EOF





