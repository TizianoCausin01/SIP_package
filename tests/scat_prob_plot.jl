using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")

using SIP_package
using Plots
using LaTeXStrings
using Combinatorics
##
results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results"
file_name = "oregon"
cg_dims = (3, 3, 3)
win_dims = (3, 3, 2)
iterations_num = 5
combs = combinations(1:5, 2)
fns = ["oregon", "snow_walk", "cenote_caves"]
for file_name in fns
	for iters in combs
		counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
		path2figs = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/figures_SIP"
		first_iter = iters[1]
		second_iter = iters[2]

		dict1 = json2dict("$(counts_path)/counts_$(file_name)_iter$(first_iter).json")
		dict2 = json2dict("$(counts_path)/counts_$(file_name)_iter$(second_iter).json")
		prob_dict1 = counts2prob(dict1, 15)
		prob_dict2 = counts2prob(dict2, 15)
		pts = nothing
		eps = 0
		keys1 = collect(keys(prob_dict1))
		keys2 = collect(keys(prob_dict2))
		tot_keys = keys1 ∪ keys2
		for key in tot_keys
			curr_vals = [get(prob_dict1, key, eps), get(prob_dict2, key, eps)]'
			if pts === nothing
				pts = curr_vals
			else
				pts = vcat(pts, curr_vals)
			end # if pts === nothing
		end # for key in keys(prob_dict1)

		x = log10.(pts[:, 1])
		y = log10.(pts[:, 2])
		lim_min = minimum(filter(isfinite, hcat(x, y)))
		lim_max = maximum(hcat(x, y))
		# histogram2d(x, y,
		# 	bins = 200,
		# 	color = :viridis,
		# 	fillalpha = 0.80,
		# 	background_color_inside = :white,  # This sets the color for empty bins
		# 	xlabel = "log10(x)",
		# 	ylabel = "log10(y)",
		# 	clim = (0, 200))
		# plot!([lim_min, lim_max], [lim_min, lim_max], xlabel = L"P_{n-1}", ylabel = L"P_n", color = :red, linestyle = :dash, legend = false)
		x_iter = first_iter
		y_iter = second_iter
		plot_label = "$(file_name)_$(x_iter)vs$(y_iter)iter_winsize_$(win_dims)_cg_$(cg_dims)"
		plot([lim_min, lim_max], [lim_min, lim_max], linewidth = 1, color = :red, linestyle = :dash, legend = false, title = plot_label)
		scatter!(x, y, markersize = 1, alpha = 0.015, markerstrokewidth = 0, markerstrokecolor = :transparent, color = :blue, grid = false)
		savefig("$(path2figs)/$(plot_label).png")
	end # for iters in combs
end # for file_name in fns
