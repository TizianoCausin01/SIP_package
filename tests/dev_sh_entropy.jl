using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
using SIP_package
using DelimitedFiles
using Plots
using LinearAlgebra
using Statistics
using Random

"""
	random_distribution(n::Int, target_H::Float64; tol=1e-3, max_iter=10000)

Generate a Dict{Int,Float64} of length `n` representing a probability distribution
with Shannon entropy close to `target_H` (in bits).
"""
function random_distribution(n::Int, target_H::Float64; tol = 1e-3, max_iter = 10000)
	for iter in 1:max_iter
		# Sample random positive weights
		w = rand(n)
		p = w ./ sum(w)  # normalize to sum=1

		# Compute entropy
		H = -sum(pi -> pi > 0 ? pi * log2(pi) : 0.0, p)

		if abs(H - target_H) < tol
			return Dict(i => p[i] for i in 1:n), H
		end
	end
	error("Could not find distribution with entropy ≈ $target_H after $max_iter iterations")
end

# Example: 5-element distribution with entropy ≈ 2 bits
dist, H = random_distribution(5, 2.0)
println("Distribution: ", dist)
println("Entropy: ", H)
##
typeof(dist)
##
dist = Dict(1 => 0.25, 4 => 0.25, 2 => 0.25, 3 => 0.25)
##
tot_sh_entropy(dist)
