using Pkg
cd("/leonardo/home/userexternal/tcausin0/virtual_envs/SIP_dev")
Pkg.activate(".")
using SIP_package
using FFTW
using VideoIO
using Images
using Statistics
using DelimitedFiles
##
name_vid = ARGS[1]
start = ARGS[2] # the nth time we do this analysis on the same video
n_chunks = ARGS[3]
FFT_folder = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_data/$(name_vid)_FFT/"
FFT_file = "$(FFT_folder)/$(name_vid)_start$(start)_$(n_chunks)chunks_FFT.mp4"
fps = get_fps(FFT_file)
results_folder = "/leonardo_scratch/fast/Sis25_piasini/tcausin/SIP_results/FFTs"
##
reader = VideoIO.openvideo(FFT_file)
##
frame, height, width, depth = get_dimensions(reader)
global gray_float_array = Array{Float64}(undef, height, width, depth) # preallocates an array of grayscale values
# array_bits = BitArray(undef, height, width, depth) # preallocates a BitArray
copyto!(view(gray_float_array, :, :, 1), Float64.(Gray.(frame))) # copies the first frame into the first element of the gray_array
global count = 1
while !eof(reader)
	global count += 1
	frame = VideoIO.read(reader)
	global gray_float_array[:, :, count] = Float64.(Gray.(frame))
end # end while !eof(reader)
@info "starting FFT"
@info Base.summarysize(gray_float_array)
fft_time = FFTW.fft(gray_float_array[:, :, :] , 3) # along the temporal dimension
avg_fft_time = mean(abs.(fft_time), dims = (1, 2))
avg_fft_time_1 = dropdims(avg_fft_time, dims = (1, 2))
pos_fft = avg_fft_time_1[1:div(depth, 2) + 1]
freqs = LinRange(0, fps/2, length(pos_fft)) # creates a series of evenly spaced numbers from 0 to nyquist freq with the N/2 +1 positive freqs
tot_vec = hcat(freqs, pos_fft)
writedlm("$(results_folder)/FFT_$(name_vid)_start$(start)_$(n_chunks)chunks.csv", tot_vec, ',')

