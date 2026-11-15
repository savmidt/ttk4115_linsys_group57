function [Rd, noise] = estimate_Rd(Y_imu, new_data, Y_enc)
% Estimerer kovariansen i målestøyet
% Y_imu    : N x 5 IMU [p pdot e edot lambdadot] (etter transformasjon + bias fiks)
% new_data : N x 1 new-data flagg fra IMU
% Y_enc    : N x 5 Encoder verdier. Støy = IMU - encoder,
%
% Data fra "To File" block (Array format)
% d = data';  Y_imu = d(:,2:6);  new_data = d(:,7); ...

idx = new_data > 0.5;                   % Kun nye IMU samples (holder verdien mellom)
if nargin < 3
    noise = Y_imu(idx,:) - mean(Y_imu(idx,:));
else
    noise = Y_imu(idx,:) - Y_enc(idx,:);
    noise = noise - mean(noise);        % bias, ikke støy
end
Rd = cov(noise);                        % en kolonne per måling, en rad per sample

names = {'p','p_{dot}','e','e_{dot}','\lambda_{dot}'};
figure;
for i = 1:5
    subplot(2,5,i);   histogram(noise(:,i), 50); title(names{i});
    subplot(2,5,5+i); [r,lags] = xcorr(noise(:,i), 50, 'coeff'); stem(lags, r, '.');
    title(['autocorr ' names{i}]); xlabel('lag [samples]');
end
end
