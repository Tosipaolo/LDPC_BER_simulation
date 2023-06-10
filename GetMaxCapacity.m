function [min_snr, min_EbN0] = GetMaxCapacity(snr,M, rate)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

C = zeros(size(snr));

for i = 1:length(snr)
    C(i) = QAMCapacity(snr(i),1,M);
end


min_snr = interp1(C, snr, rate);

min_EbN0 = min_snr - 10 * log10(rate);

end

