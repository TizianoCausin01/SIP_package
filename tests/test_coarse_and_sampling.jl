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

# ╔═╡ 1580d9b3-a64d-4f8a-a5b3-65319721cebf
begin
## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/")
Pkg.activate("SIP")
end

# ╔═╡ 3fd06ecf-ad59-4acf-be8f-35fdf7faf866
begin
## imports useful packages
using Images
using VideoIO
using Statistics
using HDF5
using ImageView
using PlutoUI
end

# ╔═╡ d6c563ef-bcb6-4a9a-9253-97fbba802b98
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

# ╔═╡ b39a57dc-9f3d-11ef-0bf8-91ef37c5b7db

## sampling patches
# loads the file
bin_vid = h5read(bin_file, "test_nature"); #data = h5read("/tmp/test2.h5", "mygroup2/A", (2:3:15, 3:5))

# gets the dimensions of the file
video_dim = size(bin_vid) # rows, cols, depth
tot_steps = compute_steps_glider(glider_dim, video_dim) # creates a tuple with the steps the glider will have to do in each dimension. Each number in the list is the initial element in the new window. It subtracts the glider_dim such that we won't overindex

# creates the counts_dict and populates it with the glider
counts = glider(bin_vid, glider_dim, tot_steps)
sorted_counts = sort(collect(counts), by=x -> x[2], rev=true) # sorts the counts dictionary by values (by=x -> x[2]) in reverse order. To achieve this, it converts the dict in a Vector{Pair{Vector{Bool}, Int64}} in the first place 
## for visualization
window, count = get_nth_window(4, sorted_counts,glider_dim)
imshow(window)
##


# ╔═╡ e2a8fbed-974c-4f2e-908d-39c1e81f6725
begin
## configuration variables assignment
# paths for preprocessing
data_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_venice" # file name across different manipulations
file_path = "$data_dir/$file_name.mp4" # file path to the yt video
bin_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid" # directory where we store binarized videos
bin_file = "$bin_dir/$file_name.h5"
end


# ╔═╡ 23847716-51f6-4829-b794-54bb7f160876
begin
## video conversion and storing
bin_vid = video_conversion(file_p<ath) # converts a target yt video into a binarized one
#h5write(bin_file, file_name, bin_vid) # saves the video (complete_file_path, name_of_variable_when_retrieved, current variable name)
end

# ╔═╡ 12e70205-9819-4859-bc35-3bee1bc8a2a0
data = Gray.(bin_vid);

# ╔═╡ bef41a75-9646-4809-901e-fba78335ac71
@bind slice_index Slider(1:size(data, 3), show_value=true, default=1)

# ╔═╡ b5a95cb8-f460-41ee-bb9c-54d2665d974f
data[:, :, slice_index]

# ╔═╡ cef6d892-d192-4d5c-a4a0-c6c531fea8ee
begin
# variable assignment for coarse graining
video_dim = size(bin_vid) # rows, cols, depth
glider_coarse_g_dim = (3,3,1) # rows, cols, depth
new_dim = get_new_dimensions(video_dim, glider_coarse_g_dim)
volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid
tot_steps = compute_steps_glider(glider_coarse_g_dim, video_dim)
cutoff = volume / 2 # sets the cutoff for the majority rule 
#coarse_g_path = "$bin_dir/$file_name_iteration_$iteration_num"
iteration_num = 1
coarse_g_path = "$(bin_dir)/$(file_name)_iteration_$iteration_num"
	
# variables for sampling
glider_dim = (2, 2, 1) # rows, cols, depth
end

# ╔═╡ e7a9c217-8b82-49ee-8219-608f09833e4c
#=╠═╡
data_1 = Gray.(new_vid)
  ╠═╡ =#

# ╔═╡ f761ba32-8d9b-4991-9b2e-19fad7424294
#=╠═╡
@bind slice_index_1 Slider(1:size(data_1, 3), show_value=true, default=1)
  ╠═╡ =#

# ╔═╡ 544791d6-1796-4939-8dd4-b34e43d47ebc
#=╠═╡
data_1[:, :, slice_index_1]
  ╠═╡ =#

# ╔═╡ 9d5fb88e-d9ff-46f0-8d54-22a37ce60c43
#=╠═╡
begin
## sampling patches
# loads the file
#bin_vid = h5read(bin_file, "test_nature"); #data = h5read("/tmp/test2.h5", "mygroup2/A", (2:3:15, 3:5))

# gets the dimensions of the file
video_dim1 = size(new_vid) # rows, cols, depth
tot_steps1 = compute_steps_glider(glider_dim, video_dim1) # creates a tuple with the steps the glider will have to do in each dimension. Each number in the list is the initial element in the new window. It subtracts the glider_dim such that we won't overindex

# creates the counts_dict and populates it with the glider
counts = glider(new_vid, glider_dim, tot_steps1)
sorted_counts = sort(collect(counts), by=x -> x[2], rev=true) # sorts the counts dictionary by values (by=x -> x[2]) in reverse order. To achieve this, it converts the dict in a Vector{Pair{Vector{Bool}, Int64}} in the first place 
end
  ╠═╡ =#

# ╔═╡ 94fa5a2e-19dc-4009-8249-dcbbe0efcd62
#=╠═╡
@bind patch_index Slider(1:size(sorted_counts, 1), show_value=true, default=1)
  ╠═╡ =#

# ╔═╡ 15f86bb5-b9c4-4e65-9e4a-272fea330f72
#=╠═╡
## for visualization
window, count = get_nth_window(patch_index, sorted_counts, glider_dim)
  ╠═╡ =#

# ╔═╡ faf9cf4c-5d19-4e75-a03b-0e40ac001d66
#=╠═╡
md"rank patch : $(patch_index)"
  ╠═╡ =#

# ╔═╡ b3c6ef99-e054-4f4b-88e7-2931eee31009
#=╠═╡
Array(window[:,:,1])
  ╠═╡ =#

# ╔═╡ daf72327-d5fb-4511-b305-ba0093d9eb16

	

# ╔═╡ 1365b926-7e08-430a-abbe-dcc546a432f9
# ╠═╡ disabled = true
#=╠═╡
begin
for i = 1:5
	# coarse graining
	prev_iteration = new_iteration
	new_iteration = zeros(Bool,new_dim) # preallocation
	new_iteration = glider_coarse_g(bin_vid, new_vid, tot_steps, glider_coarse_g_dim, cutoff)
	tot_iterations[i] = new_iteration

	# sampling
	steps = compute_steps_glider(glider_dim, new_dim)
	counts = glider(new_vid, glider_dim, tot_steps1)
	sorted_counts = sort(collect(counts), by=x -> x[2], rev=true) # sorts the counts 
	tot_counts[i] = counts 
	tot_sorted_counts[i] = sorted_counts
end
end
  ╠═╡ =#

# ╔═╡ b8d2036d-21a0-45bc-af4b-e324fe290b45
#=╠═╡
begin
## coarse graining
new_vid = zeros(Bool,new_dim) # preallocation
new_vid = glider_coarse_g(bin_vid, new_vid, tot_steps, glider_coarse_g_dim, cutoff)
#h5write(coarse_g_path, "test_venice_$(iteration_num)", new_vid) # saves the video (complete_file_path, name_of_variable_when_retrieved, current variable name)
end
  ╠═╡ =#

# ╔═╡ 5ebf8a2b-30c5-47e3-8809-dba5b2ace12b
# ╠═╡ disabled = true
#=╠═╡
new_vid = h5read("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/bin_vid/test_venice_iteration_1", "test_venice_1")
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═b39a57dc-9f3d-11ef-0bf8-91ef37c5b7db
# ╠═1580d9b3-a64d-4f8a-a5b3-65319721cebf
# ╠═3fd06ecf-ad59-4acf-be8f-35fdf7faf866
# ╠═d6c563ef-bcb6-4a9a-9253-97fbba802b98
# ╠═e2a8fbed-974c-4f2e-908d-39c1e81f6725
# ╠═23847716-51f6-4829-b794-54bb7f160876
# ╠═12e70205-9819-4859-bc35-3bee1bc8a2a0
# ╠═bef41a75-9646-4809-901e-fba78335ac71
# ╠═b5a95cb8-f460-41ee-bb9c-54d2665d974f
# ╠═cef6d892-d192-4d5c-a4a0-c6c531fea8ee
# ╠═b8d2036d-21a0-45bc-af4b-e324fe290b45
# ╠═5ebf8a2b-30c5-47e3-8809-dba5b2ace12b
# ╠═e7a9c217-8b82-49ee-8219-608f09833e4c
# ╠═f761ba32-8d9b-4991-9b2e-19fad7424294
# ╠═544791d6-1796-4939-8dd4-b34e43d47ebc
# ╠═9d5fb88e-d9ff-46f0-8d54-22a37ce60c43
# ╟─94fa5a2e-19dc-4009-8249-dcbbe0efcd62
# ╠═15f86bb5-b9c4-4e65-9e4a-272fea330f72
# ╟─faf9cf4c-5d19-4e75-a03b-0e40ac001d66
# ╠═b3c6ef99-e054-4f4b-88e7-2931eee31009
# ╠═daf72327-d5fb-4511-b305-ba0093d9eb16
# ╠═1365b926-7e08-430a-abbe-dcc546a432f9
