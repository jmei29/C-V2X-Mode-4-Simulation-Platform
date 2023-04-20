%% System initilization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation Settings: LOAD SET OF configuration
openfile = sprintf('../simualtion_parameters.mat');
load(openfile);
%% Load files FOR MATLAB
if scenario_kind == 2
    openfile = sprintf('../Data/data_deploy/node_deployment_Freeway_parameters_vehicle_speed=%d.mat',vehicle_speed);
    load(openfile, 'drop_num', 'sub_drop_num');
    numFrame = 100;% number of simulation frame of ervery subdrop
end
drop_num_simu = drop_num; % one drop
sample_tra_len = drop_num_simu; % the length of sample trajectory
VUE_ant_gain = 3; %dBi
Auto_VUE_Tx_pow = 10^(20/10); %in mW
Safety_VUE_Tx_pow = 10^(20/10); % in mW
%% C-V2X MODE 4 FIXED PARAMETERS
Re_selection_prob = [0.1,0.1];
% Packet size
pak_bits_safey = 2400;
%in bits, the average packet length is 300 Bytes
pak_bits_auto = 1600;
%in bits, constant size of automobile related service is 200 Bytes
Max_active_VUE_num = 400;
period_safety_serv = 100; % 100 sub-frames for safet related service
period_auto_serv = 25; % 10 sub-frames for automobile service
record_pak_num = (sample_tra_len*sub_drop_num*numFrame)/period_auto_serv; 
% the maximum number of packets to be recorded
%% OFDM system configuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DL = 1; % 1:DL;else:UL
VUE_Tx_antenna_num = 1; % tx
VUE_Rx_antenna_num = 1; % rx   %!!!!!!!!!!!!!!!!!!!
CUE_Tx_antenna_num = 1; % tx
CUE_Rx_antenna_num = 1; % rx
carrier_frequency = 5.9*1e9; % 2GHz
subcarrier_spacing = 15e3; % 15kHz
subcarrier_per_RB = 12;
bandwidth = 2e7; % 20MHz    %!!!!!!!!!!!!!!!!!!!!!!
Rician_fading_factor = 9;
mcs_kind_num = 6; % there are 29 kinds of MCSs
bits_per_RB = [56 120 208 280 408 502];
% 1RB each block for MCS index 1 to 29 delete pilot
noise_density = -140;% dBm/Hz
noise_power_per_sc = noise_density+10*log10(subcarrier_spacing); % dBm
noise_power_mw_per_sc = 10.^(noise_power_per_sc./10); % mw
