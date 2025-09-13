using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
using SIP_package
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

##
plot([1, 2, 3], all_means[:, 1], yerror = all_std[:, 1], seriestype = :scatter, markersize = 4, label = "cg step = $(cg3s[1])")
plot!([1, 2, 3], all_means[:, 2], yerror = all_std[:, 2], seriestype = :scatter, markersize = 4, label = "cg step = $(cg3s[2])")
plot!([1, 2, 3], all_means[:, 3], yerror = all_std[:, 3], seriestype = :scatter, markersize = 4, label = "cg step = $(cg3s[3])")
plot!([1, 2, 3], all_means[:, 4], yerror = all_std[:, 4], seriestype = :scatter, markersize = 4, label = "cg step = $(cg3s[4])")
plot!([1, 2, 3], all_means[:, 5], yerror = all_std[:, 5], seriestype = :scatter, markersize = 4, label = "cg step = $(cg3s[4])")


##
fn = file_names[2]
file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(fn).csv"


##
cg3 = 9
fn = "oregon"
file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg3)_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(fn).csv"
#div_mat_path = "$(counts_path)/jsd_$(file_name).csv"
div_mat = readdlm(file_path, ',')
plot_jsd_mat(div_mat)
##
file_names = ["oregon", "bryce_canyon", "snow_walk", "idaho", "cenote_caves", "hawaii", "emerald_lake"]
range = 10;
stride = 3;
cg3 = 3
tot_jsds = Array{Float64}(undef, 5, 5, 7)
counter = 0
avg = 0
counter_avg = 0
all_means_within = []
for fn in file_names
	counter += 1
	file_path = "$(results_path)/local_scrambling/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg3)_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])_range_$(range)_stride_$(stride)/jsd_$(fn).csv"
	jsd_mat = readdlm(file_path, ',')
	temp_array = []
	#mask = jsd_mat .== 0
	#jsd_mat[mask] .= NaN
	tot_jsds[:, :, counter] = jsd_mat
	#push!(all_means_within, mean(filter(!isnan, jsd_mat)))
end
#push!(all_means, mean(all_means_within))
##
#mean(filter(!isnan, tot_jsds), dims=3)
avg_loc_scramb = dropdims(mean(tot_jsds, dims = 3), dims = 3)
std_loc_scramb = dropdims(std(tot_jsds, dims = 3), dims = 3)
##
plot_jsd_mat(avg_loc_scramb; std_mat = std_loc_scramb)
##
file_names = ["oregon", "bryce_canyon", "snow_walk", "idaho", "cenote_caves", "hawaii", "emerald_lake"]
scale = 20
cg3 = 3



##
avg_block, std_block = get_avg_mat(results_path, (3, 3, 3), (3, 3, 3), scrambling_condition = "block", scale = 20);
avg_local, std_local = get_avg_mat(results_path, (3, 3, 3), (3, 3, 3), scrambling_condition = "local", range = 3, stride = 1);
avg_normal, std_normal = get_avg_mat(results_path, (3, 3, 3), (3, 3, 3));
# block_scramb_plot = plot_jsd_mat(avg_block; std_mat = std_block, title_text = "block", square_size = 600, fontsize = 3)
# local_scramb_plot = plot_jsd_mat(avg_local; std_mat = std_local, title_text = "local", square_size = 600, fontsize = 3)
# normal_plot = plot_jsd_mat(avg_normal; std_mat = std_normal, title_text = "normal", square_size = 600, fontsize = 3)
block_scramb_plot = plot_jsd_mat(avg_block; title_text = "block", square_size = 600, fontsize = 3)
local_scramb_plot = plot_jsd_mat(avg_local; title_text = "local", square_size = 600, fontsize = 3)
normal_plot = plot_jsd_mat(avg_normal; title_text = "normal", square_size = 600, fontsize = 3)
plot(block_scramb_plot, local_scramb_plot, normal_plot, layout = (1, 3))
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

progression_plots[1]
##
avg_repl, std_repl = get_avg_mat(results_path, (3, 3, 1), (4, 4, 1))
plot_jsd_mat(avg_repl; std_mat = std_repl)
##
avg_repl, std_repl = get_avg_mat(results_path, (9, 9, 3), (3, 3, 3))
plot_jsd_mat(avg_repl; std_mat = std_repl, square_size = 400, fontsize = 4)

## SHANNON ENTROPY TO SEE HOW ON AVERAGE THE CG OVER SPACE
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
	push!(all_stds, std(all_means_within))
	push!(all_means, mean(all_means_within))
	# avg_diags = mean(diags, dims = 2)
	# std_diags = std(diags, dims = 2)
	# all_means[:, all_counter] = avg_diags
	# all_std[:, all_counter] = std_diags
end
plot(cg3s, all_means, yerror = all_stds, seriestype = :scatter, markersize = 4, xlabel = "cg step (frames)", ylabel = "average sh entropy")

## TO SEE HOW ON AVERAGE THE CG OVER SPACE IS STRONG
cg3s = [1, 3, 5, 7, 9]
all_means = zeros(3, length(cg3s))
all_std = zeros(3, length(cg3s))
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
		file_path = "$(results_path)/$(fn)_counts_cg_$(cg3)x$(cg3)x3_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(fn).csv"
		jsd_mat = readdlm(file_path, ',')
		jsd_mat = jsd_mat[1:3, 1:3]
		temp_array = []
		# for i in 1:4
		# 	for j in 1:i-1
		# 		push!(temp_array, jsd_mat[i, j])
		# 	end
		# end
		mask = jsd_mat .== 0
		jsd_mat[mask] .= NaN
		push!(all_means_within, mean(filter(!isnan, jsd_mat)))
	end
	push!(all_stds, std(all_means_within))
	push!(all_means, mean(all_means_within))
	# avg_diags = mean(diags, dims = 2)
	# std_diags = std(diags, dims = 2)
	# all_means[:, all_counter] = avg_diags
	# all_std[:, all_counter] = std_diags
end

plot(cg3s, all_means, yerror = all_stds, seriestype = :scatter, markersize = 4, xlabel = "cg step (pixels)", ylabel = "average jsd")



## PROGRESSION CG IN SPACE OVER ALL THE DIAGONALS
# fn = file_names[1] 
win_dims = (3, 3, 3)

cg3s = [1, 3, 5, 7, 9]
all_means = zeros(3, length(cg3s))
all_std = zeros(3, length(cg3s))
all_counter = 0
for cg3 in cg3s
	all_counter += 1
	diags = zeros(3, 7)
	counter = 0
	for fn in file_names
		counter += 1
		file_path = "$(results_path)/$(fn)_counts_cg_$(cg3)x$(cg3)x3_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(fn).csv"
		jsd_mat = readdlm(file_path, ',')
		jsd_mat = jsd_mat[1:3, 1:3]
		diags[1, counter] = mean(diag(jsd_mat, -1))
		diags[2, counter] = mean(diag(jsd_mat, -2))
		diags[3, counter] = mean(diag(jsd_mat, -3))
	end
	avg_diags = mean(diags, dims = 2)
	std_diags = std(diags, dims = 2)
	all_means[:, all_counter] = avg_diags
	all_std[:, all_counter] = std_diags
end

plot(cg3s, all_means[:, 1], yerror = all_std[:, 1], seriestype = :scatter, label = "cg step = $(cg3s[1])")
plot!(cg3s, all_means[:, 2], yerror = all_std[:, 2], seriestype = :scatter, label = "cg step = $(cg3s[2])")
plot!(cg3s, all_means[:, 3], yerror = all_std[:, 3], seriestype = :scatter, label = "cg step = $(cg3s[3])")
plot!(cg3s, all_means[:, 4], yerror = all_std[:, 4], seriestype = :scatter, label = "cg step = $(cg3s[4])")
plot!(cg3s, all_means[:, 5], yerror = all_std[:, 5], seriestype = :scatter, label = "cg step = $(cg3s[4])")

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



## TO SEE HOW ON AVERAGE THE CG OVER TIME IS WEAKER
cg3s = [1, 3, 5, 7, 9]
all_means = zeros(3, length(cg3s))
all_std = zeros(3, length(cg3s))
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
		file_path = "$(results_path)/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg3)_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(fn).csv"
		jsd_mat = readdlm(file_path, ',')
		jsd_mat = jsd_mat[1:3, 1:3]
		temp_array = []
		# for i in 1:4
		# 	for j in 1:i-1
		# 		push!(temp_array, jsd_mat[i, j])
		# 	end
		# end
		mask = jsd_mat .== 0
		jsd_mat[mask] .= NaN
		push!(all_means_within, mean(filter(!isnan, jsd_mat)))
	end
	push!(all_stds, std(all_means_within))
	push!(all_means, mean(all_means_within))
	# avg_diags = mean(diags, dims = 2)
	# std_diags = std(diags, dims = 2)
	# all_means[:, all_counter] = avg_diags
	# all_std[:, all_counter] = std_diags
end
plot(cg3s, all_means, yerror = all_stds, seriestype = :scatter, markersize = 4, xlabel = "cg step (frames)", ylabel = "average jsd")

## PROGRESSION CG IN SPACE OVER ALL THE DIAGONALS
cg3s = [1, 3, 5, 7, 9]
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

plot(cg3s, all_means[:, 1], yerror = all_std[:, 1], seriestype = :scatter, label = "cg step = $(cg3s[1])")
plot!(cg3s, all_means[:, 2], yerror = all_std[:, 2], seriestype = :scatter, label = "cg step = $(cg3s[2])")
plot!(cg3s, all_means[:, 3], yerror = all_std[:, 3], seriestype = :scatter, label = "cg step = $(cg3s[3])")
plot!(cg3s, all_means[:, 4], yerror = all_std[:, 4], seriestype = :scatter, label = "cg step = $(cg3s[4])")
plot!(cg3s, all_means[:, 5], yerror = all_std[:, 5], seriestype = :scatter, label = "cg step = $(cg3s[4])")
