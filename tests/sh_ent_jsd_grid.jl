using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
##
using SIP_package
using DelimitedFiles
##
results_path = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results"
file_name = "1917movie"
cg_dims = (3, 3, 3)
win_dims = (2, 2, 2)
iterations_num = 5
counts_path = "$(results_path)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
tot_prob_dicts = [counts2prob(json2dict("$(counts_path)/counts_$(file_name)_iter$(iter).json"), 8) for iter in 1:iterations_num]
##
sh_ent_vec = [tot_sh_entropy(tot_prob_dicts[iter]) for iter in 1:iterations_num]
##
div_mat = Array{Any}(undef, iterations_num, iterations_num)
for i in 1:iterations_num
	for j in 1:iterations_num
		div_mat[i, j] = jsd(tot_prob_dicts[i], tot_prob_dicts[j])
	end
end
##
writedlm("$(counts_path)/sh_entropy_$(file_name).csv", sh_ent_vec, ',')
writedlm("$(counts_path)/jsd_$(file_name).csv", div_mat, ',')
##
# to read it back
# div_mat = readdlm("$(counts_path)/jld_$(file_name).csv", ',') 
# ##
# ##in case to visualize it
# using Plots
# hm = heatmap(div_mat, color = reverse(cgrad(:viridis)), clim = (0, maximum(div_mat)), yflip = true, title="$(file_name) cg $(cg_dims[1]) $(cg_dims[2]) $(cg_dims[3]), win $(win_dims[1]) $(win_dims[2]) $(win_dims[3])")
# 	for i in 1:size(div_mat, 1), j in 1:size(div_mat, 2)
# 		annotate!(i, j, text(round(div_mat[i, j]; digits = 3), 8, :black))
# 	end
# hm
##