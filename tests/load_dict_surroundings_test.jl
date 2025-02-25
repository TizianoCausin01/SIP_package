using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")

##
using JSON
using SIP_package
##
path2data = "/Users/tizianocausin/OneDrive - SISSA/data_repo/SIP_results/short_counts_cg_3x3x3_win_2x2x2/template_matching_short/template_matching_ext_2_short.json"
dims = (2, 2, 2) .+ 2 * 2
##
load_dict_surroundings(path2data, dims)
