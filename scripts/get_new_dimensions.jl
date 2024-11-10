function get_new_dimensions(video_dim, coarse_g_dim)
    """Derives the new dimensions of the coarse grained video.
    Inputs :
    - video_dim -> the dimensions of the previous iteration 
    - coarse_g_dim -> the dimensions of the coarse graining to be done
    Outputs :
    - new_dim -> the new dimensions of the coarse grained video"""    
    new_dim = (                                     # floor s.t it won't overindex
        floor(Int, video_dim[1]/coarse_g_dim[1]),
        floor(Int, video_dim[2]/coarse_g_dim[2]),
        floor(Int, video_dim[3]/coarse_g_dim[3]),
    )
    return new_dim
end # EOF