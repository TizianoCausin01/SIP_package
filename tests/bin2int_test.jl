


using LinearAlgebra
function bin2int(win::BitArray{3})::Int64
	win_el = length(win)
	progression = reverse(0:win_el-1)
	pow_of_2 = 2 .^ progression
	win_vec = vec(win)
	int_repr = Int64(dot(win_vec, pow_of_2))
	return int_repr
end # EOF
##
a = falses(3, 3, 3)
a[1, :, 1] .= true
##
bin2int(a)
##
bs = filter(x -> !isspace(x), bitstring(vec(a)))
##
parse(Int, bs, base = 2)


