clf;
%%
figure(1)
subplot(1,3,1); %Queue Length
Queue_Len = (pak_count - transmit_pak_index) + ...
    (bits_need_transmit/pak_bits_safey).*((active_VUE_service_type == 1)) + ...
    (bits_need_transmit/pak_bits_auto).*((active_VUE_service_type == 2));
bar([1 : active_VUE_num], Queue_Len)
xlabel('VUE')
ylabel('Queue Length')
delay_per_pak_check_1 = delay_per_pak.*repmat(transpose(active_VUE_service_type == 1), record_pak_num, 1);
delay_per_pak_check_1 = delay_per_pak_check_1(delay_per_pak_check_1 > 0);
delay_per_pak_check_2 = delay_per_pak.*repmat(transpose(active_VUE_service_type == 2), record_pak_num, 1);
delay_per_pak_check_2 = delay_per_pak_check_2(delay_per_pak_check_2 > 0);
subplot(1,3,2);
histogram(delay_per_pak_check_1, 'Normalization','probability');
xlabel('Slice 1-Safety')
ylabel('Packet Delay (in ms)')
subplot(1,3,3)
histogram(delay_per_pak_check_2, 'Normalization','probability');
xlabel('Slice 2-Automobile')
ylabel('Packet Delay (in ms)')
%%
figure(2) %PDR in Network Slice #1
subplot(2,2,1); 
PDR_1 = PDR_active_VUE.*repmat(transpose(active_VUE_service_type == 1), record_pak_num, 1);
PDR_1 = PDR_1(PDR_1 > 0);
histogram(log10(PDR_1));
xlabel('Slice 1-Safety, PDR')
subplot(2,2,2); 
SINR_1 = SINR_active_VUE.*repmat(transpose(active_VUE_service_type == 1), record_pak_num, 1);
SINR_1 = SINR_1(SINR_1 > 0);
SINR_dB_1 = 10*log10(SINR_1);
histogram(SINR_dB_1);
xlabel('Slice 1-Safety, pSINR (dB)')
subplot(2,2,3); 
bar([1 : loop_frame], Collision_Ratio_Slice1(1:loop_frame, 3))
xlabel('Collision Probability at each frame')
ylabel('Frame index')
subplot(2,2,4); 
yy = [Collision_Ratio_Slice1(1:loop_frame, 1), Collision_Ratio_Slice1(1:loop_frame, 2)];
bar(yy,'stacked');
xlabel('Frame index')
ylabel('Num of V2V transmisson in Slice 1')
legend('Collision Num', 'Non-Collision Num');
%%
figure(3) %PDR in Network Slice #2
subplot(2,2,1); 
PDR_2 = PDR_active_VUE.*repmat(transpose(active_VUE_service_type == 2), record_pak_num, 1);
PDR_2 = PDR_2(PDR_2 > 0);
histogram(log10(PDR_2));
xlabel('Slice 2-Auto, PDR')
subplot(2,2,2); 
SINR_2 = SINR_active_VUE.*repmat(transpose(active_VUE_service_type == 2), record_pak_num, 1);
SINR_2 = SINR_2(SINR_2 > 0);
SINR_dB_2 = 10*log10(SINR_2);
histogram(SINR_dB_2);
xlabel('Slice 2-Auto, pSINR (dB)')
subplot(2,2,3); 
bar([1 : loop_frame], Collision_Ratio_Slice2(1:loop_frame, 3))
xlabel('Collision Probability at each frame')
ylabel('Frame index')
subplot(2,2,4); 
yy = [Collision_Ratio_Slice2(1:loop_frame, 1), Collision_Ratio_Slice2(1:loop_frame, 2)];
bar(yy,'stacked');
xlabel('Frame index')
ylabel('Num of V2V transmisson in Slice 2')
legend('Collision Num', 'Non-Collision Num');
%%
figure(4) % Large_scale_Fading
subplot(2,2,1)
R_power_mW_1_pre  = (VUE_Rx_S_power_per_sc_mW).*repmat(transpose(active_VUE_service_type == 1), record_pak_num, 1);
R_power_mW_1 = R_power_mW_1_pre(R_power_mW_1_pre > 0);
R_power_dBm_1 = 10*log10(R_power_mW_1);
I_power_mW_1 = VUE_Rx_I_power_per_sc_mW.*repmat(transpose(active_VUE_service_type == 1), record_pak_num, 1);
I_power_mW_1 = I_power_mW_1(R_power_mW_1_pre>0);
I_power_dBm_1 =  10*log10(I_power_mW_1+noise_power_mw_per_sc);
subplot(2,2,1)
histogram(R_power_dBm_1, 'Normalization','probability');
xlabel('Slice 1, Tx power at Rx(dBm)')
subplot(2,2,2)
histogram(I_power_dBm_1, 'Normalization','probability');
xlabel('Slice 1, Interference power at Rx(dBm)')
R_power_mW_2_pre  = (VUE_Rx_S_power_per_sc_mW).*repmat(transpose(active_VUE_service_type == 2), record_pak_num, 1);
R_power_mW_2 = R_power_mW_2_pre(R_power_mW_2_pre > 0);
R_power_dBm_2 = 10*log10(R_power_mW_2);
I_power_mW_2 = VUE_Rx_I_power_per_sc_mW.*repmat(transpose(active_VUE_service_type == 2), record_pak_num, 1);
I_power_mW_2 = I_power_mW_2(R_power_mW_2_pre>0);
I_power_dBm_2 =  10*log10(I_power_mW_2+noise_power_mw_per_sc);
subplot(2,2,3)
histogram(R_power_dBm_2, 'Normalization','probability');
xlabel('Slice 2, Tx power at Rx(dBm)')
subplot(2,2,4)
histogram(I_power_dBm_2, 'Normalization','probability');
xlabel('Slice 2-Auto, Interference power at Rx(dBm)')
%%
% figure(5) % Plot link between VUE-Tx and VUE-Rx
% for loop_VUE_Tx = 1 : active_VUE_num
%     VUE_Tx_idx = active_VUE_index(loop_VUE_Tx);
%     VUE_Rx_idx = active_VUE_Rx_index(loop_VUE_Tx);
%     temp = [VUE_info(VUE_Tx_idx,1), VUE_info(VUE_Rx_idx,1)];
%     plot(real(temp), imag(temp), '-*')
%     hold on
% end % end of loop_VUE_Tx
% %%
pause(1)