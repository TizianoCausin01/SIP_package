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

# ╔═╡ a2f288be-1fa1-4dc6-ae08-5208b1be4343
begin 
	path2results = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results/FFTs"
	vid_names = ["oregon", "cenote_caves", "emerald_lake", "snow_walk", "idaho", "hawaii", "bryce_canyon"]
	starts = [50, 15, 99, 30, 347, 400, 174]
	n_chunks = [5, 3, 5, 5, 5, 5, 5] 
	path2files = ["$(path2results)/FFT_$(vid_names[i_vid])_start$(starts[i_vid])_$(n_chunks[i_vid])chunks.csv" for i_vid in 1:length(vid_names)]

end

# ╔═╡ e0219930-d215-45c4-bdd3-7e432d4dbe9f
begin 
	FFTs = [readdlm(path2files[i_vid], ',') for i_vid in 1:length(vid_names)]
	FFTs_0 = [FFTs[i_vid][2:end,:] for i_vid in 1:length(FFTs)]
end

# ╔═╡ f543aa8d-6b7c-45c6-817f-14d55d92e8fe
begin
	p = plot(FFTs[1][:,1], FFTs[1][:,2], label="$(vid_names[1]) $(n_chunks[1]) chunks")
	for i_vid in 2:length(vid_names)
		plot!(p, FFTs[i_vid][:,1], FFTs[i_vid][:,2], label="$(vid_names[i_vid]) $(n_chunks[i_vid]) chunks")
	end
current()
end

# ╔═╡ ebb71b60-10e6-4c69-ba3e-9175436b7a54
begin
	log_p = plot(log.(FFTs_0[1][:,1]), log.(FFTs_0[1][:,2]), label="$(vid_names[1]) $(n_chunks[1]) chunks")
	for i_vid in 2:length(vid_names)
		plot!(log_p, log.(FFTs_0[i_vid][:,1]), log.(FFTs_0[i_vid][:,2]), label="$(vid_names[i_vid]) $(n_chunks[i_vid]) chunks")
	end
	current()
end

# ╔═╡ Cell order:
# ╠═0b964fc2-0942-11f0-2aba-1b81563159f4
# ╠═e9c65c2a-f829-454c-8573-8a776c056fa0
# ╠═a2f288be-1fa1-4dc6-ae08-5208b1be4343
# ╠═e0219930-d215-45c4-bdd3-7e432d4dbe9f
# ╠═f543aa8d-6b7c-45c6-817f-14d55d92e8fe
# ╠═ebb71b60-10e6-4c69-ba3e-9175436b7a54
