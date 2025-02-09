##
using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev/")
Pkg.activate(".")
##
using MAT
using Statistics
using SIP_package
##

##
path2data = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/MEG_data/sub003_allsens_50Hz_MNN0_badmuscle0_badlowfreq1_badsegint1_badcomp1.mat"
data = matread(path2data) # loads data as a dict with 4 entries
##
print(keys(data)) # it is a dict with 4 keys: "label" = name of the electrodes , "time" = timestamps , "data_final" = the MEG time series , "missingchan" = the missing channels
# The time series are in turn divided into the 6 runs. Each run is a channels (273) x timepoints matrix.
##
target_channel = "MLC11"
idx = Int(findfirst(==(target_channel), vec(data["label"]))) # to get the idx of the row of the target channel . Converts it into Int otherwise it'd be CartesianIndex{2}
##
target_run = 1
print(size(data["data_final"][target_run][idx, :])) # gives you the time series associated with the target_channel at the target run
##
target_signal = data["data_final"][target_run]
##
rowwise_medians = [median(row) for row in eachrow(data["data_final"][1])] # each electrode
##
bin_signal = target_signal .> rowwise_medians # each electrode
##
# maybe taylor the glider functions for 1D time-series ? 
target_electrode_bin_signal = bin_signal[idx, :]

##
bin_electrode = reshape(target_electrode_bin_signal, 1, 1, length(target_electrode_bin_signal)) # makes it become 3D (not needed anymore)
##
meg_sampling(bin_electrode, 3, (1, 1, 3), (1, 1, 3))
##

meg_dict = SIP_package.meg_sampling(target_electrode_bin_signal, 3, 3, 3)


