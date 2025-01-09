## initialization
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using MPI
using SIP_package
##
myDict = JSON.parsefile("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/counts/counts_test_venice_iter5.json")
##
# Function to parse keys and create a new dictionary
function convert_to_bitvector_dict(str_dict::Dict{String, Any})
	bitvector_dict = Dict{BitVector, Int}()
	for (key, value) in str_dict
		# Check if the key matches the "Bool[...]" pattern
		if occursin(r"^Bool\[[01, ]+\]$", key)  # Validate the format
			# Extract the bit sequence inside the square brackets
			bit_string = replace(key, r"Bool\[" => "", r"\]" => "")  # Remove "Bool[" and "]"
			bits = parse.(Int, split(bit_string, ", "))  # Split and parse into integers
			bitvector_dict[BitVector(bits)] = value
		else
			println("Skipping invalid key: $key")  # Log invalid keys
		end
	end
	return bitvector_dict
end


## Convert the dictionary
bitvector_dict = convert_to_bitvector_dict(myDict)
prob_dict = counts2prob(bitvector_dict, 4)
##
T = 4 # T := temperature 
##
function prob_at_T(prob_dict::Dict{BitVector, Float32}, T::Int, approx::Int)::Dict{BitVector, Float32}
	probs_T = (values(prob_dict)) .^ (1 / T) # P_T(vec{σ}) =[1/Z(T)]*[P(vec{σ})]^(1/T) here I am computing the second part of this equation
	Z = sum(probs_T) # calculates the partition function -> Z(T) = Σ_{vec{σ}}{[P(vec{σ})]^(1/T)}
	new_probs = round.(probs_T ./ Z, digits = approx) # derives the values of the new dict at T 
	new_prob_dict_T = Dict(zip(keys(prob_dict), new_probs)) # creates a new dict with probabilities as values
	if !isapprox(sum(values(new_prob_dict_T)), 1, atol = 10.0^(-approx + 2))
		throw(ValueError("the sum of probs is different from 1"))
	end
	return new_prob_dict_T
end
##
P_T = prob_at_T(prob_dict, 3, 4)
##
using LinearAlgebra
print(sum(values(P_T) .* log.(values(P_T))))
function entropy_T(prob_dict_T::Dict{BitVector, Float32})::Float32
	return -dot(values(prob_dict_T), log.(values(prob_dict_T))) # S(T) = - Σ_{P_T(vec{σ})} {P_T(vec{σ}*ln(P_T(vec{σ}))) hence we compute the dot product between vectors
end
##
entropy_T(P_T)
## still missing heat capacity C_T
