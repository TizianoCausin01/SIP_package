## initialization
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using SIP_package
using Plots
using JSON
using DelimitedFiles
##
file_name = "test_venice_long"
cg_dims = (3, 3, 3)
win_dims = (2, 2, 2)
res_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results"
counts_dir = "$(res_dir)/$(file_name)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(win_dims[1])x$(win_dims[2])x$(win_dims[3])"
iterations = 1:5
thermo_dir = "$(counts_dir)/$(file_name)_thermodynamics"
if !isdir(thermo_dir) # checks if the directory already exists
	mkpath(thermo_dir) # if not, it creates the folder where to put the split_files
end # if !isdir(dir_path)
for iter in iterations
	myDict = json2dict("$(counts_dir)/counts_$(file_name)_iter$(iter).json")
	# Convert the dictionary
	prob_dict = counts2prob(myDict, 4)
	Temp = range(0.5, 4, length = 1000)
	heat_capacity_array = []
	entropy_array = []
	for T in Temp
		curr_prob = prob_at_T(prob_dict, T, 3)
		push!(entropy_array, entropy_T(curr_prob))
		push!(heat_capacity_array, numerical_heat_capacity_T(curr_prob, T, 6, 10e-3))
	end # for T in Temp
	writedlm("$(thermo_dir)/phys_entropy_$(file_name)_iter$(iter).csv", entropy_array, ',')
	writedlm("$(thermo_dir)/heat_capacity_$(file_name)_iter$(iter).csv", heat_capacity_array, ',')
	myDict = nothing
	GC.gc()
end # for iter in iterations
## to visualize it
# hc = readdlm("$(thermo_dir)/heat_capacity_$(file_name)_iter1.csv", ',')
# plot(range(0.5, 4, length = 1000), hc)


