#! /usr/bin/octave -qf
%
% Crosstalk calculation
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
audiofile = arg{1};
Fs = str2num(arg{2});
audiolength = str2num(arg{3}); % in seconds

input_signal = wavread(audiofile);
left = input_signal(:,1);
right = input_signal(:,2);
N = length(left);
t = 0:1/Fs:audiolength-1/Fs;
freq = Fs*(0:(N/2))/N;
freq_500_index = find(freq==500);
freq_1500_index = find(freq==1500);

Y_left = fft(left);
P2_left = abs(Y_left/N);
P1_left = P2_left(1:N/2+1);
P1_left(2:end-1) = 2*P1_left(2:end-1);
[max_left, i_left] = max(P1_left(freq_500_index:length(freq))); % Search for index of maximum from 500Hz
i_left = i_left + freq_500_index - 1;

Y_right = fft(right);
P2_right = abs(Y_right/N);
P1_right = P2_right(1:N/2+1);
P1_right(2:end-1) = 2*P1_right(2:end-1);
[max_right, i_right] = max(P1_right(freq_500_index:length(freq)));
i_right = i_right + freq_500_index - 1;

crosstalk = 20*log10(max_left) - 20*log10(max_right);
printf("%f", crosstalk);

figure(1);
clf();
plot(freq,20*log10(P1_left), freq,20*log10(P1_right), freq(i_left),20*log10(max_left),'+r', freq(i_right),20*log10(max_right), '+r');
strmax = [num2str(20*log10(max_left)), ' dBFS'];
text(freq(i_left),20*log10(max_left),strmax,'HorizontalAlignment','left');
strmax = [num2str(20*log10(max_right)), ' dBFS'];
text(freq(i_right),20*log10(max_right),strmax,'HorizontalAlignment','left');
line()
grid on
title('Left and right channel inputs with -1dBFS signal output on left channel only')
xlabel('Frequency (Hz)')
ylabel('Amplitude (dBFS) ')
legend('left channel', 'right channel')
print crosstalk.pdf
print -dfig crosstalk.fig
print -dpng crosstalk.png

pause(10)
