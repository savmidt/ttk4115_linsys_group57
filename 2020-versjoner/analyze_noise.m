%% Analyse av støy for Rd
% To File-blokka: Save format = Array, Variable name = data
% Mux-rekkefolge: [y_imu(5); new_data(1); y_enc(5)]  ->  rad 1 = tid

%% Flygning (linjariseringspunkt)
load('fly_noise.mat');
d = fly_noise_data';
[Rd_fly, noise_fly] = estimate_Rd(d(:,2:6), d(:,7), d(:,8:12));
sgtitle('Støy under flygning');

%% På bakken (rotorer av)
load('ground_noise.mat');
d = ground_noise_data';
[Rd_ground, noise_ground] = estimate_Rd(d(:,2:6), d(:,7), d(:,8:12));
sgtitle('Støy på bakken');

%% Sammenlign standardavvik
disp(table(sqrt(diag(Rd_ground)), sqrt(diag(Rd_fly)), ...
     'VariableNames', {'std_bakke','std_flyvning'}, ...
     'RowNames', {'p','pdot','e','edot','lambdadot'}))

%% Bias (gjennomsnittlig IMU - enkoder) - kan brukes til å oppdatere bias-konstantene
d = fly_noise_data';
idx = d(:,7) > 0.5;
bias_fly = mean(d(idx,2:6) - d(idx,8:12))';

%% Lagre Rd til Kalman-filteret
Rd = Rd_fly;
save('Rd.mat', 'Rd');
fprintf('Rd lagret i Rd.mat\n');