## initialization
using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
using SIP_package
using JSON
using DelimitedFiles
##
file_name = ARGS[1]
cg_dims = Tuple(parse(Int, ARGS[i]) for i in 2:4)
win_dims = Tuple(parse(Int, ARGS[i]) for i in 5:7) # rows, cols, depth
res_dir = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_results"
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


