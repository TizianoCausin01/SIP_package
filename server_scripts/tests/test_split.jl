## initialization
using Pkg
cd("/home/tcausin/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/home/tcausin/SIP_package/")
using SIP_package

file_name = "ukraine"
path2original = "/home/tcausin/data/SIP_data/$(file_name).mp4"
split_folder = "/home/tcausin/data/SIP_data/$(file_name)_split"
split_files = "$(split_folder)/$(file_name)%03d.mp4"
##
split_vid(path2original, split_files, 60)
