using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
fn = "oregon"
cg_dims = (3, 3, 3)
glider_dim = (3, 3, 3)
iteration = 1
hc = readdlm("/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(glider_dim[1])x$(glider_dim[2])x$(glider_dim[3])/$(fn)_thermodynamics/heat_capacity_$(fn)_iter$(iteration).csv", ',')
plot(range(0.5, 4, length = 1000), hc ./ (glider_dim[1] * glider_dim[2] * glider_dim[3]))
##
fn = "oregon"
cg_dims = (3, 3, 3)
glider_dim = (3, 3, 2)
iteration = 1

hc = readdlm("/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results/$(fn)_counts_cg_$(cg_dims[1])x$(cg_dims[2])x$(cg_dims[3])_win_$(glider_dim[1])x$(glider_dim[2])x$(glider_dim[3])/$(fn)_thermodynamics/heat_capacity_$(fn)_iter$(iteration).csv", ',')
plot!(range(0.5, 4, length = 1000), hc ./ (glider_dim[1] * glider_dim[2] * glider_dim[3]))
