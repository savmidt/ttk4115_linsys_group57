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

pole1 = -1+1i;
pole2 = -1-1i;

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

%% Lab 3 / Eulenberger observer
p1 = -45;
p2 = -54;
p3 = -2.3;
p4 = -2.7;
p5 = -63;
PORT = 3;
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


lab3_bias = [-0.100270783716092;
    0.000687801662524980;
    0.0895667537802179;
    -1.67193300374603e-05;
    -0.00100453343233165];

[imu_bias, gyro_bias] = update_imu_bias('bias_today.mat', lab3_bias);

%% Part IV - Kalman filter

