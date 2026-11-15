%% tune_qw_offline.m - tune Qw (Van Loan) offline on a logged flight
% Replays the logged y, u and new_data through the SAME Kalman filter as in Simulink,
% for many Qw values, and compares the estimates with the encoders.
%
% Run the init file (incl. kalman_setup.m) first. Needs: K1 K2 K3 Ts Rd x0 P0 Qw use_bias Vs0
% (if your equilibrium voltage has another name, e.g. V_s_0, set Vs0 = V_s_0; first)
% Log layout (same Mux as hover_full.mat):
%   1 time | 2:6 y | 7 new_data | 8:16 encoder (9) | 17:25 KF (9) | 26:27 u = [Vs_tilde Vd]

logfile = 'tuning_flight.mat';          % <-- your logged flight
S = load(logfile);  f = fieldnames(S);  d = S.(f{1});
if size(d,1) < size(d,2), d = d'; end
Y   = d(:,2:6);
ND  = d(:,7) > 0.5;
ENC = d(:,[8 9 10 11 13]);              % encoder [p pd e ed ld] (column 12 is lambda)
U   = d(:,26:27);
skip = round(5/Ts);                     % ignore the first 5 s (start-up)

q_grid    = 10.^(-6:0.5:1);             % values to try for each axis
q_base    = diag(Qw)';                  % start from your current Qw
axis_name = {'pitch  Qw(1,1)', 'elev   Qw(2,2)', 'travel Qw(3,3)'};
judged_on = {[1 2], [3 4], 5};          % columns of [p pd e ed ld] each axis is judged on
st_names  = {'p','p_{dot}','e','e_{dot}','\lambda_{dot}'};

q_best = q_base;
figure;
for a = 1:3
    rmse = zeros(numel(q_grid), numel(judged_on{a}));
    for i = 1:numel(q_grid)
        q = q_base;  q(a) = q_grid(i);
        X   = run_kf(Y, U, ND, diag(q), K1, K2, K3, Ts, Rd, x0, P0, use_bias, V_s_0);
        err = X(skip:end, [1 2 3 4 6]) - ENC(skip:end, :);
        rmse(i,:) = sqrt(mean(err(:, judged_on{a}).^2));
    end
    [~, ib]   = min(sum(rmse ./ min(rmse), 2));     % balance angle and rate error
    q_best(a) = q_grid(ib);

    subplot(1,3,a);
    loglog(q_grid, rmse, 'o-', 'LineWidth', 1.2); hold on; grid on;
    xline(q_base(a), '--k', 'now');  xline(q_best(a), '-r', 'best');
    xlabel('Q_w value'); ylabel('RMSE vs encoder');
    title(axis_name{a}); legend(st_names(judged_on{a}), 'Location', 'best');
end
fprintf('Current Qw : diag([%s])\n', num2str(q_base, '%.0e  '));
fprintf('Suggested  : diag([%s])\n', num2str(q_best, '%.0e  '));

%% ---------------------------------------------------------------------------
function X = run_kf(Y, U, ND, Qw, K1, K2, K3, Ts, Rd, x0, P0, use_bias, V_s_0)
% Same model and algorithm as kalman_setup.m + kf_correct + kf_predict
% (including the effective elevation input Vs_eff).
A = zeros(6);  A(1,2) = 1;  A(3,4) = 1;  A(5,6) = 1;  A(6,1) = K3;
B = zeros(6,2);  B(2,2) = K1;  B(4,1) = K2;
C = eye(6);  C = C([1 2 3 4 6], :);
G = zeros(6,3);  G(2,1) = 1;  G(4,2) = 1;  G(6,3) = 1;
M  = expm([A, G*Qw*G'; zeros(6), -A'] * Ts);
Qd = M(1:6, 7:12) * M(1:6, 1:6)';
if use_bias
    A  = blkdiag(A, zeros(3));   B = [B; zeros(3,2)];
    C  = [C, [1 0 0; 0 1 0; 0 0 0; 0 0 1; 0 0 0]];
    Qd = blkdiag(Qd, 1e-11*eye(3));      % same bias noise as kalman_setup.m
end
n  = size(A,1);
sd = c2d(ss(A, B, C, zeros(5,2)), Ts, 'zoh');
Ad = sd.A;  Bd = sd.B;  Cd = sd.C;  I = eye(n);

N = size(Y,1);  X = zeros(N, n);
xb = x0;  Pb = P0;
for k = 1:N
    if ND(k)
        L  = Pb*Cd' / (Cd*Pb*Cd' + Rd);
        xh = xb + L*(Y(k,:)' - Cd*xb);
        Ph = (I - L*Cd)*Pb*(I - L*Cd)' + L*Rd*L';
    else
        xh = xb;  Ph = Pb;
    end
    X(k,:) = xh';
    Vs_eff = (U(k,1) + V_s_0)*cos(xh(1)) - V_s_0*cos(xh(3));   % Tar hensyn til effektiv Vs
    xb = Ad*xh + Bd*[Vs_eff; U(k,2)];
    Pb = Ad*Ph*Ad' + Qd;
end
end
