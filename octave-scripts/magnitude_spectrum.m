#! /usr/bin/octave -qf
%
% Magnitude spectrum calculation
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

pkg load control
pkg load signal

arg = argv();
Fs = str2num(arg{1}); % Sample rate
SoundCardName = arg{2};
freq_vec_44_1 = [1 2 3 4 5 6 7 8 9 10 20 30 40 50 60 70 80 90 100 200 300 400 500 600 700 800 900 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000 20000 21000];
freq_vec_48 = [1 2 3 4 5 6 7 8 9 10 20 30 40 50 60 70 80 90 100 200 300 400 500 600 700 800 900 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000 20000 23000];
freq_vec_96 = [1 2 3 4 5 6 7 8 9 10 20 30 40 50 60 70 80 90 100 200 300 400 500 600 700 800 900 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000 20000 30000 40000 47000];
freq_vec_192 = [1 2 3 4 5 6 7 8 9 10 20 30 40 50 60 70 80 90 100 200 300 400 500 600 700 800 900 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000 20000 30000 40000 50000 60000 70000 80000 90000 95000];

if Fs == 44100
	freq_vec = freq_vec_44_1;
elseif Fs == 48000
	freq_vec = freq_vec_48;
elseif Fs == 96000
	freq_vec = freq_vec_96;
elseif Fs == 192000
	freq_vec = freq_vec_192;
else
	exit
end

freq_vec_len = length(freq_vec);
FRvec = zeros(1, freq_vec_len);
title_ = ({['Frequency response with ' num2str(Fs/1000) ' kHz sampling rate of'];[SoundCardName]});

c = 1;
for f = freq_vec
	audiofile = strcat('sine-test/magnitude-spectrum/sine-0dBFS-', num2str(Fs), '-', strtrim(num2str(f)), '-Hz.wav');
	audio = wavread(audiofile);

	L = length(audio);
	X = fft(audio);
	P_audio = abs(X/L); % Amplitude
	P_audio = P_audio(1:L/2+1); % single sided
	P_audio(2:end-1) = 2*P_audio(2:end-1);

	Amp = max(P_audio);

	FRvec(1, c) = Amp;
	c = c+1;
end

% convert to dB
FRvec = 20*log10(FRvec);

% plot the frequency response
figure(1)
semilogx(freq_vec, FRvec, 'r', 'LineWidth', 2)
grid on
xlim([min(freq_vec) max(freq_vec)])
ylim([min(FRvec)-10 10])
%set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
xlabel('Frequency, Hz')
ylabel('Magnitude, dB')
title(title_)

%pause(120)

%bode(frequency_response)
%legend('AD1938 Prototype')
print frequency_response.pdf
print -dfig frequency_response.fig
print -dpng frequency_response.png
