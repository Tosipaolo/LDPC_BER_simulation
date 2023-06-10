close all;
clear;

snr = -3:0.1:5;
C = zeros(size(snr));
for i = 1:length(snr)
    C(i) = QAMCapacity(snr(i),1,2);
end
plot(snr, C);

r = 5/6;

min_snr = interp1(C, snr, r)

min_EbN0 = min_snr - 10 * log10(r)
