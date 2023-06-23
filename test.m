close all;
clear;



snr = -6:0.1:15;
C = zeros(size(snr));
for i = 1:length(snr)
    C(i) = QAMCapacity(snr(i),1,4);
end
plot(snr, C);

r = 5/6;

min_snr = interp1(C, snr, r)

min_EbN0 = min_snr - 10 * log10(r)

