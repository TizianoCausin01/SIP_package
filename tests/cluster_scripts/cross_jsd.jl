using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
##
using SIP_package
using DelimitedFiles
##
results_path = "/leonardo_work/Sis25_piasini/tcausin/SIP_results"
file_name1 = ARGS[1]
file_name2 = ARGS[2]
cg_dims = Tuple(parse(Int, ARGS[i]) for i in 3:5)
win_dims = Tuple(parse(Int, ARGS[i]) for i in 6:8) # rows, cols, depth
iterations_num = 5
counts_path1 = "$(results_path)/$(file_name1)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
tot_prob_dicts1 = [counts2prob(json2dict("$(counts_path1)/counts_$(file_name1)_iter$(iter).json"), 8) for iter in 1:iterations_num]
counts_path2 = "$(results_path)/$(file_name2)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
tot_prob_dicts2 = [counts2prob(json2dict("$(counts_path2)/counts_$(file_name2)_iter$(iter).json"), 8) for iter in 1:iterations_num]
##
div_mat = zeros(iterations_num, iterations_num)
for i in 1:iterations_num
	for j in 1:i
		div_mat[i, j] = jsd(tot_prob_dicts1[i], tot_prob_dicts2[j])
	end
end
writedlm("$(counts_path1)/cross_jsd_$(file_name1)_vs_$(file_name2).csv", div_mat, ',')
writedlm("$(counts_path2)/cross_jsd_$(file_name2)_vs_$(file_name1).csv", div_mat, ',')
