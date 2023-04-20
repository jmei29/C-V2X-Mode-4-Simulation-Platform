clear all;
clc;
%% Revised by Jie Mei 20200523
% V1.2 3GPP 36.885
%% Scenario Parameters set
openfile = sprintf('../simualtion_parameters.mat');
load(openfile, 'scenario_kind', 'vehicle_speed');
% scenario_kind,Urban case=1, Freeway case=2,
small_fading_on_off=0;
occupied_subcarrier_deploy = 600; %10MHz
V2V_range=200; % Urban case V2V communcation range
VUE_antenna_num_Tx = 1; %tx
VUE_antenna_num_Rx = 1; % rx
center_frequency = 5.9*1e9; % 5.9 GHz
subcarrier_spacing = 15e3; % 15kHz
%% Parameters of channel model
if scenario_kind == 2
    openfile = sprintf('../Data/data_deploy/node_deployment_Freeway_parameters_vehicle_speed=%d.mat',vehicle_speed);
end
load(openfile);
direction_angle=[90 180 270 0];%VUE direction(=1 North,2 West,3 South,4 East)
for loop_drop=1 :  drop_num
    VUE2VUE_Large_scale_fading_all = cell(sub_drop_num, 1);
    V2V_channel_gain_per_RB_all = cell(sub_drop_num, 1);
    for sub_snapshot=1 : sub_drop_num
        %% load nodedeployment information'
        if scenario_kind == 2
            openfile = sprintf('../Data/data_deploy/node_deployment_Freeway_vehicle_speed=%d_No%d_subdrop_ID%d.mat',vehicle_speed,...
                loop_drop,sub_snapshot);
            load(openfile,'Total_VUE_num','VUE_info','Shadowing_VUE2VUE_LOS','Shadowing_VUE2VUE_NLOS','Distance_VUE2VUE',...
                'MeNB_loca','VUE_loca_WRAP');
        end
        fprintf('V2V and V2C channel generation: drop=%d, subdrop=%d.\n',loop_drop,sub_snapshot);
        %% 2016-05-19 define VUE and CUE channel data
        % VUE2VUE channel
        VUE2VUE_Large_scale_fading=single(zeros(Total_VUE_num, Total_VUE_num));
        %% channel generation of VUE2VUE
        for VUE_Tx_idx = 1: Total_VUE_num
            VUE_Tx_loca=VUE_info(VUE_Tx_idx,1);
            bs_direction= direction_angle(VUE_info(VUE_Tx_idx,2));
            if VUE_info(VUE_Tx_idx,2) == 2 || VUE_info(VUE_Tx_idx,2) == 4
                VUE2VUE_direction_flag=0;
            else
                VUE2VUE_direction_flag=1;
            end
            %% VUE Large scale fading
            for VUE_Rx_idx = 1: Total_VUE_num
                if  VUE_Rx_idx == VUE_Tx_idx
                    continue
                end
                fprintf('VUE_Tx_index=%d.\n',VUE_Tx_idx);
                if scenario_kind == 1
                    VUE_Rx_loca=VUE_info(VUE_Rx_idx,1);
                else
                    VUE_Rx_loca=VUE_loca_WRAP(VUE_Tx_idx,VUE_Rx_idx);
                end
                [ PL_dB , SF_std ] = Pathloss_SF_V2V_ver1(scenario_kind,center_frequency,VUE_Tx_loca,...
                    VUE_Rx_loca,VUE2VUE_direction_flag);
                if SF_std==3 %LOS
                    shadow_fading = Shadowing_VUE2VUE_LOS(VUE_Tx_idx, VUE_Rx_idx);
                elseif SF_std==4 %NLOS
                    shadow_fading = Shadowing_VUE2VUE_NLOS(VUE_Tx_idx, VUE_Rx_idx); %loop_VUE_Rx);
                end
                temp_dB = - shadow_fading - PL_dB;
                % convert to linear value in mW
                temp = 10^(temp_dB/10);
                VUE2VUE_Large_scale_fading(VUE_Tx_idx, VUE_Rx_idx) = temp; %默认只有一个接收端存在
            end
        end %end of VUE_Tx_index
        %% save channel data every Tx VUE
        VUE2VUE_Large_scale_fading_all{sub_snapshot,  1} = VUE2VUE_Large_scale_fading;
    end % end of subsnapshot
    if exist('../Data/channel_storage', 'dir') == 0
        mkdir('../Data/channel_storage');
    end
    if scenario_kind == 2
        savefile = sprintf('../Data/channel_storage/slowfading_V2V_V2C_Freeway_vehicle_speed=%d_No%d.mat',...
            vehicle_speed,loop_drop);
    end
    save(savefile, 'VUE2VUE_Large_scale_fading_all');
end% end of loop_drop