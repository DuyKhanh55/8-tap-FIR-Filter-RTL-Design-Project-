clc;
clear;
close all;

%% Specification

N = 7;              % 8 taps
fs = 48000;         % Sample rate (Hz)
fc = 6000;          % Cut-off frequency (Hz)
Q = 15;             % Q1.15
DATA_WIDTH = 12;    % Input width

%% FIR Design

Wn = fc/(fs/2);
h = fir1(N,Wn);

disp("Floating-point coefficients:");
disp(h);

%% Quantization (Q1.15)

coeff_fixed = round(h*(2^Q));

disp("Q1.15 coefficients:");
disp(coeff_fixed);

writematrix(coeff_fixed','coefficients.txt');

%% Generate Input Samples

num_samples = 500;
t = (0:num_samples-1)/fs;

f_signal = 2000;
f_noise  = 15000;

max_val = 2^(DATA_WIDTH-1)-1;

x = 0.6*sin(2*pi*f_signal*t) + ...
    0.3*sin(2*pi*f_noise*t);

x_fixed = round(x*max_val);

writematrix(x_fixed','input_samples.txt');

%% Expected Output

y_ref = filter(h,1,x_fixed);
y_fixed = round(y_ref*(2^Q));

writematrix(y_fixed','expected_output.txt');

%% Impulse Response

figure;
stem(h,'filled');
grid on;
title("Impulse Response");
xlabel("Tap Index");
ylabel("Amplitude");

%% Frequency Response

figure;
freqz(h,1);
