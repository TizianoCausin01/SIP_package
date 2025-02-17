##
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
##
using SIP_package
##
my_dict = json2dict("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/counts_test_venice_iter3.json")
my_dict_prob = counts2prob(my_dict, 3)

##
tot_sh_entropy(my_dict_prob)