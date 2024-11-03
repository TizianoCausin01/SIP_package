function get_dimensions(reader)
    """reads the first frame of the frame of the movie and gets the dimensions of the movie"""
    frame_num = VideoIO.counttotalframes(reader) # total number of frames
    frame_1 = VideoIO.read(reader) # stores the first frame to get the height and width
    height, width = size(frame_1) 
    return frame_1, height, width, frame_num 
end # EOF