## initialization
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using SIP_package
##
file_name = "test_venice_long"
path2original = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(file_name).mp4"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/test_venice_long_split"
split_files = "$(split_folder)/$(file_name)%03d.mp4"
##
split_vid(path2original, split_files, 10)
