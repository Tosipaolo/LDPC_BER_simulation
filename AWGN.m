clear;
close all;

%Rate range
R = [2/5 5/6 9/10];
% 1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 5/6, 8/9, or 9/10.

% Range EB/N0


figure();
semilogy(-2:0.5:10.5, berawgn(-2:0.5:10.5, "psk", 2, "nondiff"));
xlabel('Eb/N0 [dB]');
ylabel('Probability of error');
hold on;
semilogy(ones(1,2)*(-1.59), [1 1e-6], '--', 'Color','black');
drawnow;
for r = R
    ebn0 = (2^(2*r)-1)/(2*r);

    semilogy(ones(1,2)*10*log10(ebn0), [1 1e-6], '--');
    BER = [];
    EbNo = [];

    ebn0 = ebn0 - 0.1;
    
    while(isempty(BER) || BER(end) > 1e-6)
        fprintf(".");

        snr = ebn0 *r;

        snr_db = 10*log10(snr);
        ebn0_db = 10*log10(ebn0);

        EbNo = [EbNo ebn0_db];

        % LDPC configurations
        
        ParityMatrix = dvbs2ldpc(r);
        
        cfg_E = ldpcEncoderConfig(ParityMatrix);
        cfg_D = ldpcDecoderConfig(cfg_E);
        
        
        % Iteration configurations
        
        Numbits = 1e6;
        NumBlocks = ceil(Numbits/cfg_E.NumInformationBits);
        Numbits = cfg_E.NumInformationBits*NumBlocks;
        
        bitstosend = randi([0 1],cfg_E.NumInformationBits,NumBlocks);
        
        %bitstosend = ones(Numbits,1);
        max_iterations = 50;
        
        % Errors per iteration (?)
        
        %Modulation Order QAM
            % 2 -> BPSK
        M = 2;
        
        %Block Lenght
        
        %Infobits
        
        % Encoder LDPC
        encoded_bits = ldpcEncode(bitstosend,cfg_E);
        
        % PSk Mod
        PSK_mod = pskmod(encoded_bits,M,'InputType','bit','PlotConstellation', false);
        
        % AWGN Channel
        NoisySignal = awgn(PSK_mod,snr_db);
        
        % PSK Demod
        PSK_demod = pskdemod(NoisySignal,M,'OutputType','llr');
        
        % Decoder LDPC
        decoded_bits = ldpcDecode(PSK_demod,cfg_D,max_iterations,"DecisionType","soft");
        
        %% Performance eval
        
        Numerrors = sum(bitstosend ~= (decoded_bits < 0),"all");
        
        BER = [BER Numerrors/Numbits];

        ebn0 = ebn0 + 0.1;
    
    end

    semilogy(EbNo, BER, 'Marker','x');
    fprintf("\n");
    drawnow;
end




