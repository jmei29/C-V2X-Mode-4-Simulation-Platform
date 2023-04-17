function [reward] = reward_fun(x, x_target, x_max)
if x <= x_target
    reward =1;
elseif (x > x_target) && (x <= x_max)
    reward = (x_max - x)/(x_max - x_target);
else
    reward = 0;
end