function [x_bar_next, P_bar_next] = kf_predict(x_hat, P_hat, u, Ad, Bd, Qd)
% u = [Vs; Vd]  (Vs = kontroller FØR Vs0)
% Mat Ad, Bd, Qd inn fra "Constants" så Qd kan endres under kjøring.
x_bar_next = Ad*x_hat + Bd*u;
P_bar_next = Ad*P_hat*Ad' + Qd;
end
