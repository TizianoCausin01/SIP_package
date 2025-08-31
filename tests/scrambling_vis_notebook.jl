### A Pluto.jl notebook ###
# v0.20.6

using Markdown
using InteractiveUtils

# ╔═╡ 9527c098-756e-11f0-0e60-cb5702c17530
begin
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
end

# ╔═╡ ceaf6201-6674-4740-ae9d-e1d16c42ce4d
begin
using DelimitedFiles
using Plots
end

# ╔═╡ 47d5d1ef-c430-45e7-96f2-5279f6aebaac
function plot_jsd(div_mat, title="")
	hm = heatmap(
		div_mat,
		title = title,
        clim = (0, 0.15),
		color = :viridis,
		yflip = true,
		legend = false,
		ytick = (1:5, 0:4),
		xticks = (1:5, 0:4),
		background_color = :white,
)
for i in 1:size(div_mat, 1), j in 1:size(div_mat, 2)
		annotate!(i, j, text(round(div_mat[j, i]; digits = 3), 8, :black))
end
hm

end # EOF

# ╔═╡ 76903015-da70-4cde-a91c-81471c873295
begin
	jsd_path_gt = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/oregon_counts_cg_3x3x3_win_3x3x3/jsd_oregon.csv"
	div_mat_gt = readdlm(jsd_path_gt, ',')

	local_jsd_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/local_scrambling/oregon_counts_cg_3x3x3_win_3x3x3_range_3_stride_1/jsd_oregon.csv"
	div_mat_loc = readdlm(local_jsd_path, ',')

	loc2_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/block_scrambling/oregon_counts_cg_3x3x3_win_3x3x3_scale_10/jsd_oregon.csv"
	
	block_jsd_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/block_scrambling/oregon_counts_cg_3x3x3_win_3x3x3_scale_20/jsd_oregon.csv"
	div_mat_block = readdlm(block_jsd_path, ',');

end

# ╔═╡ f31054a0-f66e-42ad-af41-2ce48109cb44
begin
plot_jsd(div_mat_gt, "ground_truth")
end

# ╔═╡ 7a3564a4-e866-4aaa-8afd-01079cd52464
plot_jsd(div_mat_loc, "loc scrambling range 3, stride 1")

# ╔═╡ 4930f38f-6933-479c-91fa-1d75a3013af2
plot_jsd(div_mat_block, "block scrambling scale 20")

# ╔═╡ aa6ca3c9-82b7-43e4-9fd7-e7ee3f07d43e
begin
	local2_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/local_scrambling/oregon_counts_cg_3x3x3_win_3x3x3_range_10_stride_3/jsd_oregon.csv"
	div_mat_local2 = readdlm(local2_path, ',')

	
	block2_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/block_scrambling/oregon_counts_cg_3x3x3_win_3x3x3_scale_10/jsd_oregon.csv"
div_mat_block2 = readdlm(block2_path, ',');
end

# ╔═╡ 556f6dc6-e2b6-4c74-afdd-5d80a7844f84
plot_jsd(div_mat_local2, "local scrambling range 10 stride 3")

# ╔═╡ 892b240c-33d0-43b8-b526-aa86c3b30df5
plot_jsd(div_mat_block2, "block scrambling scale 10")

# ╔═╡ Cell order:
# ╠═9527c098-756e-11f0-0e60-cb5702c17530
# ╠═ceaf6201-6674-4740-ae9d-e1d16c42ce4d
# ╠═47d5d1ef-c430-45e7-96f2-5279f6aebaac
# ╠═76903015-da70-4cde-a91c-81471c873295
# ╠═f31054a0-f66e-42ad-af41-2ce48109cb44
# ╠═7a3564a4-e866-4aaa-8afd-01079cd52464
# ╠═4930f38f-6933-479c-91fa-1d75a3013af2
# ╠═aa6ca3c9-82b7-43e4-9fd7-e7ee3f07d43e
# ╠═556f6dc6-e2b6-4c74-afdd-5d80a7844f84
# ╠═892b240c-33d0-43b8-b526-aa86c3b30df5
