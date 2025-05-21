using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
#cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
flush(stdout)
flush(stderr)
using SIP_package
using MPI
using JSON
using Dates
using CodecZlib
MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
worker = 0
merger = 1
name_vid = ARGS[1]
split_folder = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/$(name_vid)_split"
#split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split"
split_files = "$(split_folder)/$(name_vid)%03d.mp4"
files_names = readdir(split_folder)
# vars for sampling
glider_dim = (2, 2, 1) # rows, cols, depth
function wrapper_sampling_parallel(video_path, glider_dim)
	# video conversion into BitArray
	@info "running binarization,  free memory $(round(Sys.free_memory()/1024^3, digits=3)) max size by now: $(round(Sys.maxrss()/1024^3, digits=3))    $(Dates.format(now(), "HH:MM:SS"))"
	flush(stdout)
	flush(stderr)
	bin_vid = whole_video_conversion(video_path) # converts a target yt video into a binarized one
	# preallocation of dictionaries
	@info "before sampling: free memory $(round(Sys.free_memory()/1024^3, digits=3)) max size by now: $(round(Sys.maxrss()/1024^3, digits=3))   $(Dates.format(now(), "HH:MM:SS"))"
	counts = glider(bin_vid, glider_dim) # samples the current iteration
	@info "after sampling : free memory: $(round(Sys.free_memory()/1024^3, digits=3)) max size by now: $(round(Sys.maxrss()/1024^3, digits=3))   $(Dates.format(now(), "HH:MM:SS"))"
	flush(stdout)
	flush(stderr)
	return counts
end # EOF

if rank == 0
	for file in files_names
		file_path = "$(split_folder)/$(file)"

		current_dict = wrapper_sampling_parallel(file_path, glider_dim)
		current_dict = MPI.serialize(current_dict)
		current_dict = transcode(ZlibCompressor, current_dict)
		length_dict = Int32(length(current_dict))
		@info "outside the function : free memory: $(round(Sys.free_memory()/1024^3, digits=3)) max size by now: $(round(Sys.maxrss()/1024^3, digits=3))   $(Dates.format(now(), "HH:MM:SS"))"
		flush(stdout)
		flush(stderr)
		len_req = MPI.Isend(Ref(length_dict), merger, merger + 64, comm) # sends length of dict to merger for preallocation but with another tag (on another frequency)
		MPI.wait(len_req)
		dict_req = MPI.Isend(current_dict, merger, merger + 32, comm) # sends dict to merger
	end # for file in files_names
elseif rank == 1 # I am merger
	while true
sleep(100)
		ismessage_len, status = MPI.Iprobe(worker, rank + 64, comm)
		ismessage, status = MPI.Iprobe(worker, rank + 32, comm)
		if ismessage & ismessage_len
			length_mex = Vector{Int32}(undef, 1) # preallocates recv buffer
			req_len = MPI.Irecv!(length_mex, worker, rank + 64, comm)
			dict_buffer = Vector{UInt8}(undef, length_mex[1])
			MPI.Wait(req_len)
			dict_arrives = MPI.Irecv!(dict_buffer, worker, rank + 32, comm)
			@info "merger: dict received. free memory: $(round(Sys.free_memory()/1024^3, digits=3)) max size by now: $(round(Sys.maxrss()/1024^3, digits=3))   $(Dates.format(now(), "HH:MM:SS"))"
			flush(stdout)
			flush(stderr)
		end # if ismessage & ismessage_len 
	end
end # if rank==0 
