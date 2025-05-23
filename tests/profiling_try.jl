##
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using Profile
using PProf
##
function waiting(list)  # Function to profile
	for i in 1:100
		aa = rand(1, 1000)
		push!(list, aa...)
	end
end
##
prova = [0.1, 0.2, 0.3, 0.4, 0.5]
@profile waiting(prova)
##
Profile.print()
##
@pprof waiting(prova)
##
new_rows, new_cols, new_time = [0, 0, 0]
