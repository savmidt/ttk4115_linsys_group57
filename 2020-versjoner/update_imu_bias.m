function [imu_bias, gyro_bias] = update_imu_bias(logfile,initial)
%UPDATE_BIAS_IMU Summary of this function goes here
%   Detailed explanation goes here
gyro_bias = zeros(3,1);
if isfile('imu_bias.mat')
    load('imu_bias.mat', 'imu_bias');
else
    imu_bias = initial(:);
end
    
if isfile(logfile)
    S = load(logfile);  f = fieldnames(S); d = S.(f{1});
    if size(d,1) < size(d,2), d = d'; end
    idx = d(:,7) > 0.5;
    gyro_bias = mean(d(idx,13:15))'; %Bruker råverdi, derfor skal den ikke oppdateres men omskrives
    imu_bias = imu_bias + mean(d(idx,2:6) - d(idx,8:12))';
    imu_bias([2 4 5]) = 0;
    save('imu_bias.mat', 'imu_bias', 'gyro_bias');
    newname = sprintf('bias_used_%s.mat', char(datetime('now', 'Format', 'yyyy-MM-dd_HHmm')));
    movefile(logfile, newname);
    disp('IMU bias updated:');
end
disp(imu_bias'); disp(gyro_bias');
end

