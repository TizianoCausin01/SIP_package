### A Pluto.jl notebook ###
# v0.20.6

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ f20e1b94-56d2-11f0-0ca7-9b94ca953025
begin
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
end

# ╔═╡ 313a984b-ff6a-403b-adbc-901527f1f667
begin
using SIP_package
using MPI
using JSON
using Dates
using CodecZlib
using VideoIO
using Images
using Statistics
using Random
using Images
	using ImageView
using PlutoUI
end

# ╔═╡ ced0ca79-83de-4aa7-a8c7-98d337db6a34
begin
video_path = "/Users/tizianocausin/Desktop/bolt_moviechunk.mp4"
vid = whole_video_conversion(video_path);
end

# ╔═╡ 280c5054-64af-4f1e-8e71-6fa81b7dc879
begin
range_scr = 10; stride = 3
vid_ls = local_scrambling(vid, range_scr, stride);
end

# ╔═╡ cbb4e5de-96c8-48af-a3f1-6cebab3fde5a
@bind frame_idx_loc Slider(1:size(vid_ls, 3), show_value=true)

# ╔═╡ be27e3c2-6ca8-49aa-80e9-b14987014445
Gray.(vid_ls[:, :, frame_idx_loc])

# ╔═╡ a82a6ffa-0273-469e-8038-3e7819bc6d0b
n_v = block_scrambling(vid, 20);

# ╔═╡ 96fcd436-5284-474b-8fc7-6a68e67b81c1
@bind frame_idx_block Slider(1:size(n_v, 3), show_value=true)

# ╔═╡ 781cd0b7-2077-4343-8b54-b7db17b5fb4a
Gray.(n_v[:, :, frame_idx_block])

# ╔═╡ Cell order:
# ╠═f20e1b94-56d2-11f0-0ca7-9b94ca953025
# ╠═313a984b-ff6a-403b-adbc-901527f1f667
# ╠═ced0ca79-83de-4aa7-a8c7-98d337db6a34
# ╠═280c5054-64af-4f1e-8e71-6fa81b7dc879
# ╠═cbb4e5de-96c8-48af-a3f1-6cebab3fde5a
# ╠═be27e3c2-6ca8-49aa-80e9-b14987014445
# ╠═a82a6ffa-0273-469e-8038-3e7819bc6d0b
# ╠═96fcd436-5284-474b-8fc7-6a68e67b81c1
# ╠═781cd0b7-2077-4343-8b54-b7db17b5fb4a
