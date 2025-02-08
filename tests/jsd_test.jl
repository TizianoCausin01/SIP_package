##
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
##
using SIP_package
##
dict1 = json2dict("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/counts_test_venice_iter3.json")
dict1 = counts2prob(dict1, 3)
dict2 = json2dict("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/counts_test_venice_iter4.json")
dict2 = counts2prob(dict2, 3)

SIP_package.jsd(dict1, dict2; ϵ = 1e-12)
