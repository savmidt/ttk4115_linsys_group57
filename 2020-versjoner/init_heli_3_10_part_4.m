% FOR HELICOPTER NR 3-10
% This file contains the initialization for the helicopter assignment in
% the course TTK4115. Run this file before you execute QuaRC_ -> Build 
% to build the file heli_q8.mdl.

% Oppdatert høsten 2006 av Jostein Bakkeheim
% Oppdatert høsten 2008 av Arnfinn Aas Eielsen
% Oppdatert høsten 2009 av Jonathan Ronen
% Updated fall 2010, Dominik Breu
% Updated fall 2013, Mark Haring
% Updated spring 2015, Mark Haring


%%%%%%%%%%% Calibration of the encoder and the hardware for the specific
%%%%%%%%%%% helicopter
Joystick_gain_x = 1;
Joystick_gain_y = -1;


%%%%%%%%%%% Physical constants
g = 9.81; % gravitational constant [m/s^2]
l_c = 0.46; % distance elevation axis to counterweight [m]
l_h = 0.66; % distance elevation axis to helicopter head [m]
l_p = 0.175; % distance pitch axis to motor [m]
m_c = 1.92; % Counterweight mass [kg]
m_p = 0.72; % Motor mass [kg]

PORT = 6;  % Heli 10
%PORT = 5;   % Heli 6

V_s_0 = 7.77;
K_f = (-l_c * m_c * g + 2 * l_h * m_p * g) / (V_s_0 * l_h);

L1 = K_f * l_p;
L2 = l_c * m_c * g - 2 * l_h * m_p * g;
L3 = K_f * l_h;
L4 = K_f * l_h;

J_p = 2*m_p*l_p^2;
J_e = m_c*l_c^2 + 2*m_p*l_h^2;
J_l = m_c*l_c^2 + 2*m_p*(l_h^2 + l_p^2);

K1 = L1 / J_p;
K2 = L3 / J_e;
K3 = -L2*L4 / (L3*J_l);

% constant added to elevation:
elev_const = 0.53;

pole1 = -1;
pole2 = -10;

K_pd = -(pole1 + pole2) / K1;
K_pp = pole1*pole2 / K1;

%%
% Part 2 - Multivariable control
% Problem 1
q1 = 5;
q2 = 0.5;
q3 = 10;
r1 = 0.1;
r2 = 0.1;
Q_lqr = eye(3).*[q1 q2 q3];

R_lqr = eye(2).*[r1 r2];

A = [0 1 0
     0 0 0
     0 0 0];
B = [0 0
     0 K1
     K2 0];


K_1 = lqr(A,B, Q_lqr, R_lqr)
F_1 = [K_1(1,1) K_1(1,3)
       K_1(2,1) K_1(2,3)]
 
 % Problem 2
A_lqr = [0 1 0 0 0
     0 0 0 0 0
     0 0 0 0 0
     -1 0 0 0 0
     0 0 -1 0 0];
B_lqr = [0 0
     0 K1
     K2 0
     0 0
     0 0];

G_2 = [0 0
     0 0
     0 0
     1 0
     0 1];
 
q1 = 10;
q2 = 0.5;
q3 = 10;
q4 = 2;
q5 = 5;
r1 = 0.1;
r2 = 0.1;  
Q_lqr = diag([q1 q2 q3 q4 q5]);
R_lqr = diag([r1 r2]);

K_2 = lqr(A_lqr,B_lqr,Q_lqr, R_lqr)
F_2 = [K_2(1,1) K_2(1,3)
       K_2(2,1) K_2(2,3)]

%% Lab 3 / Luenberger observer
p1 = -45;
p2 = -54;
p3 = -2.3;
p4 = -2.7;
p5 = -63;


A_est = [0 1 0 0 0
         0 0 0 0 0
         0 0 0 1 0
         0 0 0 0 0
         K3 0 0 0 0];
 
B_est = [0  0
          0  K1
          0  0
          K2 0
          0  0];
 
C_est = eye(5);
 
%  C_est = [0 0 1 0 0
%           0 0 0 0 1]; % minimal states viable, for tests 8 and 9
 
p_est = transpose([p1 p2 p3 p4 p5]);
L_est = transpose(place(transpose(A_est),transpose(C_est),p_est));


lab3_bias = [-0.0918732538603325;
    0.0392850152532825;
    0.0496947738020852;
    -0.00867648252982556;
    0.000660862987063704];


[imu_bias, gyro_bias] = update_imu_bias('bias_today.mat', lab3_bias);

%% Part IV - Kalman filter

use_bias = true;

Ts = 0.002;

fc_acc = 3;
fc_gyro = 15;

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
Qd6 = diag([1e3, 1e3, 1e3, 1e3, 1e3, 1e3]);   % tunes
G  = [0 0 0; 1 0 0; 0 0 0; 0 1 0; 0 0 0; 0 0 1];   % støy på p_ddot, e_ddot, lambda_ddot
% Qw = diag([1e-2, 1, 1]);  % Test
Qw = diag([3e-3, 3e-4, 3e-4]);  % Etter tuning

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
    Qd = blkdiag(Qd6, 1e-11*eye(3));      % tiny noise: biases drift slowly
    x0 = [x0; 0; 0; 0];                   % calibration already removed most of the bias
    P0 = blkdiag(P0, 0.02^2*eye(3));      % initial bias uncertainty
else
    Qd = Qd6;
end
n = size(A,1);


%% Diskretisering

sysd = c2d(ss(A, B, C, zeros(5,2)), Ts, 'zoh');
Ad = sysd.A;  Bd = sysd.B;  Cd = sysd.C;
fprintf('%d states, rank(obsv) = %d \n', n, rank(obsv(Ad,Cd)));

%% IMU bias

load('imu_bias.mat', 'imu_bias', 'gyro_bias');

%% Rd

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
