function [waiting_time, sub_CH_idx] = Sensing_based_SPS(Sensing_Result, Selection_Win_Len)
% Create by MJ, 2019-01-10
%% input
% Sensing_Window: two-dimension matrix, cloumn-time and row-subchannel
% SPS_period: The semi-persistent scheduling period
%% output
% waiting_time: the waiting time to transmit a packet
% sub_CH_idx: the index of sub_CH_idx to be chosen
%%
Sensing_Array = reshape(Sensing_Result,1, []);
%  sub_CH_num = size(Sensing_Result, 2);
%     sub_CH_idx = randi([1 sub_CH_num]);
%     waiting_time =  randi([1 Selection_Win_Len]);
if sum(Sensing_Array(:)) == 0
    sub_CH_num = size(Sensing_Result, 2);
    sub_CH_idx = randi([1 sub_CH_num]);
    waiting_time =  randi([1 Selection_Win_Len]);
else
    Sensing_Array = sort(Sensing_Array,'descend');
    index_20 = floor(length(Sensing_Array)*0.8);
    Threshold = Sensing_Array(index_20);
    [Sense_time_set, sub_CH_idx_set]=find(Sensing_Result<=Threshold);
    Index_ = randi([1 length(Sense_time_set)]);
    waiting_time = max(Sense_time_set(Index_), 1);
    %waiting_time = max(Selection_Win_Len - Sense_time_set(Index_) + 1, 1);
    sub_CH_idx = sub_CH_idx_set(Index_);
end
end