clear;
close all;

%Rate range
R = [5/6];


% Range EB/N0
EbNo = 2.5:0.1:3;

figure();
semilogy(1:0.5:12, berawgn(1:0.5:12, "psk", 2, "nondiff"));
hold on;
for r = R
    semilogy(ones(1,2)*(2^(2*r)-1)/r, [1 1e-6], '--');
     BER = [];
    for ebn0 = EbNo
        fprintf(".");
        
        snr = ebn0 * r;
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
        NoisySignal = awgn(PSK_mod,snr);
        
        % PSK Demod
        PSK_demod = pskdemod(NoisySignal,M,'OutputType','llr');
        
        % Decoder LDPC
        decoded_bits = ldpcDecode(PSK_demod,cfg_D,max_iterations,"DecisionType","soft");
        
        %% Performance eval
        
        Numerrors = sum(bitstosend ~= (decoded_bits < 0),"all");
        
        BER = [BER Numerrors/Numbits];
    
    end

    semilogy(EbNo, BER);
end
fprintf("\n");



