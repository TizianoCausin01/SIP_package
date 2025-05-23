using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
Pkg.develop(path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/")
using SIP_package
using Metal
##
using GPUArrays
using Metal
##
print(Metal.device())
##
aa = [1 1 1; 2 2 2]
bb = [2 2; 1 1; 3 3]

gpu_aa = GPUArray(aa)
gpu_bb = GPUArray(bb)
##
@elapsed(gpu_aa * gpu_bb)

# If needed, fallback to CPU:
result_cpu = aa * bb  # Matrix multiplication on CPU

# Fetch the result from GPU to CPU
result_gpu = Array(gpu_result)

println("GPU Result: ", result_gpu)
println("CPU Result: ", result_cpu)
##

