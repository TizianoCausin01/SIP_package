using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using SIP_package
##
function generate_rand_dict(size_str, size_dict, num_of_iterations)

	if 2^size_str < size_dict
		@warn "the possible combinations of bits are less than the desired size of the dictionary"
	end
	dicts_vec = []
	for iter in 1:num_of_iterations
		my_dict = Dict{BitVector, Int}()
		for i in 1:size_dict
			key = BitVector(rand(Bool, size_str))
			val = rand(1:100)
			my_dict[key] = val
		end # for i in 1:size_dict
		push!(dicts_vec, my_dict)
	end #for iter in 1:num_of_iterations
	return dicts_vec
end # EOF
##
rand_dict = generate_rand_dict(10, 100, 1)[1]
##
lm = get_loc_max_ham(rand_dict, 10, 9)