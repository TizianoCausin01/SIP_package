##
using Pkg
cd("/home/tcausin/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/home/tcausin/SIP_package/")
using SIP_package
##
data_dir = "/home/tcausin/SIP_data" # dir where the yt videos have been downloaded
file_name = "test_venice" # file name across different manipulations
video_path = "$data_dir/$file_name.mp4" # file path to the yt video
num_of_iterations = 5 # counting the 0th iteration
glider_coarse_g_dim = (3, 3, 3) # rows, cols, depth
glider_dim = (2, 2, 2) # rows, cols, depth
percentile = 30 # top nth part of the distribution taken into account to compute loc_max	
results_dir = "/home/tcausin/SIP_data/SIP_results"
##
wrapper_sampling(video_path, results_dir, file_name, num_of_iterations, glider_coarse_g_dim, glider_dim, percentile)

