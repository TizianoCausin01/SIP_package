using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
using SIP_package
using DelimitedFiles
using Plots
using LinearAlgebra
using Statistics
using HypothesisTests
##
results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results"
fig_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/figures_SIP/"
file_names = ["oregon", "bryce_canyon", "snow_walk", "idaho", "cenote_caves", "hawaii", "emerald_lake"]
##
function get_avg_jsd_val(results_path, file_names, cg_dims, win_dims)
	all_means_within = []
	for fn in file_names
		file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(fn).csv"
		jsd_mat = readdlm(file_path, ',')
		jsd_mat = jsd_mat[1:3, 1:3]
		mask = jsd_mat .== 0
		jsd_mat[mask] .= NaN
		push!(all_means_within, mean(filter(!isnan, jsd_mat)))
	end
	return mean(all_means_within), std(all_means_within) / sqrt(7)
end
##
avg_normal, std_normal = get_avg_mat(results_path, (3, 3, 3), (3, 3, 3));
p = plot_jsd_mat(avg_normal; std_mat = std_normal)
savefig(p, "$(fig_path)/jsd_cg_3x3x3_win_3x3x3.svg")
##
avg_normal, std_normal = get_avg_mat(results_path, (3, 3, 1), (3, 3, 3));
p = plot_jsd_mat(avg_normal; std_mat = std_normal)
savefig(p, "$(fig_path)/jsd_cg_3x3x1_win_3x3x3.svg")
##
avg_normal, std_normal = get_avg_mat(results_path, (1, 1, 3), (3, 3, 3));
p = plot_jsd_mat(avg_normal; std_mat = std_normal)
savefig(p, "$(fig_path)/jsd_cg_1x1x3_win_3x3x3.svg")
## win = 3 × 3 × 3 scrambling
avg_block, std_block = get_avg_mat(results_path, (3, 3, 3), (3, 3, 3), scrambling_condition = "block", scale = 10);
avg_local, std_local = get_avg_mat(results_path, (3, 3, 3), (3, 3, 3), scrambling_condition = "local", range = 10, stride = 3);
avg_normal, std_normal = get_avg_mat(results_path, (3, 3, 3), (3, 3, 3));
block_scramb_plot = plot_jsd_mat(avg_block; std_mat = std_block, title_text = "block", square_size = 600, fontsize = 3)
local_scramb_plot = plot_jsd_mat(avg_local; title_text = "local", square_size = 600, fontsize = 3)
normal_plot = plot_jsd_mat(avg_normal; title_text = "normal", square_size = 600, fontsize = 3)
plot(normal_plot, local_scramb_plot, block_scramb_plot, layout = (1, 3))
##
avg_sh_normal3, std_sh_normal3 = get_avg_sh_ent(results_path, (3, 3, 1), (3, 3, 1));
avg_sh_normal4, std_sh_normal4 = get_avg_sh_ent(results_path, (3, 3, 1), (4, 4, 1));
##
@info "3 $(avg_sh_normal3)"
@info "4 $(avg_sh_normal4)"
##
avg_sh_normal, std_sh_normal = get_avg_sh_ent(results_path, (3, 3, 3), (3, 3, 3));
avg_sh_local, std_sh_local = get_avg_sh_ent(results_path, (3, 3, 3), (3, 3, 3), scrambling_condition = "local", range = 10, stride = 3);
avg_sh_block, std_sh_block = get_avg_sh_ent(results_path, (3, 3, 3), (3, 3, 3), scrambling_condition = "block", scale = 10);
all_sh_ents = [avg_sh_normal, avg_sh_local, avg_sh_block]
all_std_sh_ents = [std_sh_normal, std_sh_local, std_sh_block]
conditions = ["normal", "local", "block"]
##
p = plot(; xlabel = "X", ylabel = "Y", title = "Shannon Entropies")
my_palette = reverse(cgrad([
	RGB(0.0, 0, 0.6),   # deep blue
	RGB(0.1, 0.3, 0.8),   # true blue
	RGB(0.3, 0.8, 1.0),    # light/cyan-blue
]))

for i in 1:length(all_sh_ents)
	plot!(all_sh_ents[i];
		ribbon = all_std_sh_ents[i],
		palette = my_palette,
		marker = :circle,
		markerstrokewidth = 0,
		linewidth = 4,
		label = "$(conditions[i])")  # optional label for legend
end
p
## win = 1 × 1 × 9 scrambling
range = 10
stride = 3
scale = 20
avg_jsd_normal, std_jsd_normal = get_avg_mat(results_path, (1, 1, 3), (1, 1, 9));
avg_jsd_local, std_jsd_local = get_avg_mat(results_path, (1, 1, 3), (1, 1, 9), scrambling_condition = "local", range = range, stride = stride);
avg_jsd_block, std_jsd_block = get_avg_mat(results_path, (1, 1, 3), (1, 1, 9), scrambling_condition = "block", scale = scale);
## plot jsd mat
normal_plot = plot_jsd_mat(avg_jsd_normal; title_text = "normal", square_size = 600, fontsize = 3)
local_scramb_plot = plot_jsd_mat(avg_jsd_local; title_text = "local", square_size = 600, fontsize = 3)
block_scramb_plot = plot_jsd_mat(avg_jsd_block; title_text = "block", square_size = 600, fontsize = 3)
plot(normal_plot, local_scramb_plot, block_scramb_plot, layout = (1, 3))
## SHANNON entropy scrambling
# GENERAL #GOT HERE, now add normal to all of them and move legends
range = 10
stride = 3
scale = 10
avg_sh_normal, std_sh_normal = get_avg_sh_ent(results_path, (1, 1, 3), (1, 1, 9));
avg_sh_local, std_sh_local = get_avg_sh_ent(results_path, (1, 1, 3), (1, 1, 9), scrambling_condition = "local", range = range, stride = stride);
avg_sh_block, std_sh_block = get_avg_sh_ent(results_path, (1, 1, 3), (1, 1, 9), scrambling_condition = "block", scale = scale);
all_sh_ents = [avg_sh_normal, avg_sh_local, avg_sh_block]
all_std_sh_ents = [std_sh_normal, std_sh_local, std_sh_block]
conditions = ["normal", "local", "block"]
p = plot(; title = "Shannon Entropies", size = (500, 334), tickfontsize = 12)

colors = [RGB(0.56, 0.0, 1.0), RGB(0.1, 0.3, 0.8), RGB(0.9, 0.2, 0.1)]
for i in 1:length(all_sh_ents)
	plot!(all_sh_ents[i];
		ylims = [3, 9],
		ribbon = all_std_sh_ents[i],
		#palette = my_palette,
		color = colors[i],
		marker = :circle,
		markerstrokewidth = 0,
		linewidth = 4,
		grid = false,
		label = "$(conditions[i])")  # optional label for legend
end
p
savefig(p, "$(fig_path)/sh_ent_scrambling_all_1x1x9.svg")
## BLOCK
scales = [20, 10, 2]
tot_avg_block = []
tot_std_block = []
for s in scales
	avg_sh_block, std_sh_block = get_avg_sh_ent(results_path, (1, 1, 3), (1, 1, 9), scrambling_condition = "block", scale = s)
	push!(tot_avg_block, avg_sh_block)
	push!(tot_std_block, std_sh_block)
end
p = plot(; title = "Shannon Entropies", legend = (0.85, 1), tickfontsize = 12)
my_red_palette = reverse(cgrad([
	RGB(0.9, 0.4, 0.1),   # dark red
	RGB(0.8, 0.2, 0.2),   # mid red
	RGB(1, 0.9, 0.2),    # light red
]))
red_colors = [RGB(1, 0.9, 0.2), RGB(0.9, 0.2, 0.1), RGB(0.9, 0.0, 0.3)]
plot!(avg_sh_normal;
	ylims = [3, 9],
	ribbon = std_sh_normal,
	color = RGB(0.56, 0.0, 1.0),
	marker = :circle,
	markerstrokewidth = 0,
	linewidth = 4,
	grid = false,
	label = "normal")
for i in 1:length(tot_avg_block)
	plot!(tot_avg_block[i];
		ylims = [3, 9],
		ribbon = tot_std_block[i],
		color = red_colors[i],
		marker = :circle,
		markerstrokewidth = 0,
		linewidth = 4,
		grid = false,
		label = "scale = $(scales[i])",
		size = (500, 334))  # optional label for legend
end
p
savefig(p, "$(fig_path)/sh_ent_scrambling_block_1x1x9.svg")
## LOCAL 
ranges = [3, 10, 40]
strides = [1, 3, 1]
tot_avg_loc = []
tot_std_loc = []
for i in 1:length(ranges)
	avg_sh_loc, std_sh_loc = get_avg_sh_ent(results_path, (1, 1, 3), (1, 1, 9), scrambling_condition = "local", range = ranges[i], stride = strides[i])
	push!(tot_avg_loc, avg_sh_loc)
	push!(tot_std_loc, std_sh_loc)
end
p = plot(; title = "Shannon Entropies", size = (500, 333), tickfontsize = 12)
plot!(avg_sh_normal;
	ylims = [3, 9],
	ribbon = std_sh_normal,
	color = RGB(0.56, 0.0, 1.0),
	marker = :circle,
	markerstrokewidth = 0,
	linewidth = 4,
	grid = false,
	label = "normal")
blue_colors = [RGB(0.3, 0.7, 1.0), RGB(0.1, 0.3, 0.8), RGB(0.1, 0, 0.6)]
for i in 1:length(tot_avg_loc)
	plot!(tot_avg_loc[i];
		ylims = [3, 9],
		ribbon = tot_std_loc[i],
		color = blue_colors[i],
		marker = :circle,
		markerstrokewidth = 0,
		linewidth = 4,
		grid = false,
		label = "range = $(ranges[i]) , stride = $(strides[i])",
		size = (500, 333))  # optional label for legend
end
p
savefig(p, "$(fig_path)/sh_ent_scrambling_local_1x1x9.svg")
##
cg_dims = (1, 1, 3)
win_dims = (1, 1, 25)
avg_jsd, std_err = get_avg_mat(results_path, cg_dims, win_dims);
p = plot_jsd_mat(avg_jsd; std_mat = std_err, fontsize = 8)
savefig(p, "$(fig_path)/jsd_mat_1x1x$(win_dims[3]).svg")
## SHANNON entropy scrambling
# GENERAL
range = 10
stride = 3
scale = 10
avg_sh_normal, std_sh_normal = get_avg_sh_ent(results_path, (3, 3, 3), (3, 3, 3));
avg_sh_local, std_sh_local = get_avg_sh_ent(results_path, (3, 3, 3), (3, 3, 3), scrambling_condition = "local", range = range, stride = stride);
avg_sh_block, std_sh_block = get_avg_sh_ent(results_path, (3, 3, 3), (3, 3, 3), scrambling_condition = "block", scale = scale);
all_sh_ents = [avg_sh_normal, avg_sh_local, avg_sh_block]
all_std_sh_ents = [std_sh_normal, std_sh_local, std_sh_block]
conditions = ["normal", "local", "block"]
p = plot(; title = "Shannon Entropies", size = (500, 333), tickfontsize = 12)

colors = [RGB(0.56, 0.0, 1.0), RGB(0.1, 0.3, 0.8), RGB(0.9, 0.2, 0.1)]
for i in 1:length(all_sh_ents)
	plot!(all_sh_ents[i];
		ylims = [3, 14],
		ribbon = all_std_sh_ents[i],
		#palette = my_palette,
		color = colors[i],
		marker = :circle,
		markerstrokewidth = 0,
		linewidth = 4,
		grid = false,
		label = "$(conditions[i])",
		size = (500, 333))  # optional label for legend
end
p
savefig(p, "$(fig_path)/sh_ent_scrambling_all_3x3x3.svg")
##
progression_avgs = []
progression_stds = []
progression_plots = []
cg3s = [1, 3, 5, 7, 9]
for i in 1:length(cg3s)
	print(cg3s[i])
	avg_normal, std_normal = get_avg_mat(results_path, (3, 3, cg3s[i]), (3, 3, 3))
	push!(progression_avgs, avg_normal)
	push!(progression_stds, std_normal)
	normal_plot = plot_jsd_mat(avg_normal; title_text = "normal $(cg3s[i])", square_size = 600, fontsize = 3)
	push!(progression_plots, normal_plot)
end
##
plot(progression_plots..., layout = (2, 3))
##
##
avg_repl, std_repl = get_avg_mat(results_path, (3, 3, 1), (4, 4, 1))
plot_jsd_mat(avg_repl; std_mat = std_repl)

## TO SEE HOW ON AVERAGE THE CG OVER SPACE IS STRONGER THAN TIME
cg_dims = (3, 3, 3)
win_dims = (3, 3, 3)
cg3s = [1, 3, 5, 7, 9]
all_means = zeros(3, length(cg3s))
all_std = zeros(3, length(cg3s))
all_counter = 0
all_means = []
all_stds = []
for cg3 in cg3s
	all_m_win, sem_win = get_avg_jsd_val(results_path, file_names, (cg_dims[1], cg_dims[2], cg3), win_dims)
	push!(all_stds, sem_win)
	push!(all_means, all_m_win)
end
p = plot(cg3s, all_means, linestyle = :solid, ribbon = all_stds, xticks = cg3s, marker = :circle, color = RGB(0.6, 0.3, 0.9), markerstrokewidth = 0, grid = false, markersize = 4, label = "time", size = (300, 200)) #xlabel = "cg step (pixels or frames)", ylabel = "average jsd",


all_counter = 0
all_means = []
all_stds = []
for cg3 in cg3s
	all_m_win, sem_win = get_avg_jsd_val(results_path, file_names, (cg3, cg3, cg_dims[3]), win_dims)
	push!(all_stds, sem_win)
	push!(all_means, all_m_win)
end
plot!(cg3s, all_means, ylims = [0, 0.2], ribbon = all_stds, xticks = cg3s, yticks = [0, 0.05, 0.1, 0.15, 0.2], marker = :circle, color = RGB(0.2, 0, 0.6), markerstrokewidth = 0, grid = false, markersize = 4, label = "space", size = (300, 200)) # xlabel = "cg step (pixels or frames)", ylabel = "average jsd",

##
savefig(p, "$(fig_path)/space_time_progression_3x3x3.svg")
## progression over time with only temporal window
win_dims = (1, 1, 9)
cg_dims = (1, 1, 3)
cg3s = [3, 5, 7, 9]
all_means = zeros(3, length(cg3s))
all_std = zeros(3, length(cg3s))
all_counter = 0
all_means = []
all_stds = []
for cg3 in cg3s
	all_counter += 1
	diags = zeros(3, 7)
	all_m_win, sem_win = get_avg_jsd_val(results_path, file_names, (cg_dims[1], cg_dims[2], cg3), win_dims)
	push!(all_stds, sem_win)
	push!(all_means, all_m_win)
end
p = plot(
	[1, 3, 5, 7, 9],
	pushfirst!(all_means, 0),
	ylims = [0, 0.2],
	yticks = [0, 0.05, 0.1, 0.15, 0.2],
	linestyle = :solid,
	ribbon = pushfirst!(all_stds, 0),
	xticks = [1, 3, 5, 7, 9],
	marker = :circle,
	color = RGB(0.6, 0.3, 0.9),
	markerstrokewidth = 0,
	grid = false,
	markersize = 4,
	label = "time",
	size = (300, 200),
) # xlabel = "cg step (frames)", ylabel = "average jsd",
##
savefig(p, "$(fig_path)/time_progression_1x1x9.svg")
## SHANNON ENTROPY TO SEE HOW ON AVERAGE THE CG OVER TIME IS WEAKER
win_dims = (3, 3, 3)
cg_dims = (3, 3, 3)
cg3s = [1, 3, 5, 7, 9]
all_counter = 0
all_means = []
all_stds = []
for cg3 in cg3s
	all_counter += 1
	diags = zeros(3, 7)
	counter = 0
	avg = 0
	counter_avg = 0
	all_means_within = []
	all_stds_within = []
	for fn in file_names
		counter += 1
		file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg3)_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/sh_ent_$(fn).csv"
		sh_ent_vec = readdlm(file_path, ',')
		mask = sh_ent_vec .== 0
		sh_ent_vec[mask] .= NaN
		push!(all_means_within, mean(filter(!isnan, sh_ent_vec)))
	end
	print(all_means_within)
	push!(all_stds, std(all_means_within) / sqrt(7))
	push!(all_means, mean(all_means_within))
	# avg_diags = mean(diags, dims = 2)
	# std_diags = std(diags, dims = 2)
	# all_means[:, all_counter] = avg_diags
	# all_std[:, all_counter] = std_diags
end
plot(cg3s, all_means, ribbon = all_stds, xticks = cg3s, marker = :circle, markerstrokewidth = 0, grid = false, markersize = 4, xlabel = "cg step (pixels)", ylabel = "average Shannon's entropy")


## SHANNON ENTROPY TO SEE HOW ON AVERAGE THE CG OVER TIME IS WEAKER
cg3s = [1, 3, 5, 7, 9]
all_counter = 0
all_means = []
all_stds = []
for cg3 in cg3s
	all_counter += 1
	diags = zeros(3, 7)
	counter = 0
	avg = 0
	counter_avg = 0
	all_means_within = []
	all_stds_within = []
	for fn in file_names
		counter += 1
		file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg3)_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/sh_ent_$(fn).csv"
		sh_ent_vec = readdlm(file_path, ',')
		mask = sh_ent_vec .== 0
		sh_ent_vec[mask] .= NaN
		push!(all_means_within, mean(filter(!isnan, sh_ent_vec)))
	end
	print(all_means_within)
	push!(all_stds, std(all_means_within))
	push!(all_means, mean(all_means_within))
	# avg_diags = mean(diags, dims = 2)
	# std_diags = std(diags, dims = 2)
	# all_means[:, all_counter] = avg_diags
	# all_std[:, all_counter] = std_diags
end
plot(cg3s, all_means, yerror = all_stds, seriestype = :scatter, markersize = 4, xlabel = "cg step (frames)", ylabel = "average sh entropy")

## SHANNON ENTROPY TO SEE HOW ON AVERAGE THE CG OVER SPACE
win_dims = (3, 3, 3)
cg_dims = (3, 3, 3)
cg3s = [1, 3, 5, 7, 9]
all_counter = 0
all_means = []
all_stds = []
for cg3 in cg3s
	all_counter += 1
	diags = zeros(3, 7)
	counter = 0
	avg = 0
	counter_avg = 0
	all_means_within = []
	all_stds_within = []
	for fn in file_names
		counter += 1
		file_path = "$(results_path)/$(fn)_counts_cg_$(cg3)x$(cg3)x3_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/sh_ent_$(fn).csv"
		sh_ent_vec = readdlm(file_path, ',')
		mask = sh_ent_vec .== 0
		sh_ent_vec[mask] .= NaN
		push!(all_means_within, mean(filter(!isnan, sh_ent_vec)))
	end
	print(all_means_within)
	push!(all_stds, std(all_means_within) / sqrt(7))
	push!(all_means, mean(all_means_within))
	# avg_diags = mean(diags, dims = 2)
	# std_diags = std(diags, dims = 2)
	# all_means[:, all_counter] = avg_diags
	# all_std[:, all_counter] = std_diags
end
plot(cg3s, all_means, ribbon = all_stds, xticks = cg3s, marker = :circle, markerstrokewidth = 0, grid = false, markersize = 4, xlabel = "cg step (pixels)", ylabel = "average Shannon's entropy")

## SHANNON ENTROPY TO SEE HOW ON AVERAGE THE CG OVER TIME IS WEAKER
cg3s = [3, 5, 7, 9]
all_counter = 0
all_means = []
all_stds = []
for cg3 in cg3s
	all_counter += 1
	diags = zeros(3, 7)
	counter = 0
	avg = 0
	counter_avg = 0
	all_means_within = []
	all_stds_within = []
	for fn in file_names
		counter += 1
		file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg3)_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/sh_ent_$(fn).csv"
		sh_ent_vec = readdlm(file_path, ',')
		mask = sh_ent_vec .== 0
		sh_ent_vec[mask] .= NaN
		push!(all_means_within, mean(filter(!isnan, sh_ent_vec)))
	end
	print(all_means_within)
	push!(all_stds, std(all_means_within))
	push!(all_means, mean(all_means_within))
	# avg_diags = mean(diags, dims = 2)
	# std_diags = std(diags, dims = 2)
	# all_means[:, all_counter] = avg_diags
	# all_std[:, all_counter] = std_diags
end
plot(cg3s, all_means, yerror = all_stds, seriestype = :scatter, markersize = 4, xlabel = "cg step (frames)", ylabel = "average sh entropy")

##
cg_dims = (3, 3, 3)
win_dims = (4, 4, 2)
file_names = ["oregon", "bryce_canyon", "snow_walk", "idaho", "cenote_caves", "hawaii", "emerald_lake"]
tot_jsds = Array{Float64}(undef, 5, 5, length(file_names))
tot_sh_ents = Array{Float64}(undef, 5, length(file_names))
counter = 0
avg = 0
counter_avg = 0
all_means_within = []
for fn in file_names
	counter += 1
	file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(fn).csv"
	@info "$file_path"
	jsd_mat = readdlm(file_path, ',')
	temp_array = []
	file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/sh_ent_$(fn).csv"
	sh_ent_vec = readdlm(file_path, ',')
	#mask = jsd_mat .== 0
	#jsd_mat[mask] .= NaN
	tot_jsds[:, :, counter] = jsd_mat
	tot_sh_ents[:, counter] = sh_ent_vec
	#push!(all_means_within, mean(filter(!isnan, jsd_mat)))
end
#push!(all_means, mean(all_means_within))
##

cg_dims = (3, 3, 1)
win_dims = (4, 4, 1)
avg3x3, std3x3 = get_avg_mat(results_path, cg_dims, win_dims)
cg_dims = (1, 1, 3)
win_dims = (1, 1, 16)
avg9, std9 = get_avg_mat(results_path, cg_dims, win_dims)
mask = tril(trues(size(avg3x3)), 1)
##
test = EqualVarianceTTest(avg3x3[mask], avg9[mask])
##
avg3x3[mask]
##
#mean(filter(!isnan, tot_jsds), dims=3)
avg_jsd_mat = dropdims(mean(tot_jsds, dims = 3), dims = 3)
std_jsd_mat = dropdims(std(tot_jsds, dims = 3), dims = 3)
avg_sh_ent = dropdims(mean(tot_sh_ents, dims = 2), dims = 2)
std_sh_ent = dropdims(std(tot_sh_ents, dims = 2), dims = 2)
##
print(avg_sh_ent)
h = plot_jsd_mat(avg_jsd_mat; std_mat = std_jsd_mat)
##
plot(avg_sh_ent, ribbon = std_sh_ent, marker = :circle, markerstrokewidth = 0)
##
savefig(h, "$(fig_path)/jsd_cg_$(cg_dims[1])_$(cg_dims[2])_$(cg_dims[3])_win_$(win_dims[1])_$(win_dims[2])_$(win_dims[3]).svg")
##
## TO SEE HOW ON AVERAGE THE CG OVER SPACE IS STRONGER THAN TIME
cg_dims = [(3, 3, 3), (3, 3, 1), (1, 1, 3)]
win_dims = (4, 4, 2)
names = [file_names, ["cenote_caves", "emerald_lake", "bryce_canyon", "oregon", "hawaii"], ["cenote_caves", "bryce_canyon", "oregon", "hawaii"]]
all_means = []
all_stds = []
for i in 1:length(cg_dims)
	all_m_win, sem_win = get_avg_sh_ent(results_path, cg_dims[i], win_dims; file_names = names[i])
	push!(all_stds, sem_win)
	push!(all_means, all_m_win)
end
##
p = plot(; title = "Shannon Entropies")
for i in 1:length(all_means)
	plot!(all_means[4-i]; grid = false, ylims = [3, 15], yticks = [3, 6, 9, 12, 15], ribbon = all_stds[4-i], marker = :circle, markerstrokewidth = 0, color = c[4-i], size = (500, 334), tickfontsize = 12, label = "coarse graining = $(cg_dims[4-i])")
end
p
##
savefig(p, "$(fig_path)/entropy_progression_cg_win_4x4x2.svg")
##
cg_dims = [(3, 3, 3), (3, 3, 1), (1, 1, 3)]
win_dims = (3, 3, 3)
all_means = []
all_stds = []
for i in 1:length(cg_dims)
	all_m_win, sem_win = get_avg_sh_ent(results_path, cg_dims[i], win_dims; file_names = file_names)
	push!(all_stds, sem_win)
	push!(all_means, all_m_win)
end
##
c = [RGB(0.0, 0.3, 0.0), RGB(0.2, 0.6, 0.2), RGB(0.6, 0.9, 0.6)]

p = plot(; title = "Shannon Entropies")

for i in 1:length(all_means)
	plot!(all_means[4-i]; grid = false, ylims = [3, 15], yticks = [3, 6, 9, 12, 15], ribbon = all_stds[4-i], marker = :circle, markerstrokewidth = 0, color = c[4-i], size = (500, 334), tickfontsize = 12, label = "coarse graining = $(cg_dims[4-i])")
end
p
##
savefig(p, "$(fig_path)/entropy_progression_cg_win_3x3x3.svg")
##
cg_dims = [(3, 3, 3), (3, 3, 1), (1, 1, 3)]
win_dims = (3, 3, 3)
names = [file_names, ["cenote_caves", "emerald_lake", "bryce_canyon", "oregon", "hawaii"], ["cenote_caves", "bryce_canyon", "oregon", "hawaii"]]
all_means = []
all_stds = []
for i in 1:length(cg_dims)
	all_m_win, sem_win = get_avg_mat(results_path, cg_dims[i], win_dims; file_names = names[i])
	push!(all_stds, sem_win)
	push!(all_means, all_m_win)
end
##
all_plots = []
for m in all_means
	push!(all_plots, plot_jsd_mat(m; fontsize = 15))
end
##
plot(all_plots[1])#, layout=(1,3))
for i in 1:length(all_plots)
	cg = cg_dims[i]
	savefig(all_plots[i], "$(fig_path)/jsd_mat_cg_$(cg[1])x$(cg[2])x$(cg[3])_win_3x3x3.svg")
end
##
all_means
##
all_counter = 0
all_means = []
all_stds = []
for cg3 in cg3s
	all_m_win, sem_win = get_avg_jsd_val(results_path, file_names, (cg3, cg3, cg_dims[3]), win_dims)
	push!(all_stds, sem_win)
	push!(all_means, all_m_win)
end
plot!(
	cg3s,
	all_means,
	ylims = [0, 0.2],
	ribbon = all_stds,
	xticks = cg3s,
	yticks = [0, 0.05, 0.1, 0.15, 0.2],
	marker = :circle,
	color = RGB(0.2, 0, 0.6),
	markerstrokewidth = 0,
	grid = false,
	markersize = 4,
	xlabel = "cg step (pixels or frames)",
	ylabel = "average jsd",
	label = "space",
)

