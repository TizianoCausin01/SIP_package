### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ 0b964fc2-0942-11f0-2aba-1b81563159f4
begin
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
end

# ╔═╡ e9c65c2a-f829-454c-8573-8a776c056fa0
begin
	using SIP_package
	using VideoIO
	using Images
	using Plots
	using DelimitedFiles
end

# ╔═╡ 3b7d5f32-538e-4994-909d-52a8e6499e20
begin
	vid_name1 = "oregon"
	start1 = 50
	n_chunks1 = 5
	path2file1 = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results/FFTs/FFT_$(vid_name1)_start$(start1)_$(n_chunks1)chunks.csv"
	
	vid_name2 = "cenote_caves"
	start2 = 15
	n_chunks2 = 3
	path2file2 = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results/FFTs/FFT_$(vid_name2)_start$(start2)_$(n_chunks2)chunks.csv"

    vid_name3 = "emerald_lake"
	start3 = 99
	n_chunks3 = 5
	path2file3 = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results/FFTs/FFT_$(vid_name3)_start$(start3)_$(n_chunks3)chunks.csv"
	
	
end

# ╔═╡ 84342d67-e8c1-4d94-bd8d-09f3847af800
begin
	FFT1 = readdlm(path2file1, ',');
	FFT_01 = FFT1[2:end, :];
		
	FFT2 = readdlm(path2file2, ',');
	FFT_02 = FFT2[2:end, :];

	FFT3 = readdlm(path2file3, ',');
	FFT_03 = FFT3[2:end, :];	
end

# ╔═╡ 1f413b16-e99a-4528-b907-146806fd2d00
begin
	plot(FFT1[:,1], FFT1[:,2], label="$(vid_name1) $(n_chunks1) chunks")
	plot!(FFT2[:,1], FFT2[:,2], label="$(vid_name2) $(n_chunks2) chunks")
	plot!(FFT3[:,1], FFT3[:,2], label="$(vid_name3) $(n_chunks3) chunks")
end

# ╔═╡ 60a23df7-a0ac-4a6c-8b09-ceffb388c071
begin
	plot(log.(FFT_01[:, 1]), log.(FFT_01[:,2]), label="$(vid_name1) $(n_chunks1) chunks")
	plot!(log.(FFT_02[:, 1]), log.(FFT_02[:,2]), label="$(vid_name2) $(n_chunks2) chunks")
	plot!(log.(FFT_03[:, 1]), log.(FFT_03[:,2]), label="$(vid_name3) $(n_chunks3) chunks")
end

# ╔═╡ Cell order:
# ╠═0b964fc2-0942-11f0-2aba-1b81563159f4
# ╠═e9c65c2a-f829-454c-8573-8a776c056fa0
# ╠═3b7d5f32-538e-4994-909d-52a8e6499e20
# ╠═84342d67-e8c1-4d94-bd8d-09f3847af800
# ╠═1f413b16-e99a-4528-b907-146806fd2d00
# ╠═60a23df7-a0ac-4a6c-8b09-ceffb388c071
