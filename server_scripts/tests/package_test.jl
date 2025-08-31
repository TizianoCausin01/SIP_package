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

# ╔═╡ dca45676-0482-4d43-956c-365f91120a6e
begin
## select correct virtual environment
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/")
Pkg.activate("SIP")
end

# ╔═╡ 485f8408-93b0-4dcc-9514-76f08f2f705a
begin
	Pkg.develop(path="/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_code/SIP_package/")
	using SIP_package
end

# ╔═╡ 68f3d10f-46cf-46ae-b63c-eecc989eaaf4
begin	
	using Images
	using VideoIO
	using Statistics
	using HDF5
	using ImageView
	using PlutoUI
	using Revise
end

# ╔═╡ 8005de68-1e0d-47c4-b28b-b4bc6a525cf8
using Plots

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
bin_vid = SIP_package.video_conversion(file_path); # converts a target yt video into a binarized one

# ╔═╡ 52063ab6-d66e-4d9a-ad59-9702a04bd7a5
size(bin_vid)

# ╔═╡ 39e3ab69-b2d3-4466-8e74-cb5882f4253a
data = Gray.(bin_vid); # converts the data into grayscale to be plotted

# ╔═╡ 98e62907-6178-4746-a7c0-053979777671
md"### original binarized video slider"

# ╔═╡ c3b7dc8f-4ff2-4c69-a4a1-d8b5e7b8cf98
@bind slice_index Slider(1:size(data, 3), show_value=true, default=1)

# ╔═╡ d0f0b579-4455-4dc9-a305-0c32783f17d7
data[:, :, slice_index]

# ╔═╡ 4f6a1a43-7ceb-4aad-933a-d69fbdcb3b90
begin
# variable assignment for coarse graining
glider_coarse_g_dim = (3,3,3) # rows, cols, depth
volume = glider_coarse_g_dim[1] * glider_coarse_g_dim[2] * glider_coarse_g_dim[3] #computes the volume of the solid

cutoff = volume / 2 # sets the cutoff for the majority rule 
#coarse_g_path = "$bin_dir/$file_name_iteration_$iteration_num"
	
# variables for sampling
glider_dim = (2, 2, 2) # rows, cols, depth
end

# ╔═╡ d7325609-7ab9-41bf-9c83-71399c49a23a
md"Iterative cycle in which the previous coarse-graining iteration is the base for the next one"

# ╔═╡ 407c7e4e-a017-11ef-26b8-e7d8dff96192
begin
	local old_dim = size(bin_vid) # rows, cols, depth # local so that I can use them inside the for loop
	local prev_iteration = bin_vid
	tot_iterations = Dict{Int, BitArray{3}}() # different coarse-graining iterations
	tot_counts = Dict{Int, Dict{BitVector, Int}}() # counts of patches
	tot_sorted_counts = Vector{Vector{Pair{BitVector, Int}}}() # sorted count of patches
	
	for i = 1:5
		new_dim = get_new_dimensions(old_dim, glider_coarse_g_dim) # gets new dimensions of video for preallocation

		# coarse graining
		steps_coarse_g = compute_steps_glider(glider_coarse_g_dim, old_dim) # creates a tuple with the steps the coarse-graining glider will have to do
		new_iteration = BitArray(undef,new_dim) # preallocation of current iteration array
		fill!(new_iteration,false)
		new_iteration = glider_coarse_g(prev_iteration, new_iteration, steps_coarse_g, glider_coarse_g_dim, cutoff) # computation of new iteration array
		tot_iterations[i] = new_iteration # storing it into the dict with all iterations
	
		# sampling
		#steps = compute_steps_glider(glider_dim, new_dim) # computing the steps for the sampling glider 
		counts = glider(new_iteration, glider_dim) # hoovers over the current iteration video and counts the instances of the pixels configurations
		sorted_counts = sort(collect(counts), by=x -> x[2], rev=true) # sorts the counts 
		tot_counts[i] = counts # stores the current counts into the total ones
		push!(tot_sorted_counts, sorted_counts) # stores the current sorted counts into the total ones (as a vector this time)
		old_dim = new_dim # updates the video dimensions for the next iteration
		prev_iteration = new_iteration # updates the video for the next iteration
	end
end

# ╔═╡ b591a3e2-830d-4d71-95f2-090090fe3135
#just to save it
begin
using JSON
open("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/counts_test.json", "w") do file
    JSON.print(file, tot_counts[1])
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

# ╔═╡ 5b543ce9-fdf5-41c5-8da3-16ad06ce560b
@bind time_idx Slider(1:size(window,3))

# ╔═╡ 6dd95fb1-1d25-46c9-a6fc-deaf5a2ff4c5
window[:,:,time_idx], count

# ╔═╡ 340bcbb1-dc45-4d87-a260-7a28134683d2
md"### Local maxima computation"

# ╔═╡ 91a20253-4b5a-4959-8ed8-e583fa332c79
begin
myDict = copy(tot_counts[iteration_idx])
loc_max = get_loc_max(myDict, 70)
end

# ╔═╡ 69831433-9a08-4174-93b8-44c17bc1e394
@bind max_idx_t Slider(1:size(loc_max,1), show_value=true, default=1)

# ╔═╡ 15533d41-7a8c-43e5-920a-f1adc07c1d6a
@bind time_idx_max_t Slider(1:size(window,3), show_value=true, default=1)

# ╔═╡ deae04e2-ffd9-4973-a9ff-c4e026ec7d62
begin
win_max_t = reshape(loc_max[max_idx_t], glider_dim) 
Gray.(win_max_t[:,:,time_idx_max_t])
end

# ╔═╡ 71e8c658-5880-4c24-a005-1e77ef00f5bd
begin
array_of_patches = Vector{Array{ColorTypes.Gray{Bool},3}}(undef, size(loc_max))
counter = 0
	for el in loc_max
	    counter +=1
		patch = Gray.(reshape(el, glider_dim))
	    array_of_patches[counter] = patch
end
end

# ╔═╡ 9bc31d42-40c8-4bc5-8dd1-6cb5b3d30387
begin
	theme(:default)
    default(background_color=:lightgray) 
	@gif for aaa in 1 : glider_dim[3]
    global plot_list = [plot(
                heatmap(el[:, :, aaa], color=:grays, axis=false),  # Base heatmap
            ) for el in array_of_patches]  # Enumerate for titles
    plot(plot_list...)  # Adjust layout as needed
	end every 1 fps=2
end

# ╔═╡ e86331d9-f5c1-4e12-be81-20b3c0494f88
typeof(plot_list)

# ╔═╡ Cell order:
# ╠═dca45676-0482-4d43-956c-365f91120a6e
# ╠═485f8408-93b0-4dcc-9514-76f08f2f705a
# ╠═68f3d10f-46cf-46ae-b63c-eecc989eaaf4
# ╠═5fd55fbc-54a1-482c-9da7-0205508db611
# ╠═7373b4b4-0b69-4945-89b9-bb551fe31641
# ╠═52063ab6-d66e-4d9a-ad59-9702a04bd7a5
# ╠═39e3ab69-b2d3-4466-8e74-cb5882f4253a
# ╟─98e62907-6178-4746-a7c0-053979777671
# ╟─c3b7dc8f-4ff2-4c69-a4a1-d8b5e7b8cf98
# ╠═d0f0b579-4455-4dc9-a305-0c32783f17d7
# ╠═4f6a1a43-7ceb-4aad-933a-d69fbdcb3b90
# ╟─d7325609-7ab9-41bf-9c83-71399c49a23a
# ╠═407c7e4e-a017-11ef-26b8-e7d8dff96192
# ╟─b9b75657-f66c-430d-b893-15108e0cf562
# ╟─1b584e59-d0c1-46b1-a44d-7b1669ba1c78
# ╠═c5e9ada8-9a66-4743-87ba-36a53e82d4f8
# ╠═b591a3e2-830d-4d71-95f2-090090fe3135
# ╟─c4962149-640e-4a1f-aed6-6ed3411579aa
# ╠═a84d4d53-611d-47fe-919d-073c047495a2
# ╠═d9dc9cf6-61e1-413f-a00a-dc0e87a3090d
# ╟─a56080b3-4fc8-4ac6-a347-80dd24940695
# ╠═a1113d85-da9e-4dda-a84f-686a21f7b172
# ╠═4421c859-d0cd-4acc-9a9a-0efe59c58b7b
# ╠═5b543ce9-fdf5-41c5-8da3-16ad06ce560b
# ╠═6dd95fb1-1d25-46c9-a6fc-deaf5a2ff4c5
# ╟─340bcbb1-dc45-4d87-a260-7a28134683d2
# ╠═91a20253-4b5a-4959-8ed8-e583fa332c79
# ╠═69831433-9a08-4174-93b8-44c17bc1e394
# ╠═15533d41-7a8c-43e5-920a-f1adc07c1d6a
# ╠═deae04e2-ffd9-4973-a9ff-c4e026ec7d62
# ╠═8005de68-1e0d-47c4-b28b-b4bc6a525cf8
# ╠═71e8c658-5880-4c24-a005-1e77ef00f5bd
# ╠═9bc31d42-40c8-4bc5-8dd1-6cb5b3d30387
# ╠═e86331d9-f5c1-4e12-be81-20b3c0494f88
