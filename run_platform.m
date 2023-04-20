%% Simulation Settings: LOAD SET OF configuration
CASE_IDX = 1;
MAX_epsiode = 2;
scenario_kind = 2;% scenario_kind, Freeway case=2
vehicle_speed=70;
drop_num = 10;
num_of_subchannel = 3; % 1- subcahnnel num  
selection_Win_Len = 50; % 2- selection window size of 
MCS_index = 3; % 3- MCS index
Max_Sensing_Win_len = 100;
Max_num_sub_channel = 6;
% save simualtion parameters
savefile = sprintf('simualtion_parameters.mat');
save(savefile, 'CASE_IDX', 'MAX_epsiode', 'scenario_kind', 'vehicle_speed', 'drop_num',...
    'num_of_subchannel', 'selection_Win_Len', 'MCS_index', 'Max_Sensing_Win_len',...
    'Max_num_sub_channel');
%% run simulation platform
%------run nodedeployment---------------------%
cd('node_ployment_Freeway_case/')
node_deployment;
%------run channel generation-----------------%
cd('../channel generation/')
V2V_V2C_channel_generation_v1_3;
%------run main documen----------------------%
cd('../platform/')
Generate_Service_Traffic_Dynamics;
Main;

