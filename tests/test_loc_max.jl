##
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")

##
using JSON
##

##
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
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

##
println(bitvector_dict)
##
loc_max = get_loc_max(bitvector_dict, 40)
##
plot_loc_max(loc_max, (2, 2, 2), 1)
##
edit(plot_loc_max)
##
fn = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/test_venice.mp4"
split_vid(fn, outfn, 10)
outfn = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/test_ven%03d.mp4"


