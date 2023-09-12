close all; clear;

[files, path] = uigetfile("../saves/", "Seleziona file da plottare", "MultiSelect","on");


%% parameters
colors = jet(numel(files));
ebn0_interval = -2:0.5:12;
M = 4;

%% init plots
Ber_axes = axes(figure("Name","BER"));

semilogy(Ber_axes, ebn0_interval, berawgn(ebn0_interval, "psk", M, "nondiff"), "--", "Color","Black", "DisplayName","uncoded");
hold(Ber_axes, "on");
grid(Ber_axes, "on");

EbN0_lowest_BER = zeros(1,numel(files));
R = zeros(1,numel(files));

%% plot saved simulations
for ii = 1:numel(files)
    file = string(files(ii));
    load(fullfile(path, file));
    ber_string = ['BER @ r=' strtrim(rats(r))];
    semilogy(Ber_axes, EbNo, BER, 'Marker','x', 'Color', colors(ii,:));
    snr_interval = -6:0.1:10;
    [~, lower_bound_ebn0_db] = GetMaxCapacity(snr_interval, M, r);
    shannon_bound_string = ['shannon limit @ r=' strtrim(rats(r))];
    semilogy(Ber_axes, ones(1,2)*lower_bound_ebn0_db, [1 1e-8], '--', 'Color',colors(ii,:), 'DisplayName',shannon_bound_string);

    EbN0_lowest_BER(ii) = EbNo(end);
    R(ii) = r;

end
%% Coding gain at Pe=1e-6

coding_Gain =  uncoded_EbN0_lowestBER - EbN0_lowest_BER;

figure(Name="Coding Gain");
scatter(R, coding_Gain,[],colors, "filled", "o");
grid on;
xlabel('Coding Rate');
ylabel('Coding Gain [dB]');
xlim([0 1]);
ylim([4 9]);

%% Net Coding Gain

BERin = berawgn(EbN0_lowestBER,'psk', M, 'nondiff');

NCG = 20*log10(erfcinv(2*BERout)) - 20*log10(erfcinv(2*BERin)) + 10*log10(R);
figure(Name="Net Coding Gain");

scatter(R, NCG,[],colors, "filled", "o");

grid on;
xlabel('Coding Rate');
ylabel('Net Coding Gain [dB]');
xlim([0 1]);
ylim([4 9]);


%% System Reach

fiber_att = 0.2; %dB/Km

figure(Name="Optical reach increase")

scatter(R, coding_Gain./fiber_att,[], colors, "filled", "o");
grid on;
xlabel('Coding Rate');
ylabel('Reach increase [Km]');
xlim([0 1]);
ylim([20 50]);