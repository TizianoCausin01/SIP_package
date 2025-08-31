using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
using DelimitedFiles
using Plots
using LinearAlgebra
using Statistics
##
results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results"
file_names = ["oregon", "bryce_canyon", "snow_walk", "idaho", "cenote_caves", "hawaii", "emerald_lake"]
cg_dims = (3, 3, 5)
win_dims = (3, 3, 3)
##
# fn = file_names[1] 


cg3s = [3, 5, 7, 9]
all_means = zeros(3, length(cg3s))
all_std = zeros(3, length(cg3s))
all_counter = 0
for cg3 in cg3s
	all_counter += 1
	diags = zeros(3, 7)
	counter = 0
	for fn in file_names
		counter += 1
		file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg3)_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(fn).csv"
		jsd_mat = readdlm(file_path, ',')
		jsd_mat = jsd_mat[1:4, 1:4]
		diags[1, counter] = mean(diag(jsd_mat, -1))
		diags[2, counter] = mean(diag(jsd_mat, -2))
		diags[3, counter] = mean(diag(jsd_mat, -3))
	end
	avg_diags = mean(diags, dims = 2)
	std_diags = std(diags, dims = 2)
	all_means[:, all_counter] = avg_diags
	all_std[:, all_counter] = std_diags
end
##
plot(cg3s, all_means[:, 1], yerror = all_std[:, 1], seriestype = :scatter, label = "cg3=$(cg3s[1])")
plot!(cg3s, all_means[:, 2], yerror = all_std[:, 2], seriestype = :scatter, label = "cg3=$(cg3s[2])")
plot!(cg3s, all_means[:, 3], yerror = all_std[:, 3], seriestype = :scatter, label = "cg3=$(cg3s[3])")
plot!(cg3s, all_means[:, 4], yerror = all_std[:, 4], seriestype = :scatter, label = "cg3=$(cg3s[4])")
##

##
print(mean(diag(div_mat, -1)))

##
fn = file_names[2]
file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(fn).csv"


##
default(background_color = :white)
#div_mat_path = "$(counts_path)/jsd_$(file_name).csv"
div_mat = readdlm(file_path, ',')
my_purple_gradient = cgrad([
	RGB(0.2, 0.0, 0.3),  # deep purple
	RGB(0.5, 0.1, 0.6),  # violet
	RGB(0.9, 0.9, 0.7),   # soft lilac
])
my_red_gradient = cgrad([
	RGB(0.3, 0.0, 0.0),  # dark red / maroon
	RGB(0.8, 0.2, 0.2),  # strong red
	RGB(1.0, 0.9, 0.8),   # soft peach / pale red
])
my_yellow_red_gradient = reverse(cgrad([
		RGB(0.9, 1.0, 0.0),  # bright yellow
		RGB(0.9, 0.1, 0.0),  # orange-red
		RGB(1, 0.0, 0.0),   # dark red / maroon
	], [0.0, 0.2, 0.6, 1.0]))  # control the position of colors
hm = heatmap(
	div_mat,
	color = reverse(my_yellow_red_gradient),
	clim = (0 - 0.01, maximum(div_mat) + 0.3),
	yflip = true,
	title = "$(fn) cg $(cg_dims[1]) $(cg_dims[2]) $(cg_dims[3]), win $(win_dims[1]) $(win_dims[2]) $(win_dims[3])",
	legend = false,
	ytick = (1:5, 0:4),
	xticks = (1:5, 0:4),
	background_color = :white,
)
for i in 1:size(div_mat, 1), j in 1:size(div_mat, 2)
	annotate!(j, i, text(round(div_mat[i, j]; digits = 3), 8, :black))
end
hm


