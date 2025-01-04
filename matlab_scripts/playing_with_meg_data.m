path2data = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/MEG_data/sub003_allsens_50Hz_MNN0_badmuscle0_badlowfreq1_badsegint1_badcomp1.mat";
load(path2data)
%%
plot(data_final{1}(1,1:100))
%%
target_sensor = data_final{1}(1,:);
median_target_sensor = median(target_sensor)
%%