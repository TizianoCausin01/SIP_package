function get_cutoff(glider_coarse_g_dim)
"""Gets the dimensions of the glider for coarse graining
   and returns a cutoff value for the decision rule
   Inputs : 
   - glider_coarse_g_dim -> tuple with the dimensions of the glider for coarse graining """
    
    volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
    cutoff = volume / 2 # sets the cutoff for the majority rule 
    return get_cutoff
end # EOF
