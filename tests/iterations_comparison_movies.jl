##
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
##
using SIP_package
using Plots
##
file_name = "1917movie"
results_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/$(file_name)_counts"
num_of_iterations = 5
tot_dict = Dict{BitVector, Float32}[]
for iter_idx in 1:num_of_iterations
	data_path = "$(results_path)/counts_$(file_name)_iter$(iter_idx).json"
	current_dict = counts2prob(json2dict(data_path), 6)
	push!(tot_dict, current_dict)
end # for iter_idx in 1:num_of_iterations
##
div_mat = Array{Any}(undef, num_of_iterations, num_of_iterations)
for i in 1:num_of_iterations
	for j in 1:num_of_iterations
		div_mat[i, j] = jsd(tot_dict[i], tot_dict[j])
	end
end
##
hm = heatmap(div_mat, color = reverse(cgrad(:viridis)), clim = (0, 0.2), yflip = true, title = "1917movie")
for i in 1:size(div_mat, 1), j in 1:size(div_mat, 2)
	annotate!(i, j, text(round(div_mat[i, j]; digits = 3), 8, :black))
end
display(hm)
##
print(keys(tot_dict[1]))
