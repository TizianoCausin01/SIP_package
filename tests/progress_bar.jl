using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
using ProgressBars
using ProgressMeter
##
@showprogress for i in ProgressBar(1:3:100000000) #wrap any iterator
	aa = 10
end
##
counts = 0
p = ProgressBar(1:100000000)
while counts < 100000000
	counts += 1
	update(p, counts)
end
##
total = 1000000000
counts = 0
prog = Progress(total)
while counts < total
	counts += 1
	next!(prog)
end
