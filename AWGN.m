clear;
close all;

%Rate range
R = [1/2 5/6 8/9 9/10];
% 1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 5/6, 8/9, or 9/10.

% Range EB/N0

% Modulation Constellation
%   M = 2 -> BPSK
M = 2;

ebn0_interval = -2:0.5:10.5;


%% Transmission Limits
% Uncoded BER
figure();
semilogy(ebn0_interval, berawgn(-2:0.5:10.5, "psk", 2, "nondiff"));
xlabel('Eb/N0 [dB]');
ylabel('Probability of error');
hold on;

% Ultimate Shannon limit, max capacity
semilogy(ones(1,2)*(-1.59), [1 1e-6], '--', 'Color','black');
drawnow;

%% Coded Transmission

for r = R
    
    snr_interval = -6:0.1:10; % interval for the GetMaxCapacity interpolation
    [limit_snr, limit_ebn0_db] = GetMaxCapacity(snr_interval, M, r);
    fprintf("RATE: %s, Eb/N0: %.3f dB\n", strtrim(rats(r)), limit_ebn0_db);
    semilogy(ones(1,2)*limit_ebn0_db, [1 1e-6], '--');
    BER = [];
    EbNo = [];
    
    % LDPC configurations
        
    ParityMatrix = dvbs2ldpc(r);
    
    cfg_E = ldpcEncoderConfig(ParityMatrix);
    cfg_D = ldpcDecoderConfig(cfg_E);
    
    
    % Iteration configurations
    
    Numbits = 1e6;
    NumBlocks = ceil(Numbits/cfg_E.NumInformationBits);
    Numbits = cfg_E.NumInformationBits*NumBlocks;

    snr_db = limit_snr - 0.01;

    while(isempty(BER) || BER(end) > 1e-6)
        fprintf(".");

        limit_ebn0_db = snr_db - 10*log10(r) - 10*log10(log2(M));
        EbNo = [EbNo limit_ebn0_db];

        
        bitstosend = randi([0 1],cfg_E.NumInformationBits,NumBlocks);
        
        %bitstosend = ones(Numbits,1);
        max_iterations = 50;
        
        % Encoder LDPC
        encoded_bits = ldpcEncode(bitstosend,cfg_E);
        
        % PSk Mod
        PSK_mod = pskmod(encoded_bits,M);
        
        % AWGN Channel
        NoisySignal = awgn(PSK_mod,snr_db);
        
        % PSK Demod
        PSK_demod = pskdemod(NoisySignal,M,'OutputType','llr');
        
        % Decoder LDPC
        decoded_bits = ldpcDecode(PSK_demod,cfg_D,max_iterations,"DecisionType","soft");
        
        %% Performance eval
        
        Numerrors = sum(bitstosend ~= (decoded_bits < 0),"all");
        
        BER = [BER Numerrors/Numbits];

        snr_db = snr_db + 0.1;
    
    end

    semilogy(EbNo, BER, 'Marker','x');
    fprintf("\n");
    fprintf("End at %.3f dB\n", EbNo(end));
    drawnow;
end




