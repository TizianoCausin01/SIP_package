### A Pluto.jl notebook ###
# v0.20.6

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ a01b91a6-f395-11ef-3f4e-d13822cb03c3
begin
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
end

# ╔═╡ b055baa2-336a-465e-8599-af42ace47998
begin
    using SIP_package
	using JSON
	using PlutoUI
	using Plots
	using DelimitedFiles
end

# ╔═╡ aa232ab8-4b24-45a7-89f0-7e07c6219c45
begin
    results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results"
	img_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/figures_SIP"
	file_name = "oregon"
	cg_dims = (3,3,1)
	win_dims = (3,3,1)
	iterations_num = 5
end

# ╔═╡ fb35c107-89f6-4567-9df6-cb8a6d9e75e5
begin
counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
	
loc_max_path = "$(counts_path)/loc_max_$(file_name)"
end
	
	

# ╔═╡ e4cf5473-5fec-4bdb-8bc1-fd1953615965
function int2win(key, win_dims)
	str_key = bitstring(key)
	tot_bits = prod(win_dims)
	str_key = str_key[end-tot_bits+1:end]
	bit_vec_key = BitVector(c == '1' for c in str_key)
	win = reshape(bit_vec_key, win_dims)
	return win
end # EOF

# ╔═╡ 01cd98b5-8b79-417c-9cb5-bb500b590f03
begin
	ham_dist = 1
	percentile = 100
	loc_max_ham_path =  "$(counts_path)/loc_max_ham_$(ham_dist)_$(file_name)_$(percentile)percent"
end

# ╔═╡ 3ea45e23-3379-44af-9d9a-337dd76df947
md"## iteration number"

# ╔═╡ b0e9b208-0f99-458a-8462-44ad580c6d7a
@bind iter_idx Slider(1:iterations_num, show_value=true, default=1) 

# ╔═╡ e38daff8-18ee-42f3-950b-edb3614366e2
md"## print top loc max"

# ╔═╡ d1bd8aab-9f32-4523-8bd3-e2e27e692b8b
md"## start at"

# ╔═╡ f40ff0a6-a84c-4728-891b-070ee1daa872
# ╠═╡ disabled = true
#=╠═╡
begin
counts_dict_path = "$(counts_path)/counts_$(file_name)_iter4.json"
d = json2intdict(counts_dict_path)
end
  ╠═╡ =#

# ╔═╡ 46d1f143-55a2-4d67-ac4e-25a0c9dbfa7e
#=╠═╡
begin
key_list = []
	sorted_keys = sort(collect(d), by = x -> x[2], rev = true)
    for (key, _) in sorted_keys[start_at:start_at+top_n-1]
		target_win = int2win(key, win_dims)
		print(target_win)
		push!(key_list, Gray.(target_win))
	end # for key in keys(loc_max_dict)
end

  ╠═╡ =#

# ╔═╡ 103d4d30-4cc1-4efa-8e43-b9f3fd59c1ca
function isstatic(win)
	if all(win[:,:,1]==win[:,:,2]) & all(win[:,:,1]==win[:,:,3])
		return true
	else
		return false
	end

end #EOF

# ╔═╡ 16ccffee-bcf4-404b-8aee-8a2b4eb88df5
#=╠═╡
print(typeof(sorted_keys[1].second))
  ╠═╡ =#

# ╔═╡ c83adfee-f82e-42ff-9665-a2306d2adb41
# ╠═╡ disabled = true
#=╠═╡
begin
count_s=0
count =0
for key in keys(loc_max_dict)
	if isstatic(int2win(key, (3,3,3)))
		count_s +=1
	end
	count += 1

end	# for key in keys(d)
	print(count_s/count)
end
  ╠═╡ =#

# ╔═╡ 344381e8-b921-40a7-a8af-a362bb6024fb
# ╠═╡ disabled = true
#=╠═╡
begin
	theme(:default)
    default(background_color=:lightgray) 
	animk = @animate for frame_idx in 1 : win_dims[3]
            global plot_listk = [plot(
            heatmap(el[:, :, frame_idx], color=:grays, axis=false, grid=false),  # Base heatmap
            ) for el in key_list]  # Enumerate for titles
		title_plot = plot(title="Overall Title", grid=false, showaxis=false, framestyle=:none)
            plot(plot_list...)  # Adjust layout as needed
	end every 1 
	gif(animk, "$(img_path)/loc_max_$(file_name)_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])_iter$(iter_idx).gif", fps = 1)
	
end
  ╠═╡ =#

# ╔═╡ bf8ca8bf-4b66-4e16-a50d-598f54c7f5f6
begin
    loc_max_iter_path = "$(loc_max_path)/loc_max_$(file_name)_iter$(iter_idx).json"
    loc_max_dict = json2intdict(loc_max_iter_path)
	sorted_loc_max = sort(collect(loc_max_dict), by = x -> x[2], rev = true)
end

# ╔═╡ bb90abdf-0ee8-42b4-b21b-d2c05b5df47e


# ╔═╡ dbb9eb85-f94a-4d4a-856d-8c2231acf0f5
begin
loc_max_list = []
    for (key, _) in sorted_loc_max[start_at:start_at+top_n-1]
		target_win = int2win(key, win_dims)
		push!(loc_max_list, Gray.(target_win))
	end # for key in keys(loc_max_dict)
end

# ╔═╡ c977519c-504a-4e39-8a8d-3879f03b88b0
md"## loc max hamming distance 1"

# ╔═╡ 930fdd0b-aa1c-45fc-a7cf-938bc452fd43
begin
	theme(:default)
    default(background_color=:lightgray) 
	anim = @animate for frame_idx in 1 : win_dims[3]
            global plot_list = [plot(
            heatmap(el[:, :, frame_idx], color=:grays, axis=false, grid=false),  # Base heatmap
            ) for el in loc_max_list]  # Enumerate for titles
		title_plot = plot(title="Overall Title", grid=false, showaxis=false, framestyle=:none)
            plot(plot_list...)  # Adjust layout as needed
	end every 1 
	gif(anim, "$(img_path)/loc_max_$(file_name)_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])_iter$(iter_idx).gif", fps = 1)
	
end

# ╔═╡ ac929d60-741d-4611-9535-873bf12c4b68
function lload_intdict_surroundings(path2dict::String, surr_dims::Tuple{Integer, Integer, Integer})
	str_dict = JSON.parsefile(path2dict)
	# loops through the key=>value pairs, parses the keys, assigns the values to the tuples
	print(size(str_dict["0"][1][1][1][1]))
	
	dict_surr = Dict(parse(Int, k) => (UInt.(reshape(v[1], surr_dims)), v[2]) for (k, v) in str_dict)
	return dict_surr
end #EOF

# ╔═╡ d7228c76-3653-477e-9f5f-78daeed3faf8
begin
	extension_surr = 2
	surr_dims = win_dims .+ extension_surr*2
    surr_path = "$(counts_path)/template_matching_$(file_name)/template_matching_ext_$(extension_surr)_$(file_name)_iter1.json"
	surr_dict = lload_intdict_surroundings(surr_path, surr_dims)
	surr_list = []
	# loads iteration one for which we did the template matching
	loc_max_iter1_path = "$(loc_max_path)/loc_max_$(file_name)_iter1.json"
	loc_max_dict_iter1 = json2intdict(loc_max_iter1_path)
	sorted_loc_max_iter1 = sort(collect(loc_max_dict_iter1), by = x -> x[2], rev = true)
	for (key, _) in sorted_loc_max_iter1[start_at:start_at+top_n-1]
		surr_patch = Gray.(surr_dict[key][1]./surr_dict[key][2])
		push!(surr_list, surr_patch)
	end # for key in keys(loc_max_dict)
end

# ╔═╡ 9aa557c0-6ca8-43e8-9dc6-bfca1add7fed
begin
	theme(:default)
    default(background_color=:lightgray) 
	anim_tm = @animate for frame_idx in 1 : surr_dims[3]
            global plot_surr_list = [plot(
            heatmap(el[:, :, frame_idx], color=:grays, axis=false, grid=false),  # Base heatmap
            ) for el in surr_list]  # Enumerate for titles
            plot(plot_surr_list...)  # Adjust layout as needed
	end every 1 fps=2
	gif(anim_tm, "$(img_path)/tm_$(file_name)_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3]).gif", fps = 2)
end

# ╔═╡ 55292a20-d785-4dc4-800b-0a4260e38ffe
md"## loc max hamming distance 1"

# ╔═╡ 3df52c1e-cd9b-4077-92b5-32e38b02df43
begin
    loc_max_ham_iter_path = "$(loc_max_ham_path)/loc_max_ham_$(ham_dist)_$(file_name)_iter$(iter_idx).json"
    loc_max_ham_dict = json2intdict(loc_max_ham_iter_path)
	sorted_loc_max_ham = sort(collect(loc_max_ham_dict), by = x -> x[2], rev = true)
end

# ╔═╡ 5becffe0-7506-4ba0-98b5-48fd39e4b92d
loc_max_ham_iter_path

# ╔═╡ cbcd3b86-78c2-455c-9d9c-0b269f024b1b
@bind sstart_at Slider(1:length(sorted_loc_max_ham), show_value=true, default=1)

# ╔═╡ edc2f21b-ba35-419c-971e-1cb0a5a4feaf
begin
loc_max_ham_list = []
    for (win_h, _) in sorted_loc_max_ham[sstart_at:sstart_at+top_n-1]
		target_win_h = int2win(win_h, win_dims)
		push!(loc_max_ham_list, Gray.(target_win_h))
	end # for key in keys(loc_max_dict)
end


# ╔═╡ 49c62c28-c111-4f18-94b4-75a34290cc63
length(loc_max_ham_list)

# ╔═╡ 98111faa-f3e5-4659-a81e-304b906a651f
md"## loc max hamming distance = $ham_dist"

# ╔═╡ 0ceffe95-d4ec-4421-8f7d-ebedd6181477
begin
	theme(:default)
    default(background_color=:lightgray) 
	anim_h = @animate for frame_idx_h in 1 : win_dims[3]
            global plot_ham_list = [plot(
            heatmap(el_h[:, :, frame_idx_h], color=:grays, axis=false, grid=false),  # Base heatmap
            ) for el_h in loc_max_ham_list]  # Enumerate for titles
		title_plot = plot(title="Overall Title", grid=false, showaxis=false, framestyle=:none)
            plot(plot_ham_list...)  # Adjust layout as needed
	end every 1 
	gif(anim_h, "$(img_path)/loc_max_ham_$(ham_dist)_$(file_name)_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])_iter$(iter_idx).gif", fps = 1)
end

# ╔═╡ 0eabd6ab-2ea1-4835-9070-2abf3b298866
begin
	loc_max_ham_iter1_path = "$(loc_max_ham_path)/loc_max_ham_$(ham_dist)_$(file_name)_iter1.json"
loc_max_ham_dict_iter1 = json2intdict(loc_max_ham_iter1_path)
	sorted_loc_max_ham_iter1 = sort(collect(loc_max_ham_dict_iter1), by = x -> x[2], rev = true)
end

# ╔═╡ f4acde1b-25da-4d4e-ad83-4a70c5dbca39
begin
	surr_list_h=[]
for (key_h, _) in sorted_loc_max_ham_iter1[start_at:start_at+top_n-1]
		surr_patch_h = Gray.(surr_dict[key_h][1]./surr_dict[key_h][2])
		push!(surr_list_h, surr_patch_h)
	end # for key in keys(loc_max_dict)
end

# ╔═╡ b6f7e723-20aa-4c88-aea5-f11c7a49127c
begin
	theme(:default)
    default(background_color=:lightgray) 
	anim_tm_h = @animate for frame_idx in 1 : surr_dims[3]
            global plot_surr_list_h = [plot(
            heatmap(el[:, :, frame_idx], color=:grays, axis=false, grid=false),  # Base heatmap
            ) for el in surr_list_h]  # Enumerate for titles
            plot(plot_surr_list_h...)  # Adjust layout as needed
	end every 1 fps=2
	gif(anim_tm_h, "$(img_path)/tm_$(file_name)_ham_$(ham_dist)_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3]).gif", fps = 2)
end

# ╔═╡ ba2f06ad-6ca9-4822-8c85-f6c481d50708
md"## Shannon's entropy"

# ╔═╡ 8c84beb4-84ef-4664-8e88-2c58fb454842
begin
	sh_ent_path = "$(counts_path)/sh_entropy_$(file_name).csv"
    sh_ent = readdlm(sh_ent_path, ',')	
end

# ╔═╡ bba7aa34-15fd-484b-b070-6fa228e6218b
md"## Shannon-Jensen divergence"

# ╔═╡ db25ac09-9879-4a4b-9a9c-c4730215277e
begin
	default(background_color = :white)
	div_mat_path = "$(counts_path)/jsd_$(file_name).csv"
	div_mat = readdlm(div_mat_path, ',')
	my_purple_gradient = cgrad([
    RGB(0.2, 0.0, 0.3),  # deep purple
    RGB(0.5, 0.1, 0.6),  # violet
    RGB(.9, 0.9, 0.7)   # soft lilac
])
	my_red_gradient = cgrad([
    RGB(0.3, 0.0, 0.0),  # dark red / maroon
    RGB(0.8, 0.2, 0.2),  # strong red
    RGB(1.0, 0.9, 0.8)   # soft peach / pale red
])
my_yellow_red_gradient = reverse(cgrad([
    RGB(0.9, 1.0, 0.0),  # bright yellow
    RGB(.9, 0.1, 0.0),  # orange-red
    RGB(1, 0.0, 0.0)   # dark red / maroon
], [0.0, 0.2, 0.6, 1.0]))  # control the position of colors
	hm = heatmap(div_mat, color = reverse(my_yellow_red_gradient), clim = (0-.01, maximum(div_mat)+.3), yflip = true, title="$(file_name) cg $(cg_dims[1]) $(cg_dims[2]) $(cg_dims[3]), win $(win_dims[1]) $(win_dims[2]) $(win_dims[3])", legend=false, ytick=(1:5, 0:4), xticks=(1:5, 0:4), background_color=:white)
	for i in 1:size(div_mat, 1), j in 1:size(div_mat, 2)
		annotate!(j, i, text(round(div_mat[i, j]; digits = 3), 8, :black))
	end
	hm
	
end

# ╔═╡ 1876f661-39e3-4988-8651-5e168c3f4b69
savefig(hm, "$(img_path)/$(file_name)_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3]).svg")

# ╔═╡ 4cbc0676-e105-43a7-bc8d-0e1fa937978a
# ╠═╡ disabled = true
#=╠═╡
@bind start_at Slider(1:length(loc_max_dict)-top_n, show_value=true, default=1) 
  ╠═╡ =#

# ╔═╡ d462f6ca-cb07-499f-9d08-c03e962ad715
@bind start_at Slider(1:max(length(loc_max_dict)-top_n, 1), show_value=true, default=1) 

# ╔═╡ 7150ef72-c1db-4294-b87a-ab6e46888362
# ╠═╡ disabled = true
#=╠═╡
@bind top_n Slider(1:60, show_value=true, default=1) 
  ╠═╡ =#

# ╔═╡ f439e04e-14d9-49e2-bcae-75d7be06f01c
@bind top_n Slider(1:min(60, length(loc_max_dict)), show_value=true, default=1) 

# ╔═╡ Cell order:
# ╠═a01b91a6-f395-11ef-3f4e-d13822cb03c3
# ╠═b055baa2-336a-465e-8599-af42ace47998
# ╠═aa232ab8-4b24-45a7-89f0-7e07c6219c45
# ╠═fb35c107-89f6-4567-9df6-cb8a6d9e75e5
# ╠═e4cf5473-5fec-4bdb-8bc1-fd1953615965
# ╠═01cd98b5-8b79-417c-9cb5-bb500b590f03
# ╠═3ea45e23-3379-44af-9d9a-337dd76df947
# ╠═b0e9b208-0f99-458a-8462-44ad580c6d7a
# ╠═e38daff8-18ee-42f3-950b-edb3614366e2
# ╠═7150ef72-c1db-4294-b87a-ab6e46888362
# ╠═d1bd8aab-9f32-4523-8bd3-e2e27e692b8b
# ╠═4cbc0676-e105-43a7-bc8d-0e1fa937978a
# ╠═f40ff0a6-a84c-4728-891b-070ee1daa872
# ╠═46d1f143-55a2-4d67-ac4e-25a0c9dbfa7e
# ╠═103d4d30-4cc1-4efa-8e43-b9f3fd59c1ca
# ╠═16ccffee-bcf4-404b-8aee-8a2b4eb88df5
# ╠═c83adfee-f82e-42ff-9665-a2306d2adb41
# ╠═344381e8-b921-40a7-a8af-a362bb6024fb
# ╠═bf8ca8bf-4b66-4e16-a50d-598f54c7f5f6
# ╠═bb90abdf-0ee8-42b4-b21b-d2c05b5df47e
# ╠═f439e04e-14d9-49e2-bcae-75d7be06f01c
# ╠═d462f6ca-cb07-499f-9d08-c03e962ad715
# ╠═dbb9eb85-f94a-4d4a-856d-8c2231acf0f5
# ╟─c977519c-504a-4e39-8a8d-3879f03b88b0
# ╠═930fdd0b-aa1c-45fc-a7cf-938bc452fd43
# ╠═d7228c76-3653-477e-9f5f-78daeed3faf8
# ╠═ac929d60-741d-4611-9535-873bf12c4b68
# ╠═9aa557c0-6ca8-43e8-9dc6-bfca1add7fed
# ╟─55292a20-d785-4dc4-800b-0a4260e38ffe
# ╠═5becffe0-7506-4ba0-98b5-48fd39e4b92d
# ╠═3df52c1e-cd9b-4077-92b5-32e38b02df43
# ╠═cbcd3b86-78c2-455c-9d9c-0b269f024b1b
# ╠═edc2f21b-ba35-419c-971e-1cb0a5a4feaf
# ╠═49c62c28-c111-4f18-94b4-75a34290cc63
# ╟─98111faa-f3e5-4659-a81e-304b906a651f
# ╠═0ceffe95-d4ec-4421-8f7d-ebedd6181477
# ╠═0eabd6ab-2ea1-4835-9070-2abf3b298866
# ╠═f4acde1b-25da-4d4e-ad83-4a70c5dbca39
# ╠═b6f7e723-20aa-4c88-aea5-f11c7a49127c
# ╟─ba2f06ad-6ca9-4822-8c85-f6c481d50708
# ╠═8c84beb4-84ef-4664-8e88-2c58fb454842
# ╟─bba7aa34-15fd-484b-b070-6fa228e6218b
# ╠═db25ac09-9879-4a4b-9a9c-c4730215277e
# ╠═1876f661-39e3-4988-8651-5e168c3f4b69
