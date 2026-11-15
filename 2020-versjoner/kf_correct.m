function [x_hat, P_hat] = kf_correct(x_bar, P_bar, y, new_data, Cd, Rd)
% Korrigerer kun når IMU har gitt en ny sample, ellers gir prediction
if new_data > 0.5
    S = Cd*P_bar*Cd' + Rd;
    L = P_bar*Cd' / S;
    x_hat = x_bar + L*(y - Cd*x_bar);
    I = eye(size(P_bar,1));
    P_hat = (I - L*Cd)*P_bar*(I - L*Cd)' + L*Rd*L';   % Joseph form, holder seg SPD
else
    x_hat = x_bar;
    P_hat = P_bar;
end
end
