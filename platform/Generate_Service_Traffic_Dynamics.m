clear all;
clc;
% V2V_service_type = 1, Safety related message, Periodic traffic.
% V2V_service_type = 2, Automobile service, Periodic traffic;
System_Initialization_C_V2X;
%% Scenario Parameters set
service_traffic_ratio_set = [1 0];
active_ratio_set = [0.25];
len = length(active_ratio_set);
active_ratio = active_ratio_set(unidrnd(len));
distance_min = 20;
distance_max = 45;
active_VUE_num_array = [];
%% generate VUE Tx information
for i = 1: sample_tra_len
    loop_drop = mod(i, drop_num_simu);
    if loop_drop == 0
        loop_drop = drop_num_simu;
    end
    for sub_snapshot = 1 : sub_drop_num
        if scenario_kind == 2
            openfile = sprintf('../Data/data_deploy/node_deployment_Freeway_vehicle_speed=%d_No%d_subdrop_ID%d.mat',...
                vehicle_speed,loop_drop,sub_snapshot);
        end
        load(openfile,'Total_VUE_num','VUE_info','Distance_VUE2VUE');
        if sub_snapshot == 1
            %% generate index of VUE-Tx
            active_VUE_service_type = zeros(Total_VUE_num, 1);
            active_VUE_index = zeros(Total_VUE_num, 1);
            active_VUE_Rx_index = zeros(Total_VUE_num, 1);
            slice_safety_VUE_set = [];
            slice_auto_VUE_set = [];
            index_ = 1; % index of active VUE
            for loop_VUE_Tx_idx = 1 : Total_VUE_num
                if rand > active_ratio
                    continue
                end
                active_VUE_index(index_) = loop_VUE_Tx_idx;
                Distance_VUE2VUE_vector = Distance_VUE2VUE(loop_VUE_Tx_idx, :).*...
                    (VUE_info(:,2) == VUE_info(loop_VUE_Tx_idx,2))';
                index_vector = find(Distance_VUE2VUE_vector>distance_min & Distance_VUE2VUE_vector<distance_max);
                if isempty(index_vector)
                    [Value II] = min(abs(Distance_VUE2VUE_vector - distance_max));
                    active_VUE_Rx_index(index_) = II;
                else
                    [Value II] = max(Distance_VUE2VUE_vector(index_vector));
                    active_VUE_Rx_index(index_) = index_vector(II);
                end % end of isempty(index_vector)
                index_ = index_ + 1;
            end %end of loop_VUE_Tx
            active_VUE_num  = index_ - 1;
            active_VUE_service_type = active_VUE_service_type(1:active_VUE_num, :);
            active_VUE_index = active_VUE_index(1:active_VUE_num, :);
            active_VUE_Rx_index = active_VUE_Rx_index(1:active_VUE_num, :);
            len = length(service_traffic_ratio_set);
            service_traffic_ratio = service_traffic_ratio_set(unidrnd(len));
            for index_ = 1 : active_VUE_num
                active_VUE_service_type(index_) = 1 + (rand>service_traffic_ratio);
                if active_VUE_service_type(index_) == 1
                    slice_safety_VUE_set = [slice_safety_VUE_set; active_VUE_index(index_)];
                else
                    slice_auto_VUE_set = [slice_auto_VUE_set; active_VUE_index(index_)];
                end
            end % end of for index_
            %% save files of active UE
            if scenario_kind == 2
                savefile0 = sprintf('../Data/VUE_Tx_INFO/VUE_Tx_info_Freeway_vehicle_speed=%d_No%d.mat',...
                    vehicle_speed,i);
            end
            save(savefile0, 'active_VUE_index','active_VUE_num', 'active_VUE_service_type',...
                'slice_safety_VUE_set', 'slice_auto_VUE_set');
            fprintf('\n Number of active UE = %d.\n', active_VUE_num);
        else
            active_VUE_Rx_index = zeros(active_VUE_num, 1);
            for index_ = 1 : active_VUE_num
                loop_VUE_Tx_idx = active_VUE_index(index_);
                Distance_VUE2VUE_vector = Distance_VUE2VUE(loop_VUE_Tx_idx, :).*...
                    (VUE_info(:,2) == VUE_info(loop_VUE_Tx_idx,2))';
                index_vector = find(Distance_VUE2VUE_vector>distance_min & Distance_VUE2VUE_vector<distance_max);
                if isempty(index_vector)
                    [Value II] = min(abs(Distance_VUE2VUE_vector - distance_max));
                    active_VUE_Rx_index(index_) = II;
                else
                    [Value II] = max(Distance_VUE2VUE_vector(index_vector));
                    active_VUE_Rx_index(index_) = index_vector(II);
                end % end of isempty(index_vector)
            end
        end % if sub_snapshot == 1
        %% save files of active UE
        if scenario_kind == 2
            savefile1 = sprintf('../Data/VUE_Tx_INFO/VUE_Tx_info_Freeway_vehicle_speed=%d_No%d_subdrop_ID%d.mat',...
                vehicle_speed,i, sub_snapshot);
        end
        save(savefile1, 'active_VUE_Rx_index');
        %% print
        %fprintf('\n snapshot=%d, sub_snapshot_ID=%d.\n', loop_drop, sub_snapshot);
    end %end of sub_snapshot
end %end of loop_drop\