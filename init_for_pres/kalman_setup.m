%% Lab 4

use_bias = true;

Ts = 0.002;

%% Kontinuerlig modell

A = [0  1  0  0  0  0;
     0  0  0  0  0  0;
     0  0  0  1  0  0;
     0  0  0  0  0  0;
     0  0  0  0  0  1;
     K3 0  0  0  0  0];
 
B = [0  0;
     0  K1;
     0  0;
     K2 0;
     0  0;
     0  0];

C = [1 0 0 0 0 0;
     0 1 0 0 0 0;
     0 0 1 0 0 0;
     0 0 0 1 0 0;
     0 0 0 0 0 1];

%% Prosesstøy kovarians Qd - tuning
Qd6 = diag([1e-6, 1e-3, 1e-6, 1e-3, 1e-6, 1e-3]);   % tunes

G  = [0 0 0; 1 0 0; 0 0 0; 0 1 0; 0 0 0; 0 0 1];   % støy på p_ddot, e_ddot, lambda_ddot
Qw = diag([3e0, 3e-4, 3e-6]);
M  = expm([A, G*Qw*G'; zeros(6), -A'] * Ts);
Qd_vanloan = M(1:6, 7:12) * M(1:6, 1:6)';
Qd6 = Qd_vanloan;

%% Initialverdier

e_rest = -0.53;                   % høyde ved start
x0 = [0; 0; e_rest; 0; 0; 0];
P0 = eye(6);
%% Bias states, y = C x + b,  b_dot = 0 (+ litt støy så de kan drifte)
% Estimerbarie biaser: b_p, b_pdot, b_edot. Bias på e og lambda_dot er ikke observerbare
% En bias kan bare estimeres hvis den gir et spor som er forskjellig fra en ekte endring i tilstanden.
%   b_ṗ (gyro): Anta at gyroen viser ṗ for høyt. Hvis filteret trodde det var ekte, måtte p ha økt jevnt over tid. 
%       Akselerometeret måler p direkte og ser ingen slik økning, så filteret skjønner at det er en bias. 
%       Det samme gjelder b_ė, som avsløres av den målte e.
%   b_p (akselerometer): Pitch påvirker travel gjennom λ̈ = K₃·p. En feil i p ville ha fått λ̇ til å drive, og λ̇ måles.
%       Derfor er b_p observerbar, men bare svakt. Den konvergerer derfor sakte, og bare når helikopteret faktisk beveger seg i travel.
%   Bias på e er ikke observerbar: Sett at e egentlig er e₀ + c og at biasen er −c. Da blir målingen den samme. 
%       e påvirker ingen andre tilstander (kolonne 3 i A er null), så det finnes ingen annen måling som kan avsløre forskjellen.
%   Bias på λ̇ er ikke observerbar av samme grunn. λ̇ påvirker bare λ, og λ måles ikke.

if use_bias
    A = blkdiag(A, zeros(3));
    B = [B; zeros(3,2)];
    C = [C, [1 0 0;      % p meas     + b_p
             0 1 0;      % pdot meas  + b_pdot
             0 0 0;      % e meas
             0 0 1;      % edot meas  + b_edot
             0 0 0]];    % lambdadot meas
    Qd = blkdiag(Qd6, 1e-11*eye(3));       % tiny noise: biases drift slowly
    x0 = [x0; 0; 0; 0];                   % calibration already removed most of the bias
    P0 = blkdiag(P0, 0.02^2*eye(3));      % initial bias uncertainty
else
    Qd = Qd6;
end
n = size(A,1);


%% Diskretisering

sysd = c2d(ss(A, B, C, zeros(5,2)), Ts, 'zoh');
Ad = sysd.A;  Bd = sysd.B;  Cd = sysd.C;
fprintf('%d states, rank(obsv) = %d (lambda is always unobservable)\n', n, rank(obsv(Ad,Cd)));

%% IMU bias

load('imu_bias.mat', 'imu_bias', 'gyro_bias');

%% Målestøy Rd: fra estimate_Rd.m

% if isfile('Rd.mat')
%     load('Rd.mat')            % målt Rd
% else
%     Rd = [0.00812480304466055,0.00127534589208997,5.61923873555641e-05,-0.00141001125716994,-0.000574355996342042;
%         0.00127534589208997,0.000624006150697616,-0.00123154513819189,-0.000177683123650412,-6.72706441455587e-05;
%         5.61923873555641e-05,-0.00123154513819189,0.0463630762097309,-0.00308130772057730,-0.000248066400126223;
%         -0.00141001125716994,-0.000177683123650412,-0.00308130772057730,0.000829942705044508,0.000129367202484110;
%         -0.000574355996342042,-6.72706441455587e-05,-0.000248066400126223,0.000129367202484110,0.000353581848805466];          % Målt 04.11
% end

%% Alternativ Rd

S = load('hover_full.mat'); f = fieldnames(S); d = S.(f{1});
if size(d,1) < size(d,2), d = d'; end
t   = d(:,1);   Y = d(:,2:6);   nd = d(:,7);
ENC = d(:, [8 9 10 11 13]);            % encoder [p pd e ed ld] - skip lambda (col 12)
KF  = d(:, 17:25);                     % Kalman, 9 states
m   = t > t(1) + 10;                   % skip take-off og start-up

% Ny Rd
[Rd, noise] = estimate_Rd(Y(m,:), nd(m), ENC(m,:));
disp(sqrt(diag(Rd))')                  % standardavvik
save('Rd.mat', 'Rd');

% Hvor er elevation offset?
idx = m & nd > 0.5;
fprintf('IMU_e - ENC_e : %+.4f rad\n', mean(Y(idx,3)  - ENC(idx,3)));
fprintf('KF_e  - ENC_e : %+.4f rad\n', mean(KF(idx,3) - ENC(idx,3)));
fprintf('IMU_ld - ENC_ld: %+.4f rad/s\n', mean(Y(idx,5) - ENC(idx,5)));