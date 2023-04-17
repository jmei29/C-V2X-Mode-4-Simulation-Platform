clc;
clear;
vehicle_speed=70;
sample_tra_len = 16;
openfile = sprintf('../../Data/data_deploy/node_deployment_Freeway_parameters_vehicle_speed=%d.mat',vehicle_speed);
load(openfile, 'drop_num', 'sub_drop_num');
numFrame = 100;% number of simulation frame of ervery subdrop
period_safety_serv = 50; % 50 sub-frames for safet related service
period_auto_serv = 25; % 10 sub-frames for automobile service
record_pak_num = (sample_tra_len*sub_drop_num*numFrame)/period_auto_serv;
%% DRQN Scheme
if 1
    CASE_IDX = 6;
    File_ULC_index_Min = 1;
    File_ULC_index_Max = 99;%Max_num;
    openfile_str = '../../Data/Result_DRQN/V2V_single_cell_speed%d_Sample%d_DRQN_Case_%d.mat';
    [ALL_CDF_Reward_DRQN,ALL_Seg_Array_Reward_DRQN,cdf_S_PDR_DRQN, PDR_S_DRQN,cdf_A_PDR_DRQN, PDR_A_DRQN,...
        Reward_Result_DRQN, PDR_avg_Result_DRQN] ...
        = get_Result_fun(openfile_str, File_ULC_index_Min, File_ULC_index_Max, vehicle_speed, CASE_IDX, sample_tra_len);
    [cdf_S_delay_DRQN, delay_S_DRQN,cdf_A_delay_DRQN, delay_A_DRQN, Delay_Result_DRQN] ...
        = get_Result_Delay_fun(openfile_str, File_ULC_index_Min, File_ULC_index_Max, vehicle_speed, CASE_IDX, sample_tra_len, record_pak_num);
end
%% PRO
if 1
    CASE_IDX = 6;
    File_ULC_index_Min = 1;
    File_ULC_index_Max = 99;%Max_num;
    openfile_str = '../../Data/Result_DRL_Propose/V2V_single_cell_speed%d_Sample%d_Proposed_DRL_v4_1_Case_%d.mat';
    [ALL_CDF_Reward_PRO,ALL_Seg_Array_Reward_PRO,cdf_S_PDR_PRO, PDR_S_PRO,cdf_A_PDR_PRO, PDR_A_PRO,...
        Reward_Result_PRO, PDR_avg_Result_PRO] ...
        = get_Result_fun(openfile_str, File_ULC_index_Min, File_ULC_index_Max, vehicle_speed, CASE_IDX, sample_tra_len);
    [cdf_S_delay_PRO, delay_S_PRO,cdf_A_delay_PRO, delay_A_PRO, Delay_Result_PRO] ...
        = get_Result_Delay_fun(openfile_str, File_ULC_index_Min, File_ULC_index_Max, vehicle_speed, CASE_IDX, sample_tra_len, record_pak_num);
end
%%
Reward_Compare = zeros(1, 2);
Reward_Compare(1) = mean(Reward_Result_PRO{1,1});
Reward_Compare(2) = mean(Reward_Result_DRQN{1,1});
delay_avg_S1 = zeros(1,2);
delay_avg_S1(1) = mean(Delay_Result_PRO{1,1});
delay_avg_S1(2) = mean(Delay_Result_DRQN{1,1});
delay_avg_S2 = zeros(1, 2);
delay_avg_S2(1) = mean(Delay_Result_PRO{1,2});
delay_avg_S2(2) = mean(Delay_Result_DRQN{1,2});
PDR_avg_S1 = zeros(1, 2);
PDR_avg_S1(1) = mean(PDR_avg_Result_PRO{1,1});
PDR_avg_S1(2) = mean(PDR_avg_Result_DRQN{1,1});
PDR_avg_S2 = zeros(1, 2);
PDR_avg_S2(1) = mean(PDR_avg_Result_PRO{1,2});
PDR_avg_S2(2) = mean(PDR_avg_Result_DRQN{1,2});
%%
if 1
    figure(1)
    plot(ALL_Seg_Array_Reward_DRQN,ALL_CDF_Reward_DRQN, '--',...
        ALL_Seg_Array_Reward_PRO, ALL_CDF_Reward_PRO, 'b-');%,...
    legend('DRQN', 'PRO')
    figure(2)
    plot(PDR_S_DRQN, cdf_S_PDR_DRQN, '--',...
        PDR_S_PRO, cdf_S_PDR_PRO, 'b-');
    legend('DRQN', 'PRO')
    title('Safety')
    figure(3)
    plot(PDR_A_DRQN, cdf_A_PDR_DRQN, '--',...
        PDR_A_PRO, cdf_A_PDR_PRO, 'b-');
    legend('DRQN', 'PRO')
    title('Auto')
    figure(4)
    plot(delay_S_DRQN, cdf_S_delay_DRQN, '--',...
        delay_S_PRO, cdf_S_delay_PRO, 'b-');
    legend('DRQN', 'PRO')
    title('Safety')
    figure(6)
    plot(delay_A_DRQN, cdf_A_delay_DRQN, '--',...
        delay_A_PRO, cdf_A_delay_PRO, 'b-');
    legend('DRQN', 'PRO')
    title('Auto')
end

