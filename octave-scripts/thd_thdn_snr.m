#! /usr/bin/octave -qf
%
% THD, THD+N, SNR calculation
%
% Copyright (C) Henrik Langer <henni19790@googlemail.com>
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% version 2 as published by the Free Software Foundation.
%
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.

arg = argv();
audiofile_sine = arg{1};
Fs = str2num(arg{2}); % Sample rate
num_measurements = str2num(arg{3}); % Number of iterations

% Calculate mean value of audio
audio_mean_sine = 0;
audio_mean_noise = 0;
for m = 1:num_measurements
	audiofilesine = strcat(audiofile_sine, num2str(m), '.wav');
	audiosine = wavread(audiofilesine);
	audio_sine_left_channel = audiosine(:,1);

	% Find index of closest value to 0 of first sine period
	period_range = 1:0.001/(1/Fs);
	sine_period = audio_sine_left_channel(period_range);
	sine_period = sine_period(find(sine_period >= 0));
	idx_start = find(audio_sine_left_channel(period_range) == min(sine_period));

	% Get index of period start
	if (audio_sine_left_channel(idx_start+length(period_range)/4) < 0)
		idx_start += length(period_range)/2;
		if (audio_sine_left_channel(idx_start) < 0)
			idx_start += 1;
		end
	end

	% Take 500 sine periods into measurement and calculate rms of signal amplitude
	audio_sine_left_channel = audio_sine_left_channel(idx_start:idx_start+500*length(period_range)-1);
	audio_mean_sine += audio_sine_left_channel;
end
audio_mean_sine = audio_mean_sine ./ num_measurements;

% Compute single sided amplitude spectrum
L = length(audio_mean_sine);
f = Fs*(0:(L/2))/L;
Y_sine = fft(audio_mean_sine);
P_sine = abs(Y_sine/L); % Amplitude
P_sine = P_sine(1:L/2+1); % Single sided
P_sine(2:end-1) = 2*P_sine(2:end-1);

idx_signal = find(f == 1000);
idx_harmonics = find((f == 2000) | (f == 3000) | (f == 4000) | (f == 5000) | (f == 6000));
idx_noise = find((f > 19) & (f != 1000) & (f != 2000) & (f != 3000) & (f != 4000) & (f != 5000) & (f != 6000) & (f < Fs/2+1));
idx_harmonics_plus_noise = find((f > 19) & (f != 1000) & (f < Fs/2+1));

% Get index of harmonics exluding first five
vec_high_harmonics = 7000:1000:Fs/2;
idx_high_harmonics = 0;
for n = 1:length(vec_high_harmonics)
  idx_high_harmonics(n) = find((f == vec_high_harmonics(n)));
end

% THD in dB calculation (ratio of fundamental signal to mean value of its harmonics)
thd = 10 * log10(sum(P_sine(idx_harmonics).^2) / P_sine(idx_signal).^2);

% THD+N in dB calculation (ratio of fundamental signal to mean value of its harmonics plus noise components)
thd_n = 10 * log10(sum(P_sine(idx_harmonics_plus_noise).^2) / P_sine(idx_signal).^2);

% DNR in dB calculation (ratio of fundamental signal to max noise component)
snr = 10 * log10(P_sine(idx_signal).^2 / sum(P_sine(idx_noise).^2));

printf("%f %f %f", thd, thd_n, snr);
