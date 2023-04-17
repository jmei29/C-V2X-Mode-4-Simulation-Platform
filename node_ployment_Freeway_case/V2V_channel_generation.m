clear all;
clc;
%% Scenario Parameters set
scenario_kind=2;% scenario_kind,Urban case=1, Freeway case=2,
vehicle_speed = 70;%Absolute vehicle speed is 15 or 60 km/h
channel_on_off=1;%0->???????????? 1->????????
numFrame = 100;% number of simulation frame
occupied_subcarrier_deploy = 600; %10MHz
VUE_TxPow = 23;  % in dBm
VUE_ant_pat=3; % in dB
VUE_antenna_num_Tx = 1; %tx
VUE_antenna_num_Rx = 2; % rx
carrier_frequency = 2e9; % 2GHz for PC5 interface
subcarrier_spacing = 15e3; % 15kHz
SampleFreq=15.36e6;    %Sample Frequency
bandwidth = 10e6; % 10MHz
FFT_length = 1024;
CP_length = 72;
occupied_subcarrier = 600;
subcarrier_per_RB = 12;
occupied_subcarrier_index = [CP_length+(FFT_length-occupied_subcarrier)/2:CP_length+(FFT_length-occupied_subcarrier)/2+occupied_subcarrier/2-1,...
    CP_length+(FFT_length-occupied_subcarrier)/2+occupied_subcarrier/2+1:CP_length+(FFT_length-occupied_subcarrier)/2+occupied_subcarrier];
RB_per_subframe = 50;
Tb = 1/subcarrier_spacing;
Tg = Tb*(CP_length/FFT_length);
symbol_duration = Tb+Tg;
symbol_length = FFT_length+CP_length;
symbol_per_subframe = 14;
Sample_duration = 1/SampleFreq;
subframe_duration = symbol_duration*symbol_per_subframe;
subframe_length = symbol_length*symbol_per_subframe;
%% Parameters of channel model
if scenario_kind == 1
    openfile = sprintf('../node_deployment/data_deploy/node_deployment_Urban_parameters_vehicle_speed=%d.mat',vehicle_speed);
else
    openfile = sprintf('../node_deployment/data_deploy/node_deployment_Freeway_parameters_vehicle_speed=%d.mat',vehicle_speed);
end
load(openfile);
scenario=2;                                             % 1:UMa          2:UMi
los_flag=0;                                             % 0:NLOS         1:LOS
if los_flag == 0
    path_delay_num = 23;
else
    path_delay_num = 16;
end
ms_indoor_flag=0;                                       % 0:Outdoor      1:O-to-I
center_frequency=carrier_frequency;
dt=Sample_duration;
bs_bearing_angle=0;
bs_downtilt_angle=0;
bs_slant_angle=0;
bs_num_antenna_h=VUE_antenna_num_Tx;
bs_num_antenna_v=1; % Fixed
bs_d_antenna_h=0.5;
bs_d_antenna_v=0.5;
bs_cross_polarization_flag=0;
bs_velocity=vehicle_speed*1000/3600; % New
bs_height=1.5;% in m
ms_height=1.5;
ms_bearing_angle=0;
ms_downtilt_angle=0;
ms_slant_angle=0;
ms_num_antenna_h=VUE_antenna_num_Rx;
ms_num_antenna_v=1; % Fixed
ms_d_antenna_h=0.5;
ms_d_antenna_v=0.5;
ms_cross_polarization_flag=0;
ms_velocity=vehicle_speed*1000/3600;
polarization_field_model=2; % Fixed
CDL_flag = 0; % New
V2V_flag = 1; % =1 omi, =0 direction
t=0;
length_burst=1;%subframe_length/14;
tx_signal=zeros(bs_num_antenna_h*bs_num_antenna_v*(bs_cross_polarization_flag+1),length_burst);
direction_angle=[90 180 270 0];%VUE direction(=1 North,2 West,3 South,4 East)
drop_num=1;
for loop_drop=1:drop_num
    for sub_snapshot=1:sub_drop_num
        if scenario_kind == 1
            %% load nodedeployment information
            openfile = sprintf('../node_deployment/data_deploy/node_deployment_Urban_vehicle_speed=%d_No%d_subdrop_ID%d.mat',...
                vehicle_speed,loop_drop,sub_snapshot);
            load(openfile,'Total_VUE_num','VUE_info','Shadowing_VUE2VUE_LOS','Shadowing_VUE2VUE_NLOS','Distance_VUE2VUE','MeNB_loca','VUE_loca_WRAP');
            if vehicle_speed == 60
                V2V_range = 200; % Urban case V2V communcation range
            elseif vehicle_speed == 15
                V2V_range = 60; % Urban case V2V communcation range
            end
        else
            openfile = sprintf('../node_deploymentdata_deploy/node_deployment_Freeway_vehicle_speed=%d_No%d_subdrop_ID%d.mat',vehicle_speed,...
                loop_drop,sub_snapshot);
            load(openfile,'Total_VUE_num','VUE_info','Shadowing_VUE2VUE_LOS','Shadowing_VUE2VUE_NLOS','Distance_VUE2VUE','MeNB_loca','VUE_loca_WRAP');
            if vehicle_speed == 70
                V2V_range = 500; % Urban case V2V communcation range
            elseif vehicle_speed == 140
                V2V_range = 500; % Urban case V2V communcation range
            end
        end
        fprintf('V2V channel generation: drop=%d, subdrop=%d.\n',loop_drop,sub_snapshot);
        %% 2016-05-19 define VUE and CUE channel data
        % VUE2VUE channel
        VUE2VUE_Large_scale_fading=single(zeros(Total_VUE_num,Total_VUE_num));
        VUE2VUE_channel_index_matrix = (Distance_VUE2VUE<V2V_range).*(Distance_VUE2VUE>0);
        % this matrix decides if there is small scale fading based on the distance range
        VUE2VUE_channel_index_matrix = triu(VUE2VUE_channel_index_matrix); % Extract its upper triangular part
        VUE2VUE_channel_num = sum(VUE2VUE_channel_index_matrix,2);
        VUE2VUE_channel_local_index = cell(Total_VUE_num,1);
        VUE2VUE_pathDelay = cell(Total_VUE_num,1);
        %single(zeros(path_delay_num,Total_VUE_num,Total_VUE_num));
        VUE2VUE_fadingWeight = cell(Total_VUE_num,1);
        %single(zeros(bs_num_antenna_h*ms_num_antenna_h*path_delay_num,numFrame,Total_VUE_num,Total_VUE_num));
        V2V_channel_gain_per_RB = cell(Total_VUE_num,1);
        %single(zeros(RB_per_subframe,numFrame,Total_VUE_num,Total_VUE_num));
        for loop_VUE=1:Total_VUE_num
            VUE2VUE_channel_local_index{loop_VUE,1} = find(VUE2VUE_channel_index_matrix(loop_VUE,:) == 1);
            VUE2VUE_pathDelay{loop_VUE,1} = single(zeros(path_delay_num,VUE2VUE_channel_num(loop_VUE)));
            VUE2VUE_fadingWeight{loop_VUE,1} = single(zeros(bs_num_antenna_h*ms_num_antenna_h*path_delay_num,...
                numFrame,VUE2VUE_channel_num(loop_VUE)));
            V2V_channel_gain_per_RB{loop_VUE,1} = single(zeros(RB_per_subframe,numFrame,...
                VUE2VUE_channel_num(loop_VUE)));
        end
        %% channel generation of VUE2VUE
        for loop_VUE_Tx = 1:Total_VUE_num
            VUE_Tx_loca=VUE_info(loop_VUE_Tx,1);
            bs_direction= direction_angle(VUE_info(loop_VUE_Tx,2));
            if VUE_info(loop_VUE_Tx,2) == 2 || VUE_info(loop_VUE_Tx,2) == 4
                VUE2VUE_direction_flag=0;
            else
                VUE2VUE_direction_flag=1;
            end
            inner_index = 1;
            for loop_VUE_Rx = 1 : Total_VUE_num %loop_VUE_Rx=loop_VUE_Tx+1:Total_VUE_num
                if loop_VUE_Rx == loop_VUE_Tx
                    continue;
                end
                fprintf('loop_VUE_Tx=%d, loop_VUE_Rx=%d.\n',loop_VUE_Tx,loop_VUE_Rx);
                %% VUE Large scale fading
                VUE_Rx_loca=VUE_loca_WRAP(loop_VUE_Tx,loop_VUE_Rx);
                [ PL_dB , SF_std ] = Pathloss_SF_V2V_ver1(scenario_kind,center_frequency,VUE_Tx_loca,...
                    VUE_Rx_loca,VUE2VUE_direction_flag);
                if SF_std==3 %LOS
                    shadow_fading = Shadowing_VUE2VUE_LOS(loop_VUE_Tx,loop_VUE_Rx);
                elseif SF_std==4 %NLOS
                    shadow_fading = Shadowing_VUE2VUE_NLOS(loop_VUE_Tx,loop_VUE_Rx);
                end
                temp_dB = - shadow_fading - PL_dB;
                if temp_dB >= -200 && temp_dB <= -180 && Distance_VUE2VUE(loop_VUE_Tx,loop_VUE_Rx)<20
                    1;
                end
                % convert to linear value in mW
                temp = 10^(temp_dB/10);
                VUE2VUE_Large_scale_fading(loop_VUE_Tx,loop_VUE_Rx) = temp;
                %% Small-scale fading
                if channel_on_off == 0 || loop_VUE_Rx < loop_VUE_Tx+1
                    continue;
                end
                if VUE2VUE_channel_index_matrix(loop_VUE_Tx,loop_VUE_Rx) == 0
                    %V2V_channel_gain_per_RB(:,:,loop_VUE_Tx,loop_VUE_Rx) = 1;
                    continue;
                end
                ms_direction= direction_angle(VUE_info(loop_VUE_Rx,2));%VUE_Rx_index
                %********************??channel initialize(matlab version)??**********************%
                [phi_los_AoA,phi_los_AoD,theta_los_ZoA,theta_los_ZoD,bs_antennas_coordinate_gcs,ms_antennas_coordinate_gcs,num_clusters,...
                    num_rays,SF_dB,SF_linear,K_dB,K_linear,tau_delay,tau_delay_los,P,P_los,phi_n_AoA,phi_n_AoD,phi_nm_AoA,phi_nm_AoD,...
                    sub_cluster_delay_offset,sub_cluster_power_ratio,left_weak_clusters_index,two_strongest_clusters_index,bs_field_theta_nm,...
                    bs_field_phi_nm,bs_field_theta_nm1,bs_field_phi_nm1,bs_field_theta_los,bs_field_phi_los,bs_field_theta_los1,bs_field_phi_los1,...
                    ms_field_theta_nm,ms_field_phi_nm,ms_field_theta_nm1,ms_field_phi_nm1,ms_field_theta_los,ms_field_phi_los,ms_field_theta_los1,ms_field_phi_los1,...
                    XPR_linear,Phi_nm_vv,Phi_nm_vh,Phi_nm_hv,Phi_nm_hh,Phi_los,length_delay,signal_from_pre]=...
                    ic2_V2V_channel_model_init_ver1(scenario,VUE_Tx_loca,bs_height,bs_bearing_angle,bs_downtilt_angle,bs_slant_angle,bs_num_antenna_h,...
                    bs_num_antenna_v,bs_d_antenna_h,bs_d_antenna_v,bs_cross_polarization_flag,VUE_Rx_loca,ms_height,ms_bearing_angle,ms_downtilt_angle,...
                    ms_slant_angle,ms_num_antenna_h,ms_num_antenna_v,ms_d_antenna_h,ms_d_antenna_v,ms_cross_polarization_flag,ms_indoor_flag,los_flag,dt,...
                    polarization_field_model,CDL_flag,V2V_flag);
                %******************************************************************************%
                for frameIndex=1:numFrame
                    [h_u_s_n,delay_including_subclusters,P_including_subclusters,update_per_burst]=ic2_V2V_channel_model_generate_ver1(phi_los_AoA,...
                        phi_los_AoD,theta_los_ZoA,theta_los_ZoD,bs_antennas_coordinate_gcs,ms_antennas_coordinate_gcs,tau_delay,tau_delay_los,P,P_los,phi_n_AoA,phi_n_AoD,...
                        phi_nm_AoA,phi_nm_AoD,sub_cluster_delay_offset,sub_cluster_power_ratio,left_weak_clusters_index,two_strongest_clusters_index,bs_field_theta_nm,...
                        bs_field_phi_nm,bs_field_theta_nm1,bs_field_phi_nm1,bs_field_theta_los,bs_field_phi_los,bs_field_theta_los1,bs_field_phi_los1,...
                        ms_field_theta_nm,ms_field_phi_nm,ms_field_theta_nm1,ms_field_phi_nm1,ms_field_theta_los,ms_field_phi_los,ms_field_theta_los1,ms_field_phi_los1,...
                        XPR_linear,Phi_nm_vv,Phi_nm_vh,Phi_nm_hv,Phi_nm_hh,Phi_los,bs_cross_polarization_flag,ms_cross_polarization_flag,bs_velocity,...
                        bs_direction,ms_velocity,ms_direction,ms_indoor_flag,los_flag,center_frequency,num_clusters,num_rays,bs_num_antenna_h,bs_num_antenna_v,...
                        ms_num_antenna_h,ms_num_antenna_v,bs_d_antenna_h,bs_d_antenna_v,ms_d_antenna_h,ms_d_antenna_v,K_dB,K_linear,length_burst,...
                        tx_signal,length_delay,signal_from_pre,t,dt,CDL_flag);
                    t=t+frameIndex*subframe_duration;
                    if frameIndex==1
                        pathDelay=round(delay_including_subclusters/dt);
                        VUE2VUE_pathDelay{loop_VUE_Tx,1}(:,inner_index) = pathDelay;
                    end
                    [Fading_Weight , FadingWeight_all] = Fading_Weight_3D_ver3(h_u_s_n,length_burst,num_clusters,bs_num_antenna_h,bs_num_antenna_v,...
                        bs_cross_polarization_flag,ms_num_antenna_h,ms_num_antenna_v,ms_cross_polarization_flag,symbol_length);
                    VUE2VUE_fadingWeight{loop_VUE_Tx,1}(:,frameIndex,inner_index) = Fading_Weight;
                    %% channel gain generation for VUE2VUE
                    CSI_link = zeros(bs_num_antenna_h*ms_num_antenna_h,occupied_subcarrier);
                    fadingWeight_perlink = zeros(bs_num_antenna_h*ms_num_antenna_h,FFT_length);
                    for loop_rx = 1:ms_num_antenna_h
                        for loop_tx = 1:bs_num_antenna_h
                            Channel_Coeff = zeros(FFT_length,1);
                            for loop_path = 1:path_delay_num %numPaths
                                Channel_Coeff(min(pathDelay(loop_path)+1,FFT_length),:) = Channel_Coeff(min(pathDelay(loop_path)+1,FFT_length),:) ...
                                    + Fading_Weight(loop_path,:);
                            end
                            fadingWeight_perlink((loop_rx-1)*bs_num_antenna_h+loop_tx,:) = fft(Channel_Coeff,FFT_length).';
                            % from one tx antenna to one rx antenna
                            CSI_link((loop_rx-1)*bs_num_antenna_h+loop_tx,:) = fadingWeight_perlink((loop_rx-1)*bs_num_antenna_h...
                                +loop_tx,occupied_subcarrier_index);  %
                        end % end of loop_rx
                    end % end of loop_tx
                    for loop_RB = 1:RB_per_subframe
                        for loop_antenna = 1:loop_rx*loop_tx
                            if loop_antenna == 1
                                CSI_current_RB = CSI_link(loop_antenna,(loop_RB-1)*subcarrier_per_RB+1:loop_RB*subcarrier_per_RB).*...
                                    conj(CSI_link(loop_antenna,(loop_RB-1)*subcarrier_per_RB+1:loop_RB*subcarrier_per_RB));
                            else
                                CSI_current_RB = CSI_current_RB + CSI_link(loop_antenna,(loop_RB-1)*subcarrier_per_RB+1:...
                                    loop_RB*subcarrier_per_RB).*conj(CSI_link(loop_antenna,(loop_RB-1)*subcarrier_per_RB+1:...
                                    loop_RB*subcarrier_per_RB));
                            end
                        end % loop_antenna
                        V2V_channel_gain_per_RB{loop_VUE_Tx,1}(loop_RB,frameIndex,inner_index) = mean(abs(CSI_current_RB));
                    end %end of loop_RB
                end %end of frame
                VUE2VUE_channel_index_matrix(loop_VUE_Tx,loop_VUE_Rx) = inner_index;
                inner_index = inner_index + 1;
            end %end of loop_VUE_Rx
        end %end of loop_VUE_Tx
        %% save channel data every Tx VUE
        if channel_on_off == 1
            if scenario_kind == 1
                savefile = sprintf('../data_storage/fast_fading/fastfading_V2V_Urban_vehicle_speed%d_No%d_subdrop_No%d.mat',...
                    vehicle_speed,loop_drop,sub_snapshot);
            else
                savefile = sprintf('../data_storage/fast_fading/fastfading_V2V_Freeway_vehicle_speed%d_No%d_subdrop_No%d.mat',...
                    vehicle_speed,loop_drop,sub_snapshot);
            end
            save(savefile,'V2V_channel_gain_per_RB','VUE2VUE_pathDelay','VUE2VUE_fadingWeight','VUE2VUE_channel_index_matrix');
        end
        if scenario_kind == 1
            savefile = sprintf('../data_storage/fast_fading/slowfading_V2V_Urban_vehicle_speed=%d_No%d_subdrop_No%d.mat',...
                vehicle_speed,loop_drop,sub_snapshot);
        else
            savefile = sprintf('../data_storage/fast_fading/slowfading_V2V_Freeway_vehicle_speed=%d_No%d_subdrop_No%d.mat',...
                vehicle_speed,loop_drop,sub_snapshot);
        end
        save(savefile,'VUE2VUE_Large_scale_fading');
    end % end of subsnapshot
end% end of loop_drop