using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
function int2win(key, win_dims)
	str_key = bitstring(key)
	print(str_key)
	tot_bits = win_dims[1] * win_dims[2] * win_dims[3]
	str_key = str_key[end-tot_bits+1:end]
	bit_vec_key = BitVector(c == '1' for c in str_key)
	win = reshape(bit_vec_key, win_dims)
	return win
end # EOF
##



