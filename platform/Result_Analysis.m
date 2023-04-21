tic; % clacluate the time
clc
clear
System_Initialization_C_V2X_Mode4;
%%
episode = 1;
sample_num = 1;
%% Data Record
SINR_sc_record_all = [];
Congestion_Ratio_record_all = [];
Packet_drop_ratio_record_all = [];
Packet_delay_record_all = [];
Collision_Ratio_record_all = [];
%% Collecting data
while 1
    if episode >= MAX_epsiode
        break
    end
    openfile = sprintf('../Data/Result/V2V_Mode_4_speed%d_drop%d_Sample%d_Case_%d.mat',...
        vehicle_speed, sample_num, CASE_IDX);
    load(openfile, 'Data_rate_record', 'SINR_sc_record', 'VUE_Rx_CIR_per_sc_record',...
        'SubCH_choice','Collision_Ratio_record','Congestion_Ratio_record',...
        'delay_per_pak','PDR_active_VUE','Delay_1','PDR_1');
    for loop_sub_drop = 1 : sub_drop_num
        Congestion_Ratio_record_all = [Congestion_Ratio_record_all; ...
            Congestion_Ratio_record{loop_sub_drop, 1}];
        Collision_Ratio_record_all = [Collision_Ratio_record_all; ...
            Collision_Ratio_record{loop_sub_drop, 1}(:,3)];
        Packet_drop_ratio_record_all = [Packet_drop_ratio_record_all; PDR_1(:)];
        Packet_delay_record_all = [Packet_delay_record_all; Delay_1(:)];
    end
    SINR_sc_record_all = [SINR_sc_record_all; SINR_sc_record{1, 1}(:)];
    SINR_sc_record_all = SINR_sc_record_all(SINR_sc_record_all > 0);
    %% Renew episode/File_index number
    episode = episode + 1; % calculate the number of episodes
    sample_num = sample_num + 1; % calculate the number of samples
end % end of while
%%
fprintf('Case Index = %d, Average SINR per Subcarrier = %f dB.\n', CASE_IDX, 10*log10(mean(SINR_sc_record_all)));
fprintf('Case Index = %d, Average Congestion Ratio = %f dB.\n', CASE_IDX, mean(Congestion_Ratio_record_all(:)));
fprintf('Case Index = %d, Average Collision Ratio = %f dB.\n', CASE_IDX, mean(Collision_Ratio_record_all(:)));
fprintf('Case Index = %d, Average Packet Drop Ratio = %f dB.\n', CASE_IDX, mean(Packet_drop_ratio_record_all(:)));
fprintf('Case Index = %d, Average Packet Delay = %f dB.\n', CASE_IDX, mean(Packet_delay_record_all(:)));