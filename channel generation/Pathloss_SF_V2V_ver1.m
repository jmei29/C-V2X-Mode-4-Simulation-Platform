function [ PL_dB , SF_std , LOS_flag ] = Pathloss_SF_V2V_ver1(scenario,center_frequency,bs_location,ms_location,direction_flag)
%% Description:
%  Calculate V2V PL and SF_std in dB
%% Create by Haojun Yang 2016-04-14 based on TR 36.885 and WINNER+ D5.3
% V1.0.0
%% Modify by Jie Mei 2016-06-08 
% V2.0.0 
%% Input Parameters:
%  scenario : 1 for Urban case   2 for Freeway case.
%  center_frequency : frequency, in Hz.
%  bs_location : real location of vehicle, in m; Note that this is real location.
%  ms_location : real location of vehicle, in m; Note that this is real location.
%  direction_flag : flag of move direction.
%% Output Parameters:
%  PL_dB : in dB.
%  SF_std : in dB.
%  LOS_flag : flag of LOS.

%% function:
center_frequency_GHz = center_frequency/1e9;% center frequency in GHz
c = 2.99792458e8;% Speed of Light in m/s

bs_height = 1.5;% the height of BS, in m
ms_height = 1.5;% the height of MS, in m
h_effective = 1.0;% in m
bs_height_effective = bs_height-h_effective;
ms_height_effective = ms_height-h_effective;

d_2D = max(abs(ms_location-bs_location),3);% Min. 2D distance,3m
d_BP_effective = 4*bs_height_effective*ms_height_effective*center_frequency/c;% in m
% 2GHz has a bug!!!
%% Urban case
if scenario == 1
    Shadow_std_LOS = 3;% in dB
    Shadow_std_NLOS = 4;% in dB
    street_width = 20;% in m
    if direction_flag == 0 % Horizontal
        d_1 = abs(real(ms_location)-real(bs_location));
        d_2 = abs(imag(ms_location)-imag(bs_location));
    elseif direction_flag == 1 % Vertical
        d_1 = abs(imag(ms_location)-imag(bs_location));
        d_2 = abs(real(ms_location)-real(bs_location));
    end
    %%
    if (min(d_1,d_2) > street_width/2) && (d_1 + d_2 > 10) && (d_1 + d_2 < 5000) 
        PL_tmp1 = Pathloss_NLOS_Manhattan(d_1,d_2,d_BP_effective,center_frequency_GHz,bs_height_effective,ms_height_effective);  
        PL_tmp2= Pathloss_NLOS_Manhattan(d_2,d_1,d_BP_effective,center_frequency_GHz,bs_height_effective,ms_height_effective);
        SF_std = Shadow_std_NLOS;
        LOS_flag = 0;
        PL_dB = min(PL_tmp1,PL_tmp2);
    elseif (min(d_1,d_2) >=0) && (min(d_1,d_2) <= street_width/2)
        PL_dB= Pathloss_LOS(d_2D,d_BP_effective,center_frequency_GHz,bs_height_effective,ms_height_effective);
        SF_std = Shadow_std_LOS;
        LOS_flag = 1;
    end  
end %end for Urban case
%% Freeway case
if scenario == 2
    Shadow_std_LOS = 3;% in dB
    PL_LOS= Pathloss_LOS(d_2D,d_BP_effective,center_frequency_GHz,bs_height_effective,ms_height_effective);
    
    PL_dB = PL_LOS;
    SF_std = Shadow_std_LOS;
    LOS_flag = 1; 
end %end for Freeway case

end




