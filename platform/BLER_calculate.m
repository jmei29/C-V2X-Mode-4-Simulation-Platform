function erro_rate = BLER_calculate(SINR,MCS_kind)
%% input
% SINR: the SINR value at the receiver side (not in dB)
% MCS_kind: the chosen MCS
%% output
% The minimum constant data rate in bits/slot
% Write by MJ, 2016-08-16
a = [4.194 5.521 8.013 16.7 12.7 15.12];
b = [3.133 1.521 0.947 0.6359 0.2964 0.1211];
SINR_thread = [-3.395 0.505 3.419 6.462 9.332 13.508]; % in dB
if SINR<10^(SINR_thread(MCS_kind)/10)
    erro_rate = 1;
else
    erro_rate = a(MCS_kind)*exp(-b(MCS_kind)*SINR);
end 