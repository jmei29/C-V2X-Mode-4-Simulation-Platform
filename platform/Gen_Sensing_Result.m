%% Create by Jie Mei on 05-11-2020
% Genrate estimated signal strength of each subchannel in Selection Window
%%
function Sensing_Result = Gen_Sensing_Result(Sensing_period, Sensing_Win_Len, Sub_channel_num, Selection_Win_Len, VUE_index)
Sensing_Window =  Sensing_period(1 : Sensing_Win_Len, 1 : Sub_channel_num,  VUE_index);
Sensing_Window =  reshape(Sensing_Window, Sensing_Win_Len, Sub_channel_num);
Num_ = Sensing_Win_Len/Selection_Win_Len;
Sensing_Result = zeros(Selection_Win_Len, Sub_channel_num);
for i = 1: Num_
    Sensing_Result = Sensing_Result + Sensing_Window((i-1)*Selection_Win_Len + 1: i*Selection_Win_Len, : );
end
Sensing_Result = Sensing_Result/Num_;