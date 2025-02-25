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
end

# ╔═╡ aa232ab8-4b24-45a7-89f0-7e07c6219c45
begin
    results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results"
	file_name = "short"
	cg_dims = (3,3,3)
	win_dims = (2,2,2)
	iterations_num = 5
end

# ╔═╡ fb35c107-89f6-4567-9df6-cb8a6d9e75e5
begin
counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
	
loc_max_path = "$(counts_path)/loc_max_$(file_name)"
end

# ╔═╡ 3ea45e23-3379-44af-9d9a-337dd76df947
md"## iteration number"

# ╔═╡ b0e9b208-0f99-458a-8462-44ad580c6d7a
@bind iter_idx Slider(1:iterations_num, show_value=true, default=1) 

# ╔═╡ bf8ca8bf-4b66-4e16-a50d-598f54c7f5f6
begin
loc_max_iter_path = "$(loc_max_path)/loc_max_$(file_name)_iter$(iter_idx).json"
loc_max_dict = json2dict(loc_max_iter_path)
	loc_max_list = []
	for key in keys(loc_max_dict)
		target_win = reshape(key, win_dims)
		push!(loc_max_list, Gray.(target_win))
	end # for key in keys(loc_max_dict)
end

# ╔═╡ 930fdd0b-aa1c-45fc-a7cf-938bc452fd43
begin
	theme(:default)
    default(background_color=:lightgray) 
	@gif for frame_idx in 1 : win_dims[3]
            global plot_list = [plot(
            heatmap(el[:, :, frame_idx], color=:grays, axis=false),  # Base heatmap
            ) for el in loc_max_list]  # Enumerate for titles
            plot(plot_list...)  # Adjust layout as needed
	end every 1 fps=1
end

# ╔═╡ d7228c76-3653-477e-9f5f-78daeed3faf8
begin
	extension_surr = 2
	surr_dims = win_dims .+ extension_surr*2
    surr_path = "$(counts_path)/template_matching_$(file_name)/template_matching_ext_$(extension_surr)_$(file_name).json"
	surr_dict = load_dict_surroundings(surr_path, surr_dims)
	surr_list = []
	for key in keys(surr_dict)
		surr_patch = Gray.(surr_dict[key][1]./surr_dict[key][2])
		push!(surr_list, surr_patch)
	end # for key in keys(loc_max_dict)
end

# ╔═╡ 9aa557c0-6ca8-43e8-9dc6-bfca1add7fed
begin
	theme(:default)
    default(background_color=:lightgray) 
	@gif for frame_idx in 1 : surr_dims[3]
            global plot_surr_list = [plot(
            heatmap(el[:, :, frame_idx], color=:grays, axis=false),  # Base heatmap
            ) for el in surr_list]  # Enumerate for titles
            plot(plot_surr_list...)  # Adjust layout as needed
	end every 1 fps=2
end

# ╔═╡ Cell order:
# ╠═a01b91a6-f395-11ef-3f4e-d13822cb03c3
# ╠═b055baa2-336a-465e-8599-af42ace47998
# ╠═aa232ab8-4b24-45a7-89f0-7e07c6219c45
# ╠═fb35c107-89f6-4567-9df6-cb8a6d9e75e5
# ╟─3ea45e23-3379-44af-9d9a-337dd76df947
# ╠═b0e9b208-0f99-458a-8462-44ad580c6d7a
# ╠═bf8ca8bf-4b66-4e16-a50d-598f54c7f5f6
# ╠═930fdd0b-aa1c-45fc-a7cf-938bc452fd43
# ╠═d7228c76-3653-477e-9f5f-78daeed3faf8
# ╠═9aa557c0-6ca8-43e8-9dc6-bfca1add7fed
