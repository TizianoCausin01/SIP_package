# ARGS[1] = file_name , ARGS[2] = chunk_duration
using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
using SIP_package
path2data = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data"
file_name = ARGS[1]
chunk_duration = parse(Int, ARGS[2])
split_vid(path2data, file_name, chunk_duration)
