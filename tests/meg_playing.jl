##
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
##
using MAT
using Statistics
using SIP_package
using Plots
##

##
path2data = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/MEG_data/sub003_allsens_50Hz_MNN0_badmuscle0_badlowfreq1_badsegint1_badcomp1.mat"
data = matread(path2data) # loads data as a dict with 4 entries
##
print(keys(data)) # it is a dict with 4 keys: "label" = name of the electrodes , "time" = timestamps , "data_final" = the MEG time series , "missingchan" = the missing channels
# The time series are in turn divided into the 6 runs. Each run is a channels (273) x timepoints matrix.
##
##
target_run = 1
print(size(data["data_final"][target_run][idx, :])) # gives you the time series associated with the target_channel at the target run
##
target_run = 1
run_num = 3
for i_run in 1:run_num # concatenates the first three runs (but binarizes each of them separately, because of possible signal drifting across runs)
	target_signal = data["data_final"][i_run]
	rowwise_medians = [median(row) for row in eachrow(target_signal)] # each electrode
	bin_signal = target_signal .> rowwise_medians # each electrode
	if !@isdefined tot_signal
		global tot_signal = bin_signal
	else
		global tot_signal = hcat(tot_signal, bin_signal)
	end # if !@isdefined tot_signal
end # for i_run in 1:run_num
##

# target_channel= "MZO01"
for target_channel in data["label"]
	idx = Int(findfirst(==(target_channel), vec(data["label"]))) # to get the idx of the row of the target channel . Converts it into Int otherwise it'd be CartesianIndex{2}
	target_electrode_bin_signal = tot_signal[idx, :]
	num_of_iterations = 5
	glider_coarse_g_dim = 3
	glider_sampling_dim = 5
	meg_dict = SIP_package.meg_sampling(target_electrode_bin_signal, num_of_iterations, glider_coarse_g_dim, glider_sampling_dim)
	prob_meg_dict = [counts2prob(meg_dict[iter], 5) for iter in 1:num_of_iterations]
	div_mat = Array{Any}(undef, num_of_iterations, num_of_iterations)
	for i in 1:num_of_iterations
		for j in 1:num_of_iterations
			div_mat[i, j] = jsd(prob_meg_dict[i], prob_meg_dict[j])
		end
	end
	fig_path = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/figures_SIP"
	hm = heatmap(div_mat, color = reverse(cgrad(:viridis)), clim = (0, 0.09), yflip = true, title = target_channel)
	for i in 1:size(div_mat, 1), j in 1:size(div_mat, 2)
		annotate!(i, j, text(round(div_mat[i, j]; digits = 3), 8, :black))
	end
	savefig(hm, "$(fig_path)/$(target_channel)_jsd_mat.png")
end # for target_channel in data["label"]


