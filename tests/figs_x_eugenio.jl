using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
using SIP_package
using DelimitedFiles
using Plots
##
#missing 
# snow_walk and cenote_caves with win (4,4,2)
# bryce_canyon and oregon (4,4,2) (3,3,1)
# hawaii and oregon (4,4,2), (1,1,3)
# all win (4,4,2) with (3,3,1) and (1,1,3) cg to run all
# hawaii and bryce_canyon win (1,1,9) cg (1,1,3) to run all
# oregon win (1,1,16) to run all
# oregon emerald_lake win (1,1,25) to run all
# snow_walk cross_jsd 3,3,3   4,4,2
# bryce_canyon 3,3,1    4,4,2
# all cross jsd over time
##
results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results"
cg_dims_vec = [(3, 3, 3), (3, 3, 1), (1, 1, 3)]
#cg_dims_vec = [(1,1,3)]
win_dims_vec = [(4, 4, 2)]
#win_dims_vec = [(1, 1, 9), (1, 1, 16), (1, 1, 25)]
file_names_vec = ["idaho", "snow_walk", "emerald_lake", "cenote_caves", "bryce_canyon", "idaho", "snow_walk"]
for cg_dims in cg_dims_vec
	for win_dims in win_dims_vec
		for file_name in file_names_vec
			jsd_path = counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/jsd_$(file_name).csv"
			fig_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/figures_SIP/figures_eugenio"
			default(background_color = :white)
			print("$jsd_path \n")
			div_mat = readdlm(jsd_path, ',')
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
				title = "$(file_name) cg $(cg_dims[1]) $(cg_dims[2]) $(cg_dims[3]), win $(win_dims[1]) $(win_dims[2]) $(win_dims[3])",
				legend = false,
				ytick = (1:5, 0:4),
				xticks = (1:5, 0:4),
				background_color = :white,
			)
			for i in 1:size(div_mat, 1), j in 1:size(div_mat, 2)
				annotate!(i, j, text(round(div_mat[i, j]; digits = 3), 8, :black))
			end
			hm

			savefig(hm, "$(fig_path)/jsd_mat_$(file_name)_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3]).png")
		end #for win_dims in win_dims_vec
	end #for cg_dims in cg_dims_vec
end #for file_name in file_names_vec

##
results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results"
#cg_dims_vec = [(3, 3, 3), (3, 3, 1), (1, 1, 3)]
cg_dims_vec = [(1, 1, 3)]
#win_dims_vec = [(4, 4, 2)]
win_dims_vec = [(1, 1, 9), (1, 1, 16), (1, 1, 25)]
file_names_vec = ["idaho", "snow_walk", "emerald_lake", "cenote_caves", "bryce_canyon", "hawaii", "oregon"] # "idaho", (3, 3, 3) "snow_walk" (3, 3, 1)
for cg_dims in cg_dims_vec
	for win_dims in win_dims_vec
		for idx_fn1 in 1:length(file_names_vec)
			fn1 = file_names_vec[idx_fn1]
			oth_fn = setdiff(Set(file_names_vec), Set([fn1]))
			fig_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/figures_SIP/figures_eugenio"
			cross_jsd_fig_fold = "$(fig_path)/cross_jsd_$(fn1)_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
			if ~isdir(cross_jsd_fig_fold)
				mkdir(cross_jsd_fig_fold)
			end # if ~isdir(cross_jsd_fig_fold)
			#print(oth_fn)
			for fn2 in oth_fn
				#fn2 = file_names_vec[idx_fn2]
				cross_jsd_path = "$(results_path)/$(fn1)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])/cross_jsd_$(fn1)/cross_jsd_$(fn1)_vs_$(fn2).csv"

				fig_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/figures_SIP/figures_eugenio"
				default(background_color = :white)
				div_mat = readdlm(cross_jsd_path, ',')
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
					title = "$(fn1) vs $(fn2) cg $(cg_dims[1]) $(cg_dims[2]) $(cg_dims[3]), win $(win_dims[1]) $(win_dims[2]) $(win_dims[3])",
					legend = false,
					ytick = (1:5, 0:4),
					xticks = (1:5, 0:4),
					background_color = :white,
				)
				for i in 1:size(div_mat, 1), j in 1:size(div_mat, 2)
					annotate!(i, j, text(round(div_mat[i, j]; digits = 3), 8, :black))
				end
				hm

				savefig(hm, "$(cross_jsd_fig_fold)/cross_jsd_$(fn1)_vs_$(fn2).png")
			end # for win_dims in win_dims_vec
		end #for cg_dims in cg_dims_vec
	end

end #for file_name in file_names_vec
