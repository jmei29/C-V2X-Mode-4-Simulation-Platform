function [ALL_CDF_Reward,ALL_Seg_Array_Reward,cdf_S_PDR, PDR_S,cdf_A_PDR, PDR_A,...
                Reward_Result, PDR_avg_Result] ...
                    = get_Result_fun(openfile_str, File_ULC_index_Min, File_ULC_index_Max, vehicle_speed, CASE_IDX, sample_tra_len)
%% Parameters
PDR_avg_Result = cell(1,2);
Reward_Result = cell(1,1);
Seg_Num = 100;
EDGE_1_PDR = [10^-4, 10^-3, 10^-2, 10^-1, 1];
Len_1_PDR = length(EDGE_1_PDR) - 1;
EDGE_2_PDR = [10^-4, 10^-3, 10^-2, 10^-1, 1];
Len_2_PDR = length(EDGE_2_PDR) - 1;
%%
for loop_File_idx = File_ULC_index_Min : File_ULC_index_Max
% Collect data
    openfile =sprintf(openfile_str, vehicle_speed, loop_File_idx, CASE_IDX);
    load(openfile, 'PDR_avg','reward');
    for loop_drop =2:  sample_tra_len %sample_tra_len
        PDR_avg_Result{1,1} = [PDR_avg_Result{1,1,1};  PDR_avg(loop_drop, 1)];
        PDR_avg_Result{1,2} = [PDR_avg_Result{1,2,1}; PDR_avg(loop_drop, 2)];
        Reward_Result{1, 1} = [Reward_Result{1, 1}; reward(loop_drop)];
        fprintf('File_idx=%d, loop_drop=%d.\n',loop_File_idx, loop_drop);
    end % end of sub_snapshot
end % end of loop_File_idx
%%
[cdf_S_PDR, PDR_S] = cdf_calculate(log10(PDR_avg_Result{1,1,1}), 1000);
[cdf_A_PDR, PDR_A] = cdf_calculate(log10(PDR_avg_Result{1,2,1}), 1000);
[ALL_CDF_Reward,ALL_Seg_Array_Reward]=cdf_calculate(Reward_Result{1,1},Seg_Num);