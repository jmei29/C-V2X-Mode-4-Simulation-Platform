function [cdf_S_delay, delay_S,cdf_A_delay, delay_A, Delay_Result] ...
                    = get_Result_Delay_fun(openfile_str, File_ULC_index_Min, File_ULC_index_Max, vehicle_speed, ...
                           CASE_IDX, sample_tra_len, record_pak_num)
%% Parameters
Delay_Result = cell(1,2);
Seg_Num = 100;
%%
for loop_File_idx = File_ULC_index_Min : File_ULC_index_Max
% Collect data
    openfile =sprintf(openfile_str, vehicle_speed, loop_File_idx, CASE_IDX);
    load(openfile, 'Packet_Delay', 'active_VUE_service_type_record');
    for loop_drop =2:  sample_tra_len %sample_tra_len
        active_VUE_service_type = active_VUE_service_type_record{loop_drop, 1};
        Packet_Delay_temp = Packet_Delay{loop_drop, 1};
        Packet_Delay_1 = Packet_Delay_temp.*repmat(transpose(active_VUE_service_type == 1), record_pak_num, 1);
        Packet_Delay_1 = Packet_Delay_1(Packet_Delay_1>0);
        Packet_Delay_2 = Packet_Delay_temp.*repmat(transpose(active_VUE_service_type == 2), record_pak_num, 1);
        Packet_Delay_2 = Packet_Delay_2(Packet_Delay_2>0);
        Delay_Result{1,1} = [Delay_Result{1,1}; Packet_Delay_1(:)];
        Delay_Result{1,2} = [Delay_Result{1,2}; Packet_Delay_2(:)];
        fprintf('File_idx=%d, loop_drop=%d.\n',loop_File_idx, loop_drop);
    end % end of sub_snapshot
end % end of loop_File_idx
%%
[cdf_S_delay, delay_S] = cdf_calculate(Delay_Result{1,1}, Seg_Num);
[cdf_A_delay, delay_A] = cdf_calculate(Delay_Result{1,2}, Seg_Num);
