function col_major(A, b)
	for k in 1:size(A, 3)
		for j in 1:size(A, 2)
			for i in 1:size(A, 1)  # Fastest-changing index
				b[i, j, k] = A[i, j, k]
			end
		end
	end
end
function row_major(A, b)

	for i in 1:size(A, 3)
		for j in 1:size(A, 1)
			for k in 1:size(A, 2)
				b[i, j, k] = A[i, j, k]
			end
		end
	end
end
##
N = 500
A = zeros(N, N, N)
b = zeros(N, N, N)
@time col_major(A, b)
@time row_major(A, b)
