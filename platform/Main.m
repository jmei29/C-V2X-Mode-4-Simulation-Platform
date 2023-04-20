%% Create by Jie Mei 2020-01-19, C-V2X Mode 4
%% Revised also by Jie Mei 2020-05-10, C-V2X Mode 4 Cablibration
tic; % clacluate the time
clc
clear
System_Initialization_C_V2X_Mode4;
fprintf('%% *****  C-V2X mode 4: Proposed DRL scheme Version 4.   ***** %%\n');
break_flag = 0;
warning off all;
%% settings for simulations
episode = 1;
File_index = 1;
sample_num = 1;
Rician_factor = 1;
%% TRAINING PROCESS
while 1
    if episode >= MAX_epsiode
        break
    end
    %% NET SLICING ENVIROMENT FOR DRL
    reward = zeros(sample_tra_len, 1); % reward of per subdrop
    Delay_avg = zeros(sample_tra_len, 2);
    PDR_avg = zeros(sample_tra_len, 2);
    PDR_record = cell(sample_tra_len, 1);
    active_VUE_service_type_record = cell(sample_tra_len, 1);
    Packet_Delay = cell(sample_tra_len, 1);
    %% A sample trajectory is generated
    for loop_drop = 1 : sample_tra_len
        fprintf(' Episode_idx=%d, loop_drop=%d.\n',episode, loop_drop);
        loop_drop_ = mod(loop_drop+(episode-1)*sample_tra_len, drop_num_simu);
        if loop_drop_ == 0
            loop_drop_ = drop_num_simu;
        end
        %% load information of V2V scenario;
        % Slow fading channel inforamtion load
        if scenario_kind == 2
            openfile1 = sprintf('../Data/channel_storage/slowfading_V2V_V2C_Freeway_vehicle_speed=%d_No%d.mat',...
                vehicle_speed,loop_drop_);
            openfile2 = sprintf('../Data/VUE_Tx_INFO/VUE_Tx_info_Freeway_vehicle_speed=%d_No%d.mat',...
                vehicle_speed,loop_drop);
        end
        %% Information V2V traffic
        load(openfile1, 'VUE2VUE_Large_scale_fading_all');
        load(openfile2, 'active_VUE_index', 'active_VUE_num',  'active_VUE_service_type', 'slice_safety_VUE_set', 'slice_auto_VUE_set');
        active_VUE_service_type_record{loop_drop, 1} = active_VUE_service_type;
        % 1: Active number of vehicles subjected safety related service
        slice_safety_VUE_num = length(slice_safety_VUE_set);
        slice_auto_VUE_num = length(slice_auto_VUE_set);
        %% Record Data
        time_index = 1;
        total_data_rate = zeros(record_pak_num, active_VUE_num);
        SINR_active_VUE = zeros(record_pak_num, active_VUE_num); % pSINR of active UE
        VUE_Rx_S_power_per_sc_mW = zeros(record_pak_num, active_VUE_num); % recevie power from active VUE at the corresponbding receviing side
        VUE_Rx_I_power_per_sc_mW = zeros(record_pak_num, active_VUE_num); % recevie power from interference VUE at the receviing side
        PDR_active_VUE = zeros(record_pak_num, active_VUE_num); % PDR of VUE at each frame
        pak_arrive_frame_index = zeros(record_pak_num ,active_VUE_num);%the arrive time of packet
        pak_leave_frame_index = zeros(record_pak_num ,active_VUE_num);% the leave time of packet
        pak_bits = zeros(record_pak_num ,active_VUE_num);% the bits of each packet
        pak_count = zeros(active_VUE_num,1); % count the arrive packet
        transmit_pak_index = zeros(active_VUE_num,1); % the index of packet which is tranismitting
        wait_time_per_pak = zeros(record_pak_num ,active_VUE_num);% wait time of each packet needs to be transmitted
        delay_per_pak = zeros(record_pak_num ,active_VUE_num); % delay of each packet
        bits_need_transmit = zeros(active_VUE_num,1); % the bits need to be transmitted
        start_instance_periodic_traffic = ones(active_VUE_num,1);
        pak_reserve_sub_CH_idx = zeros(record_pak_num ,active_VUE_num);
        % the reserve sub-channel idex of each pakcet
        %% Variable Setting
        Sensing_period = zeros(Max_Sensing_Win_len, Max_num_sub_channel, active_VUE_num);
        Collision_Ratio_record = cell(sub_drop_num, 1);
        Congestion_Ratio_record = cell(sub_drop_num, 1);
        Data_rate_record = cell(sub_drop_num, 1);
        SubCH_choice = cell(sub_drop_num, 1);
        SINR_sc_record = cell(sub_drop_num, 1);
        VUE_Rx_S_power_per_sc_mW_record = cell(sub_drop_num, 1);
        VUE_Rx_I_power_per_sc_mW_record = cell(sub_drop_num, 1);
        VUE_Rx_CIR_per_sc_record = cell(sub_drop_num, 2);
        for loop_sub_drop = 1 : sub_drop_num
            if scenario_kind == 2
                openfile3 = sprintf('../Data/VUE_Tx_INFO/VUE_Tx_info_Freeway_vehicle_speed=%d_No%d_subdrop_ID%d.mat',...
                    vehicle_speed,loop_drop, loop_sub_drop);
            end
            load(openfile3, 'active_VUE_Rx_index');
            VUE_Rx_CIR_per_sc_Slice1_snapshot = zeros(1, slice_safety_VUE_num, numFrame);
            scheduled_VUE_Slice1_SubCH_snapshot = zeros(slice_safety_VUE_num, numFrame);
            % 2: Active number of vehicles subjected automobile related service
            VUE_Rx_CIR_per_sc_Slice2_snapshot = zeros(1, slice_auto_VUE_num, numFrame);
            scheduled_VUE_Slice2_SubCH_snapshot = zeros(slice_auto_VUE_num, numFrame);
            Congestion_Ratio_Slice1 = zeros(numFrame, 1);
            Congestion_Ratio_Slice2 = zeros(numFrame, 1);
            Collision_Ratio_Slice1 = zeros(numFrame, 3); % The collision probabilty of each slice
            Collision_Ratio_Slice2 = zeros(numFrame, 3); % The collision probabilty of each slice
            VUE2VUE_Large_scale_fading  = VUE2VUE_Large_scale_fading_all{loop_sub_drop,  1};
            %% Define variable related to C-V2X mode 4
            % the scheme of RB allocation to VUEs
            scheduled_sub_CH_Safety = zeros(slice_safety_VUE_num, 1);
            scheduled_sub_CH_Auto = zeros(slice_auto_VUE_num, 1);
            % Sensing the occupation of each sub-channel in each slice
            %%
            Sub_channel_num = [num_of_subchannel, 0]; % Configuration of network slices
            Selection_Win_Len = [selection_Win_Len, 0]; % the number of sub-channels FOR each slice
            Sensing_Win_len = 2*Selection_Win_Len;
            % #1 FOR safety related service; #2 FOR automobie service
            Slice_MCS_index = [MCS_index, 0];
            RB_num_of_sub_channel = zeros(2, 1);
            RB_num_of_sub_channel(1) = (Slice_MCS_index(1) == 3)*12 + (Slice_MCS_index(1) == 4)*8;
            RB_num_of_sub_channel(2) = (Slice_MCS_index(2) == 3)*8 + (Slice_MCS_index(2) == 4)*6;
            % MCS scheme in each slice
            VUE_power_per_sc = zeros(active_VUE_num, 1); % the allocated power to each VUE
            VUE_power_per_sc(active_VUE_service_type == 1, 1) = ...
                Safety_VUE_Tx_pow/(RB_num_of_sub_channel(1)*subcarrier_per_RB); % in mW
            VUE_power_per_sc(active_VUE_service_type == 2, 1) = ...
                Auto_VUE_Tx_pow/(RB_num_of_sub_channel(2)*subcarrier_per_RB); % in mW
            %% RUNNING
            for loop_frame = 1:numFrame
                %%---------------------------------------------------------------------------%%%
                %%                                  TRANSMIT SIDE                            %%%
                %%---------------------------------------------------------------------------%%%
                %% packet arrive process
                for loop_VUE_Tx = 1 : active_VUE_num
                    if active_VUE_service_type(loop_VUE_Tx) == 1 && ... % safety related message
                            mod(time_index, period_safety_serv) == start_instance_periodic_traffic(loop_VUE_Tx)
                        arrive_pak_num = 1;
                        % the number of packet arrive at this frame FOR safety related service
                        pak_arrive_frame_index(pak_count(loop_VUE_Tx,1)+1:...
                            pak_count(loop_VUE_Tx,1)+arrive_pak_num, loop_VUE_Tx) = time_index;
                        % record arriving time index
                        pak_bits(pak_count(loop_VUE_Tx,1)+1:pak_count(loop_VUE_Tx,1)+arrive_pak_num,loop_VUE_Tx) = ...
                            pak_bits_safey;
                        pak_count(loop_VUE_Tx,1) = pak_count(loop_VUE_Tx,1)+arrive_pak_num;
                    end % end of "if active_VUE_service_type(loop_VUE_Tx) == 1 % safety related message"
                    % IF there is no data to be transmitted and buffer is not emtpy, WE LOAD data to transmit
                    if bits_need_transmit(loop_VUE_Tx,1) == 0 && ...
                            transmit_pak_index(loop_VUE_Tx,1)<pak_count(loop_VUE_Tx,1)
                        %% renew buffer state
                        transmit_pak_index(loop_VUE_Tx,1) = transmit_pak_index(loop_VUE_Tx,1)+1;
                        bits_need_transmit(loop_VUE_Tx,1) = pak_bits(transmit_pak_index(loop_VUE_Tx,1),...
                            loop_VUE_Tx);
                        %% Sensing-based Semi-persistent Scheduling
                        if active_VUE_service_type(loop_VUE_Tx) == 1 % safety related message
                            if transmit_pak_index(loop_VUE_Tx,1) > 1 && rand < 1 - Re_selection_prob(1)
                                % Stick to current Subchannel
                                pak_leave_frame_index(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = ...
                                    time_index + wait_time_per_pak(transmit_pak_index(loop_VUE_Tx,1) - 1,...
                                    loop_VUE_Tx);
                                wait_time_per_pak(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = ...
                                    wait_time_per_pak(transmit_pak_index(loop_VUE_Tx,1) - 1, loop_VUE_Tx);
                                pak_reserve_sub_CH_idx(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = ...
                                    pak_reserve_sub_CH_idx(transmit_pak_index(loop_VUE_Tx,1) - 1,...
                                    loop_VUE_Tx);
                            else
                                % Reselect
                                Sensing_Result = Gen_Sensing_Result(Sensing_period, Sensing_Win_len(1), Sub_channel_num(1), ...
                                    Selection_Win_Len(1), loop_VUE_Tx);
                                [waiting_time, sub_CH_idx] = Sensing_based_SPS(Sensing_Result, Selection_Win_Len(1));
                                pak_leave_frame_index(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = ...
                                    time_index  + waiting_time;
                                wait_time_per_pak(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx)  = waiting_time;
                                pak_reserve_sub_CH_idx(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = sub_CH_idx;
                            end
                        end % end of IF service type
                        %% Delay Calculate
                        delay_per_pak(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = ...
                            pak_leave_frame_index(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) - ...
                            pak_arrive_frame_index(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx);
                    end % end of IF bits_need_transmit(loop_VUE_Tx,1) == 0
                end %end of loop_VUE_Tx
                %%---------------------------------------------------------------------------%%%
                %%                                  Recorded SIDE                            %%
                %%---------------------------------------------------------------------------%%%
                %%  Sensing- PART I
                Sensing_period(1 : end-1, :, :) = Sensing_period(2 : end, :, :);
                Sensing_period(end, :, :) = 0; % clear variable
                IF_Transmit = zeros(active_VUE_num, 1);
                scheduled_VUE_SubCH = zeros(active_VUE_num, 1);
                VUE_Rx_S_power_per_sc = zeros(active_VUE_num, 1);  %sc=subcarrier
                %% the receive power of VUE Rx
                for loop_VUE_Tx = 1:active_VUE_num
                    if active_VUE_service_type(loop_VUE_Tx) ~= 1
                        continue;
                    end
                    if transmit_pak_index(loop_VUE_Tx,1)>0 && pak_leave_frame_index(...
                            transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) == time_index ...
                            &&  active_VUE_service_type(loop_VUE_Tx) == 1
                        sub_CH_index = pak_reserve_sub_CH_idx(transmit_pak_index(loop_VUE_Tx,1),...
                            loop_VUE_Tx);
                        IF_Transmit(loop_VUE_Tx) = 1;
                    elseif transmit_pak_index(loop_VUE_Tx,1)>0 && pak_leave_frame_index(...
                            transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) == time_index  ...
                            && active_VUE_service_type(loop_VUE_Tx) == 2
                        sub_CH_index = pak_reserve_sub_CH_idx(transmit_pak_index(loop_VUE_Tx,1),...
                            loop_VUE_Tx);
                        IF_Transmit(loop_VUE_Tx) = 1;
                    end % pak_leave_frame_index
                    %% Sensing Part II
                    % Record sensing data
                    if IF_Transmit(loop_VUE_Tx) == 0
                        continue;
                    end
                    scheduled_VUE_SubCH(loop_VUE_Tx) = sub_CH_index;
                    VUE_Tx_idx = active_VUE_index(loop_VUE_Tx);
                    VUE_Rx_idx = active_VUE_Rx_index(loop_VUE_Tx);
                    h_rayleigh = sqrt(1/2) *(randn(1,1) + 1i*randn(1,1));
                    
                    VUE_Rx_S_power_per_sc(loop_VUE_Tx, 1) = VUE_power_per_sc(loop_VUE_Tx, 1)*...
                        VUE2VUE_Large_scale_fading(VUE_Tx_idx, VUE_Rx_idx)*10^(VUE_ant_gain/10);
                    % Record data
                    VUE_Rx_S_power_per_sc_mW(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = ...
                        VUE_Rx_S_power_per_sc(loop_VUE_Tx, 1); % in mW
                    for loop_VUE_Sensing = 1 : active_VUE_num
                        if loop_VUE_Sensing == loop_VUE_Tx
                            Sensing_period(end, :, loop_VUE_Sensing) = Inf;
                            % not inclue VUE TX itself, currently transmitting packet, cannnot sense channel
                            continue
                        end
                        if transmit_pak_index(loop_VUE_Sensing,1)>0 && pak_leave_frame_index(...
                                transmit_pak_index(loop_VUE_Sensing,1), loop_VUE_Sensing) == time_index
                            continue
                        end % VUE, currently transmitting packet, cannnot sense channel
                        if active_VUE_service_type(loop_VUE_Tx) ~= active_VUE_service_type(loop_VUE_Sensing)
                            continue
                        end % VUE-Tx AND Sensed VUE must be in the same slice
                        VUE_Sensing_idx = active_VUE_index(loop_VUE_Sensing);
                        Sensing_period(end, sub_CH_index, loop_VUE_Sensing) = Sensing_period(end, sub_CH_index, ...
                            loop_VUE_Sensing) + VUE_power_per_sc(loop_VUE_Tx, 1)*...
                            VUE2VUE_Large_scale_fading(VUE_Tx_idx, VUE_Sensing_idx)*10^(VUE_ant_gain/10);
                        % Record the sum transmit power of VUE-Txs in this subchannel
                    end % end of FOR loop_VUE
                end % end of loop_VUE_Tx
                %% Record choice of sub-channel
                %---------------------Slice #1---------------------%
                temp1 = scheduled_VUE_SubCH(active_VUE_service_type == 1);
                scheduled_VUE_Slice1_SubCH_snapshot(:, loop_frame) = temp1;
                Total_transmission_num = sum(temp1>0);
                if Total_transmission_num>0
                    collision_num = 0; % Calculate the collolison frequency in slice 1 at current frame
                    channel_opccpuy_num = 0;
                    for i = 1 : Sub_channel_num(1)
                        temp_num = sum(temp1 == i);
                        collision_num = collision_num + (temp_num>1)*temp_num;
                        channel_opccpuy_num = channel_opccpuy_num + (temp_num>=1);
                    end
                    Collision_Ratio_Slice1(loop_frame, :) = [collision_num, Total_transmission_num, collision_num/Total_transmission_num];
                    Congestion_Ratio_Slice1(loop_frame, 1) = channel_opccpuy_num/Sub_channel_num(1);
                end
                %% INTERFERENCE from other VUE Txs to VUE Rx
                VUE_Rx_I_power_per_sc = zeros(active_VUE_num, active_VUE_num);
                for loop_VUE_Tx = 1 : active_VUE_num
                    if scheduled_VUE_SubCH(loop_VUE_Tx) == 0 || active_VUE_service_type(loop_VUE_Tx) ~= 1
                        continue;
                    end
                    for loop_interfered_VUE_Tx = 1 : active_VUE_num
                        if  loop_interfered_VUE_Tx == loop_VUE_Tx
                            continue;
                        end
                        if active_VUE_service_type(loop_VUE_Tx) ~= ...
                                active_VUE_service_type(loop_interfered_VUE_Tx)
                            continue
                        end % VUE-Tx AND INTERFERENCE VUE-Tx must be in the same slice
                        if scheduled_VUE_SubCH(loop_VUE_Tx) ~= ...
                                scheduled_VUE_SubCH(loop_interfered_VUE_Tx)
                            continue
                        end
                        VUE_Tx_I_index = active_VUE_index(loop_interfered_VUE_Tx);
                        VUE_Rx_idx = active_VUE_Rx_index(loop_VUE_Tx);
                        VUE_Rx_I_power_per_sc(loop_interfered_VUE_Tx, loop_VUE_Tx) = ...
                            VUE_power_per_sc(loop_VUE_Tx)*VUE2VUE_Large_scale_fading(VUE_Tx_I_index, ...
                            VUE_Rx_idx)*10^(VUE_ant_gain/10);
                    end % end of loop_interfered_VUE_Tx
                    % record data
                    VUE_Rx_I_power_per_sc_mW(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = ...
                        sum(VUE_Rx_I_power_per_sc(:, loop_VUE_Tx));
                end % end of FOR loop_VUE_Tx
                %% SINR calculate
                VUE_Rx_CIR_per_sc = zeros(1, active_VUE_num);
                % the SINR of VUE Tx in each subcarrier in each RB
                for loop_VUE_Tx = 1 : active_VUE_num
                    if scheduled_VUE_SubCH(loop_VUE_Tx) == 0 || active_VUE_service_type(loop_VUE_Tx) ~= 1
                        continue;
                    end
                    channel_gain_S_VUE_Rx_sc = norm(sqrt(Rician_fading_factor/(Rician_fading_factor+1)) + ...
                        sqrt(1/(Rician_fading_factor+1))*(sqrt(1/2)*(randn+1i*randn)))^2;
                    S_power_RB = VUE_Rx_S_power_per_sc(loop_VUE_Tx)*channel_gain_S_VUE_Rx_sc;
                    channel_gain_I_VUE_Rx_sc = norm(sqrt(Rician_fading_factor/(Rician_fading_factor+1)) + ...
                        sqrt(1/(Rician_fading_factor+1))*(sqrt(1/2)*(randn(active_VUE_num, 1)+1i*randn(active_VUE_num, 1))))^2;
                    I_power_RB = VUE_Rx_I_power_per_sc(:, loop_VUE_Tx).*channel_gain_I_VUE_Rx_sc;
                    I_power_RB_total = sum(I_power_RB);
                    VUE_Rx_CIR_per_sc(loop_VUE_Tx) = S_power_RB/(I_power_RB_total + noise_power_mw_per_sc);
                    SINR_active_VUE(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = VUE_Rx_CIR_per_sc(loop_VUE_Tx);
                    mcs_index = Slice_MCS_index(active_VUE_service_type(loop_VUE_Tx));
                    PDR_active_VUE(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = ...
                        max(BLER_calculate(VUE_Rx_CIR_per_sc(loop_VUE_Tx),mcs_index), 10^(-3));
                    if PDR_active_VUE(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) == 10^(-3)
                        PDR_active_VUE(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) =  ...
                            PDR_active_VUE(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx)*rand;
                    end
                    RB_num_per_SubCH = RB_num_of_sub_channel(active_VUE_service_type(loop_VUE_Tx));
                    total_data_rate(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx) = ...
                        RB_num_per_SubCH*bits_per_RB(mcs_index) * (1 - PDR_active_VUE(transmit_pak_index(loop_VUE_Tx,1), loop_VUE_Tx));
                    bits_need_transmit(loop_VUE_Tx,1)= 0; % FINISH transmiting
                end
                % Record SINR per subcarrier in PRB
                VUE_Rx_CIR_per_sc_Slice1_snapshot(:,:,loop_frame) = VUE_Rx_CIR_per_sc(:,...
                    active_VUE_service_type == 1);
                VUE_Rx_CIR_per_sc_Slice2_snapshot(:,:,loop_frame) = VUE_Rx_CIR_per_sc(:,...
                    active_VUE_service_type == 2);
                %% RENEW TIME INDEX
                time_index = time_index + 1;
            end % end of loop_frame
            %% Data Record
            Data_rate_record{loop_sub_drop, 1} = total_data_rate;
            SINR_sc_record{loop_sub_drop, 1} = SINR_active_VUE;
            VUE_Rx_S_power_per_sc_mW_record{loop_sub_drop, 1} = VUE_Rx_S_power_per_sc_mW;
            VUE_Rx_I_power_per_sc_mW_record{loop_sub_drop, 1} = VUE_Rx_I_power_per_sc_mW;
            VUE_Rx_CIR_per_sc_record{loop_sub_drop, 1} = VUE_Rx_CIR_per_sc_Slice1_snapshot;
            VUE_Rx_CIR_per_sc_record{loop_sub_drop, 2} = VUE_Rx_CIR_per_sc_Slice2_snapshot;
            SubCH_choice{loop_sub_drop, 1} = scheduled_VUE_Slice1_SubCH_snapshot;
            Congestion_Ratio_record{loop_sub_drop, 1} = Congestion_Ratio_Slice1(Congestion_Ratio_Slice1>0);
            Collision_Ratio_record{loop_sub_drop, 1} = Collision_Ratio_Slice1(Collision_Ratio_Slice1(:,2)>0, :);
        end % end of sub_snapshot
        %% Obtain current observe state
        % Packet delay related metric
        Delay_1 = delay_per_pak.*repmat(transpose(active_VUE_service_type == 1), record_pak_num, 1);
        Delay_1 = Delay_1(Delay_1 > 0);
        Delay_avg(loop_drop, 1) = mean(Delay_1(:));
        % PDR related metric
        PDR_1 = PDR_active_VUE.*repmat(transpose(active_VUE_service_type == 1), record_pak_num, 1);
        PDR_1 = PDR_1(PDR_1 > 0);
        PDR_avg(loop_drop, 1) = max(mean(PDR_1(:)), 10^-4);
        %% Data Record
        PDR_record{loop_drop, 1} = PDR_active_VUE;
        Packet_Delay{loop_drop, 1} = delay_per_pak;
        %% Save data FOR analysis
        if exist('../Data/Result', 'dir') == 0
            mkdir('../Data/Result');
        end
        savefile = sprintf('../Data/Result/V2V_Mode_4_speed%d_drop%d_Sample%d_Case_%d.mat',...
            vehicle_speed, sample_num, CASE_IDX);
        save(savefile, 'Data_rate_record', 'SINR_sc_record', 'VUE_Rx_CIR_per_sc_record','SubCH_choice',...
            'Collision_Ratio_record','Congestion_Ratio_record',...
            'delay_per_pak','PDR_active_VUE','Delay_1','PDR_1');
    end % end of loop_drop
    %% Renew episode/File_index number
    episode = episode + 1; % calculate the number of episodes
    sample_num = sample_num + 1; % calculate the number of samples
end % end of WHILE