clear;
close all;

%Rate range
R = [4/5, 8/9];
% 1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 5/6, 8/9, or 9/10. copy paste:
%1/4 *1/3 *2/5 *1/2 3/5 2/3 3/4 4/5 *5/6 *8/9 9/10

%Plot colours (rainbow palette, 11 colours)
%colors = ["#ff0000" "#ff8700" "#ffd300" "#deff0a" "#a1ff0a" "#0aff99" "#0aefff" "#147df5" "#580aff" "#be0aff" "#571089"];
colors = jet(length(R));

% Modulation Constellation
%   M = 2 -> BPSK
M = 4;

% Range EB/N0
ebn0_interval = -2:0.5:12;
EbN0_lowestBER = [];

BERout = 1e-6;


discretize_signal = true;
discrete_bits = 5;


% precision limit on snr increment
precision = 1e-4;

%% Transmission Limits
% Uncoded BER
figure();
semilogy(ebn0_interval, berawgn(ebn0_interval, "psk", M, "nondiff"));
grid on;
xlabel('Eb/N0 [dB]');
ylabel('Probability of error');
hold on;

uncoded_EbN0_lowestBER = interp1(berawgn(ebn0_interval, "psk", M, "nondiff"),ebn0_interval, BERout);

% Ultimate Shannon limit, max capacity
semilogy(ones(1,2)*(-1.59), [1 1e-6], '--', 'Color','black');
drawnow;

%% Coded Transmission

color_index=1;
for r = R
    
    snr_interval = -6:0.1:10; % interval for the GetMaxCapacity interpolation
    [limit_snr, limit_ebn0_db] = GetMaxCapacity(snr_interval, M, r);
    fprintf("RATE: %s, Eb/N0: %.3f dB\n", strtrim(rats(r)), limit_ebn0_db);
    semilogy(ones(1,2)*limit_ebn0_db, [1 1e-6], '--', 'Color',colors(color_index,:));
    BER = [];
    EbNo = [];
    base_increment = 0.1;
    
    % LDPC configurations
        
    ParityMatrix = dvbs2ldpc(r);
    
    cfg_E = ldpcEncoderConfig(ParityMatrix);
    cfg_D = ldpcDecoderConfig(cfg_E);
    
    
    % Iteration configurations
    
    Numbits = 1e6;
    NumBlocks = ceil(Numbits/cfg_E.NumInformationBits);
    Numbits = cfg_E.NumInformationBits*NumBlocks;

    % number of repetitions of the simulation for every r and snr
    repetition = ceil(10/(Numbits*BERout));

    snr_db = limit_snr - 0.01;

    while(isempty(BER) || BER(end) > BERout)
        Numerrors = 0;

        for iter = 1:repetition
            fprintf(".");
    
            limit_ebn0_db = snr_db - 10*log10(r) - 10*log10(log2(M));    
            
            bitstosend = randi([0 1],cfg_E.NumInformationBits,NumBlocks,"logical");
            
            %bitstosend = ones(Numbits,1);
            max_iterations = 20;
           
            % Encoder LDPC
            encoded_bits = ldpcEncode(bitstosend,cfg_E);
            
            % PSk Mod
            PSK_mod = pskmod(encoded_bits,M,'InputType','bit');
            
            % AWGN Channel
            NoisySignal = awgn(PSK_mod,snr_db);

            % Signal Discretisation
            if(discretize_signal)
                bins = linspace(-1-sqrt((1/10^(snr_db/10))), 1+sqrt((1/10^(snr_db/10))), 2^discrete_bits);

                discrete_signal_real = interp1(bins, bins, real(NoisySignal), "nearest", "extrap");
                discrete_signal_imag = interp1(bins, bins, imag(NoisySignal), "nearest", "extrap");
                discrete_signal = complex(discrete_signal_real, discrete_signal_imag);
                NoisySignal = discrete_signal;
            end
            
            % PSK Demod
            PSK_demod = pskdemod(NoisySignal,M,'OutputType','llr','NoiseVariance',1/10^(snr_db/10));
            
            % Decoder LDPC
            decoded_bits = ldpcDecode(PSK_demod,cfg_D,max_iterations,"DecisionType","soft");
            
            % Performance eval
            
            Numerrors = Numerrors + sum(bitstosend ~= (decoded_bits < 0),"all");

        end

        if (Numerrors == 0 && base_increment >= precision)
            snr_db = snr_db - base_increment;
            base_increment = base_increment/10;
            fprintf("\n");
        else
            BER = [BER Numerrors/(prod(size(bitstosend),'all')*repetition)];
            EbNo = [EbNo limit_ebn0_db];
        end
        snr_db = snr_db + base_increment;
        
    end
    
    EbN0_lowestBER = [EbN0_lowestBER EbNo(end)];
    semilogy(EbNo, BER, 'Marker','x', 'Color', colors(color_index,:));
    fprintf("\n");
    fprintf("End at %.3f dB\n", EbNo(end));
    drawnow;
    color_index = rem(color_index, length(colors)) +1;

    %NCG
    Numerrors_in = sum( encoded_bits ~= (PSK_demod < 0), 'all');
    BERin = [BER Numerrors_in/prod(size(encoded_bits), 'all')]; %BERin number of errors in input at FEC decoder


    file_name = strcat(string(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss')), '_BER@r=', num2str(r));
    if(discretize_signal)
        file_name = strcat(file_name, '_discrete@', num2str(discrete_bits), '_bits');
    end
    file_name = strcat(file_name, '.mat');
    
    [~, ~] = mkdir('saves');
    save(fullfile('saves', file_name),"r","M","discretize_signal","discrete_bits","BERin","BERout","BER","EbNo","limit_snr","limit_ebn0_db", "uncoded_EbN0_lowestBER","EbN0_lowestBER");
end

%% Coding gain at Pe=1e-6

coding_Gain =  uncoded_EbN0_lowestBER - EbN0_lowestBER;

figure(Name="Coding Gain");
scatter(R, coding_Gain,[],colors, "filled", "o");
grid on;
xlabel('Coding Rate');
ylabel('Coding Gain [dB]');
xlim([0 1]);
ylim([5 10]);

%% Net Coding Gain

BERin = berawgn(EbN0_lowestBER,'psk', M, 'nondiff');

NCG = 20*log10(erfcinv(2*BERout)) - 20*log10(erfcinv(2*BERin)) + 10*log10(R);
figure(Name="Net Coding Gain");

scatter(R, NCG,[],colors, "filled", "o");

grid on;
xlabel('Coding Rate');
ylabel('Net Coding Gain [dB]');
xlim([0 1]);
ylim([5 10]);


%% System Reach

fiber_att = 0.2; %dB/Km

figure(Name="Optical reach increase")

scatter(R, coding_Gain./fiber_att,[], colors, "filled", "o");
grid on;
xlabel('Coding Rate');
ylabel('Reach increase [Km]');
xlim([0 1]);
ylim([25 50]);

