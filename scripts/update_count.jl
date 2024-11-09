function update_count(counts_dict, window)
    """updates the dictionary of counts such that if the window was already
    present, it adds 1 to the value (to count it), otherwise it creates it
    and initializes its value with a 1"""
    
    if haskey(counts_dict, window)
        counts_dict[window]+=1
    else
        counts_dict[window] = 1
    end # if has key
    
    return counts_dict
end #EOF