### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ dca45676-0482-4d43-956c-365f91120a6e
begin
## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/")
Pkg.activate("SIP")
end

# ╔═╡ b87e7088-8b5b-4e38-b325-ff63a6c2a8f3
begin
## imports useful packages
using Images
using VideoIO
using Statistics
using HDF5
using ImageView
using PlutoUI
end

# ╔═╡ 485f8408-93b0-4dcc-9514-76f08f2f705a
begin
## including functions
##
# for the preprocessing
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/video_conversion.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/color2BW.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/get_dimensions.jl")

# for coarse graining
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/get_new_dimensions.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/majority_rule.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/get_cutoff.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/glider_coarse_g.jl")

# for sampling
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/update_count.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/compute_steps_glider.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/glider.jl")
include("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/scripts/function get_nth_window.jl")
end

# ╔═╡ 5fd55fbc-54a1-482c-9da7-0205508db611
begin
## configuration variables assignment
# paths for preprocessing
data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_venice" # file name across different manipulations
file_path = "$data_dir/$file_name.mp4" # file path to the yt video
bin_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid" # directory where we store binarized videos
bin_file = "$bin_dir/$file_name.h5"
end

# ╔═╡ 7373b4b4-0b69-4945-89b9-bb551fe31641
bin_vid = video_conversion(file_path); # converts a target yt video into a binarized one

# ╔═╡ 39e3ab69-b2d3-4466-8e74-cb5882f4253a
data = Gray.(bin_vid);

# ╔═╡ c3b7dc8f-4ff2-4c69-a4a1-d8b5e7b8cf98
@bind slice_index Slider(1:size(data, 3), show_value=true, default=1)

# ╔═╡ d0f0b579-4455-4dc9-a305-0c32783f17d7
data[:, :, slice_index]

# ╔═╡ 4f6a1a43-7ceb-4aad-933a-d69fbdcb3b90
begin
# variable assignment for coarse graining
glider_coarse_g_dim = (3,3,1) # rows, cols, depth
volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid

cutoff = volume / 2 # sets the cutoff for the majority rule 
#coarse_g_path = "$bin_dir/$file_name_iteration_$iteration_num"
iteration_num = 1
coarse_g_path = "$(bin_dir)/$(file_name)_iteration_$iteration_num"
	
# variables for sampling
glider_dim = (2, 2, 1) # rows, cols, depth
end

# ╔═╡ 407c7e4e-a017-11ef-26b8-e7d8dff96192
begin
	local old_dim = size(bin_vid) # rows, cols, depth
	local prev_iteration = bin_vid
	tot_iterations = Dict{Int, Array{Bool, 3}}()
	tot_counts = Dict{Int, Dict{Vector{Bool}, Int}}()
	tot_sorted_counts = Vector{Vector{Pair{Vector{Bool}, Int}}}()
	
	for i = 1:5
		new_dim = get_new_dimensions(old_dim, glider_coarse_g_dim) # gets new dimensions of video for preallocation

		# coarse graining
		steps_coarse_g = compute_steps_glider(glider_coarse_g_dim, old_dim)
		new_iteration = zeros(Bool,new_dim) # preallocation
		new_iteration = glider_coarse_g(prev_iteration, new_iteration, steps_coarse_g, glider_coarse_g_dim, cutoff)
		tot_iterations[i] = new_iteration
	
		# sampling
		steps = compute_steps_glider(glider_dim, new_dim)
		counts = glider(new_iteration, glider_dim, steps)
		sorted_counts = sort(collect(counts), by=x -> x[2], rev=true) # sorts the counts 
		tot_counts[i] = counts 
		push!(tot_sorted_counts, sorted_counts)
		old_dim = new_dim
		prev_iteration = new_iteration
	end
end

# ╔═╡ b9b75657-f66c-430d-b893-15108e0cf562
md"### iteration slider"

# ╔═╡ 1b584e59-d0c1-46b1-a44d-7b1669ba1c78
@bind iteration_idx Slider(1:length(tot_iterations), show_value=true, default=1) 

# ╔═╡ c5e9ada8-9a66-4743-87ba-36a53e82d4f8
dat = Gray.(tot_iterations[iteration_idx]);

# ╔═╡ c4962149-640e-4a1f-aed6-6ed3411579aa
md"### frame slider"

# ╔═╡ a84d4d53-611d-47fe-919d-073c047495a2
@bind slice_idx Slider(1:size(dat, 3), show_value=true, default=1) 

# ╔═╡ d9dc9cf6-61e1-413f-a00a-dc0e87a3090d
dat[:, :, slice_idx]

# ╔═╡ a56080b3-4fc8-4ac6-a347-80dd24940695
md"### nth most frequent window"

# ╔═╡ a1113d85-da9e-4dda-a84f-686a21f7b172
@bind patch_index Slider(1:size(tot_sorted_counts[iteration_idx], 1), show_value=true, default=1)

# ╔═╡ 4421c859-d0cd-4acc-9a9a-0efe59c58b7b
window, count = get_nth_window(patch_index, tot_sorted_counts[iteration_idx], glider_dim)

# ╔═╡ 6dd95fb1-1d25-46c9-a6fc-deaf5a2ff4c5
window[:,:,1], count

# ╔═╡ Cell order:
# ╠═dca45676-0482-4d43-956c-365f91120a6e
# ╠═b87e7088-8b5b-4e38-b325-ff63a6c2a8f3
# ╠═485f8408-93b0-4dcc-9514-76f08f2f705a
# ╠═5fd55fbc-54a1-482c-9da7-0205508db611
# ╠═7373b4b4-0b69-4945-89b9-bb551fe31641
# ╠═39e3ab69-b2d3-4466-8e74-cb5882f4253a
# ╠═c3b7dc8f-4ff2-4c69-a4a1-d8b5e7b8cf98
# ╠═d0f0b579-4455-4dc9-a305-0c32783f17d7
# ╠═4f6a1a43-7ceb-4aad-933a-d69fbdcb3b90
# ╠═407c7e4e-a017-11ef-26b8-e7d8dff96192
# ╟─b9b75657-f66c-430d-b893-15108e0cf562
# ╠═1b584e59-d0c1-46b1-a44d-7b1669ba1c78
# ╠═c5e9ada8-9a66-4743-87ba-36a53e82d4f8
# ╟─c4962149-640e-4a1f-aed6-6ed3411579aa
# ╠═a84d4d53-611d-47fe-919d-073c047495a2
# ╠═d9dc9cf6-61e1-413f-a00a-dc0e87a3090d
# ╟─a56080b3-4fc8-4ac6-a347-80dd24940695
# ╠═a1113d85-da9e-4dda-a84f-686a21f7b172
# ╠═4421c859-d0cd-4acc-9a9a-0efe59c58b7b
# ╠═6dd95fb1-1d25-46c9-a6fc-deaf5a2ff4c5
