
path2data = "/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/data_repo/SIP_data/MEG_data/sub003_allsens_50Hz_MNN0_badmuscle0_badlowfreq1_badsegint1_badcomp1.mat";
load(path2data)
%%
plot(data_final{1}(1,1:100))
%%
target_sensor = data_final{4}(203,:);
median_target_sensor = median(target_sensor)
%% Claude generated code
% Assuming your signal is stored in variable 'signal'
% and your sampling frequency is 'Fs' in Hz

Fs = 50 % Hz, it's the sampling frequency
% Compute FFT
Y = fft(target_sensor); % Y has the same legnth of my signal (row vec)

% Compute frequency axis
L = length(target_sensor); 
f = Fs*(0:(L/2))/L;

% Compute magnitude spectrum (take only first half due to symmetry)
P2 = abs(Y/L);
P1 = P2(1:floor(L/2+1));
P1(2:end-1) = 2*P1(2:end-1);

% Plot the spectrum
plot(log10(f), log10(P1))
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('Single-Sided Amplitude Spectrum')
%% GPT generated code
% Load the neural signal (example signal)
fs = 1000; % Sampling frequency in Hz
t = 0:1/fs:1-1/fs; % Time vector (1 second duration)
neural_signal = target_sensor

% Compute the FFT
N = length(neural_signal); % Length of the signal
Y = fft(neural_signal); % Perform FFT
Y = Y(1:N/2+1); % Take the positive half of the spectrum

% Compute the frequency axis
frequencies = (0:N/2)*(fs/N); % Frequency vector

% Compute the magnitude of the FFT
amplitude = abs(Y)/N; % Normalize the amplitude

% Plot the spectrum
figure;
plot(log10(frequencies), log10(amplitude));
xlabel('Frequency (Hz)');
ylabel('Amplitude');
title('Spectrum of Neural Signal');
grid on;
