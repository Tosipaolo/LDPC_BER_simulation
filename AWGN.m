clear;
close all;

%Rate range
%R = [1/4, ...];
r = 1/4;

% Range EB/N0
EbNo = 1:12;
snr = -10;


% LDPC configurations

ParityMatrix = dvbs2ldpc(r);

cfg_E = ldpcEncoderConfig(ParityMatrix)
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

% QAM Mod
QAM_mod = qammod(encoded_bits,M,'InputType','bit','PlotConstellation', false);

% AWGN Channel
NoisySignal = awgn(QAM_mod,snr);

% QAM Demod
QAM_demod = qamdemod(NoisySignal,M,'OutputType','llr');

% Decoder LDPC
decoded_bits = ldpcDecode(QAM_demod,cfg_D,max_iterations,"DecisionType","soft");

%% Performance eval

Numerrors = sum(bitstosend ~= (decoded_bits < 0),"all");

BER = Numerrors/Numbits





