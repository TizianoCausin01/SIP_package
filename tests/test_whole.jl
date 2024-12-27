### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 834b8082-babc-11ef-17da-f11fa7ff6cf5
begin
## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
end

# ╔═╡ ff2a4d7d-8990-440a-9f17-0a0719566a8c
begin
	Pkg.develop(path="/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
	using SIP_package
end

# ╔═╡ 7a6d33b4-f16c-469c-a8e6-1985be0806a2
begin	
    using Images
	using VideoIO
	using Statistics
	using HDF5
	using ImageView
	using PlutoUI
	using Revise
end

# ╔═╡ d230fbe9-07ad-4e98-9fd4-c8c3c6735eea
begin
## configuration variables assignment
# paths for preprocessing
data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_venice" # file name across different manipulations
file_path = "$data_dir/$file_name.mp4" # file path to the yt video
bin_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid" # directory where we store binarized videos
bin_file = "$bin_dir/$file_name.h5"
end

# ╔═╡ 93b3ee1a-6b3c-4207-a46c-b608e33d1970
bin_vid = SIP_package.video_conversion(file_path); # converts a target yt video into a binarized one

# ╔═╡ bf4ef19a-5a08-4a53-a855-0c346679f489
begin
# variable assignment for coarse graining
glider_coarse_g_dim = (3,3,3) # rows, cols, depth
volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid

cutoff = volume / 2 # sets the cutoff for the majority rule 
#coarse_g_path = "$bin_dir/$file_name_iteration_$iteration_num"

# variables for sampling
glider_dim = (3, 3, 3) # rows, cols, depth
percentile = 30 # top nth part of the distribution taken into acocunt to compute loc_max	
end

# ╔═╡ aefdc637-6941-4000-8dac-8a1860e2f649
begin
    num_of_iterations = 5 # counting the 0th iteration
	counts_list = Vector{Dict{BitVector, Int}}(undef, num_of_iterations) # list of count_dicts of every iteration
	loc_max_list = Vector{Vector{BitVector}}(undef, num_of_iterations) # list of loc_max of every iteration
	coarse_g_iterations = Vector{BitArray}(undef, num_of_iterations) # list of all the videos at different levels of coarse graining
	coarse_g_iterations[1] = bin_vid # stores iteration 0
	for iter_idx = 1 : num_of_iterations
		# samples the current iteration
		if iter_idx != 1
		counts_list[iter_idx] = glider(coarse_g_iterations[iter_idx], glider_dim)
		loc_max_list[iter_idx] = get_loc_max(counts_list[iter_idx], percentile)
		end
		# coarse-graining of the current iteration
		if iter_idx < num_of_iterations
			old_dim = size(coarse_g_iterations[iter_idx])
			new_dim = get_new_dimensions(old_dim, glider_coarse_g_dim)
			# creates a 3D tuple of vectors with the steps the coarse-graining glider will have to do
			steps_coarse_g = compute_steps_glider(glider_coarse_g_dim, old_dim)
			coarse_g_iterations[iter_idx+1] = BitArray(undef,new_dim) # preallocation of current iteration array
			fill!(coarse_g_iterations[iter_idx+1], false)
			coarse_g_iterations[iter_idx+1] = glider_coarse_g( 
			coarse_g_iterations[iter_idx], 
			coarse_g_iterations[iter_idx+1], 
			steps_coarse_g, 
			glider_coarse_g_dim, 
			cutoff
			) # computation of new iteration array
		end # if 
	end # for
end

# ╔═╡ 0c60f4ad-272e-4e5c-b5b9-cb6e6502eca8
#@bind iter_disp_idx Slider(2:num_of_iterations, show_value=true, default=1)

# ╔═╡ 2b331757-95cf-42ee-babb-490d6c8df3df
#plot_loc_max(loc_max_list[iter_disp_idx], glider_dim, 2)

# ╔═╡ Cell order:
# ╠═834b8082-babc-11ef-17da-f11fa7ff6cf5
# ╠═ff2a4d7d-8990-440a-9f17-0a0719566a8c
# ╠═7a6d33b4-f16c-469c-a8e6-1985be0806a2
# ╠═d230fbe9-07ad-4e98-9fd4-c8c3c6735eea
# ╠═93b3ee1a-6b3c-4207-a46c-b608e33d1970
# ╠═bf4ef19a-5a08-4a53-a855-0c346679f489
# ╠═aefdc637-6941-4000-8dac-8a1860e2f649
# ╠═0c60f4ad-272e-4e5c-b5b9-cb6e6502eca8
# ╠═2b331757-95cf-42ee-babb-490d6c8df3df
