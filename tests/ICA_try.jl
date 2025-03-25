using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
using SIP_package
using Images
using VideoIO
using Random
#using ImageIO
using Images
using LinearAlgebra
using Statistics
using MultivariateStats
name_vid = "test_venice_long"
split_folder = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/$(name_vid)_split"
split_files = "$(split_folder)/$(name_vid)001.mp4"
##
##
seek(reader, 4)
frame = VideoIO.read(reader)
##
VideoIO.testvideo(reader)
##
n_vids = 40 # num of samples
ratio_denom = 50
frame_seq = 3 # concatenates n frames
n_comps = 4
gray_array_ICA = prepare_for_ICA(split_files, n_vids, ratio_denom, frame_seq)
##
# # here ICA wants the datamatrix X as samples x features
# arr_whitened = centering_whitening(gray_array, 1e-10)

# ##
# a = whiten_data(gray_array)
# ##
# verify_whitening(a)
# ##
# round.(cov(arr_whitened), digits = 2)
# ##
# a = rand(10, 10)
# a_white = centering_whitening(a)
# @info "$(round.(cov(a_white), digits=0))"
##
model = MultivariateStats.fit(ICA, gray_array_ICA, n_comps, maxiter = 100000, tol = 1, do_whiten = true)#, do_whiten = false) # use dot notation because otherwise it's in conflict with the original fit function 
##
ICs = model.W
##

##
reader = VideoIO.openvideo(split_files)
frame = VideoIO.read(reader);
##
height_sm, width_sm = size(imresize(frame, ratio = 1 / ratio_denom))
##
to_vis = Gray.(reshape(ICs[:, 4], height_sm, width_sm, frame_seq))
for i in 1:frame_seq
	display(to_vis[:, :, i] .* 10)
	sleep(0.5)
end

##
# ICFs = model.W
vid_comp = Gray.(reshape(comps[2, :], height_sm, width_sm, frame_seq))
# for i in 1:frame_seq
# 	display(Gray.(vid_comp[:, :, i]))
# 	sleep(0.5)
# end
##
##
using LinearAlgebra
using Statistics


##
function centering_whitening(X, tol = 1e-5)
	# Center the data (mean subtraction)
	X_centered = X .- mean(X, dims = 1)

	# Compute the covariance matrix
	C = cov(X_centered)
	@info "$(size(C))"

	# Eigen-decomposition of the covariance matrix
	F = eigen(C)
	evals = F.values
	neg_idx = evals .< tol
	@info "$neg_idx"
	evals[neg_idx] .= tol

	# Only retain positive eigenvalues (to avoid numerical issues with small negative eigenvalues)
	evals = abs.(F.values)
	whitening_matrix = F.vectors * Diagonal(1.0 ./ sqrt.(evals)) * F.vectors'
	X_whitened = X_centered * whitening_matrix

	return X_whitened
end
##
function whiten_data(X::Matrix{Float64}; method::Symbol = :zca)
	"""
	Whiten a data matrix using either ZCA (Zero-phase Component Analysis) or PCA whitening.

	Parameters:
	- X: Input data matrix (rows = datapoints, columns = features)
	- method: Whitening method (:zca or :pca, default is :zca)

	Returns:
	- Whitened data matrix
	"""
	# Center the data by subtracting the mean of each feature
	X_centered = X .- mean(X, dims = 1)

	# Compute the covariance matrix
	cov_matrix = cov(X_centered)

	# Eigendecomposition of the covariance matrix
	eigen_decomp = eigen(cov_matrix)

	# Find indices of positive eigenvalues (to handle numerical issues)
	pos_idx = eigen_decomp.values .> 1e-10

	# Extract positive eigenvalues and corresponding eigenvectors
	evals = eigen_decomp.values[pos_idx]
	evecs = eigen_decomp.vectors[:, pos_idx]

	# Regularization parameter to prevent division by very small numbers
	epsilon = 1e-5

	# Compute the whitening transformation matrix
	if method == :zca
		# ZCA whitening (preserves the original data orientation)
		whitening_matrix = evecs * Diagonal(1.0 ./ sqrt.(evals .+ epsilon)) * evecs'
		X_whitened = X_centered * whitening_matrix
	elseif method == :pca
		# PCA whitening (decorrelates and scales the data)
		whitening_matrix = evecs * Diagonal(1.0 ./ sqrt.(evals .+ epsilon))
		X_whitened = X_centered * whitening_matrix
	else
		error("Invalid whitening method. Choose :zca or :pca")
	end

	return X_whitened
end

# Verification function to check whitening properties
function verify_whitening(X::Matrix{Float64}; method::Symbol = :zca)
	"""
	Verify the whitening process by checking mean and covariance properties.

	Parameters:
	- X: Input data matrix
	- method: Whitening method

	Prints diagnostic information about the whitening process.
	"""
	# Perform whitening
	X_whitened = whiten_data(X, method = method)

	println("Original Data:")
	println("  Mean: ", round.(mean(X, dims = 1), digits = 4))
	println("  Covariance matrix diagonal: ", round.(diag(cov(X)), digits = 4))

	println("\nWhitened Data:")
	println("  Mean: ", round.(mean(X_whitened, dims = 1), digits = 4))
	println("  Covariance matrix diagonal: ", round.(diag(cov(X_whitened)), digits = 4))

	return X_whitened
end

# Example usage
function example_whitening()
	# Generate some sample data
	X = randn(100, 5)  # 100 datapoints, 5 features

	println("ZCA Whitening:")
	X_zca = verify_whitening(X, method = :zca)

	println("\nPCA Whitening:")
	X_pca = verify_whitening(X, method = :pca)
end

# Uncomment to run the example
example_whitening()
