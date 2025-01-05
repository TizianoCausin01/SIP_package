# to run this : bash %  mpiexec -np 4 julia /Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/tests/MPI_try.jl
##
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using MPI
using JSON

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm) # to establish a unique ID for each process
nproc = MPI.Comm_size(comm) # to establish the total number of processes used
root = 0
print("Hello, I'm rank $(rank) of size $(nproc) \n")

# Function to parse keys and create a new dictionary
function convert_to_bitvector_dict(str_dict::Dict{String, Any})
	bitvector_dict = Dict{BitVector, Int}()
	for (key, value) in str_dict
		# Check if the key matches the Bool pattern
		if occursin(r"^Bool\[[01, ]+\]$", key)  # Validate the format
			# Extract the bit sequence inside the square brackets
			bit_string = replace(key, r"Bool\[" => "", r"\]" => "")  # Remove "Bool[" and "]"
			bits = parse.(Int, split(bit_string, ", "))  # Split and parse into integers
			bitvector_dict[BitVector(bits)] = value
		else
			println("Skipping invalid key: $key")  # Log invalid keys
		end
	end
	return bitvector_dict
end #EOF

counts_dir = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_results/counts/"
file_names = readdir(counts_dir)
my_files = file_names[rank+1:nproc:length(file_names)] # cyclic distribution (like dealing cards) -> each process has a different rank so it will be assigned different files
fn = joinpath(counts_dir, my_files[1])
myDict = JSON.parsefile(fn)
myDict_bitvec = convert_to_bitvector_dict(myDict)
send_buf = MPI.serialize(myDict_bitvec)
if rank == 0
	print(typeof(send_buf))
end
# Gather the sizes of the serialized buffers
send_size = length(send_buf)
if rank == root
	recv_sizes = Vector{Int}(undef, nproc)  # Preallocate an array to receive the gathered data
else
	recv_sizes = Int32[]
end
MPI.Gather!(Ref(send_size), recv_sizes, comm; root) # this sends only the sizes, not the whole file

if rank == root
	total_size = sum(recv_sizes)
	recv_sizes = Int32.(recv_sizes)
	recv_buf = Vector{UInt8}(undef, total_size)

	offsets = Int32.(cumsum([0; recv_sizes[1:end-1]]))
	better_buf = VBuffer(recv_buf, recv_sizes)
	println("Total size: ", total_size)
	println("Recv sizes: ", recv_sizes)
	println("Offsets: ", offsets)
else
	recv_buf = Vector{UInt8}()
	offsets = Vector{Int32}(undef, 0)
end
if rank == root
	MPI.Gatherv!(send_buf, better_buf, root, comm)
	deserialized_dicts = [MPI.deserialize(recv_buf[offsets[i]+1:offsets[i]+recv_sizes[i]]) for i in 1:length(recv_sizes)]
	print(length(deserialized_dicts))
else
	MPI.Gatherv!(send_buf, nothing, root, comm)
end

MPI.Finalize()
