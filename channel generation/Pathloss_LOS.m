%% LOS:
function PL_LOS = Pathloss_LOS(d_2D,d_BP_effective,center_frequency_GHz,bs_height_effective,ms_height_effective)

if (d_2D >= 10) && (d_2D <= d_BP_effective)
    PL_LOS = 22.7*log10(d_2D)+27.0+20.0*log10(center_frequency_GHz);
else%if (d_2D >= d_BP_effective) && (d_2D < 5000)
    PL_LOS = 40.0*log10(d_2D)+7.56-17.3*log10(bs_height_effective)-17.3*log10(ms_height_effective)+2.7*log10(center_frequency_GHz);
end

end