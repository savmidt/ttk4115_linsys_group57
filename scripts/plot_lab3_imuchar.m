%% plot_lab3_imu_characteristics.m
% Lab 3 (Luenberger observer), task 1: IMU characteristics.
% 3x3 figure from the imu_characteristics log, following the assignment:
%   row 1: encoder angles vs IMU angles        p, e, lambda
%   row 2: gyroscope vs encoder rates          p_dot, e_dot, lambda_dot
%   row 3: accelerometer by itself             a_x, a_y, a_z
%
% The IMU does not measure the travel angle, so the lambda panel in row 1
% shows the encoder only.
%
% Output: figurer/lab3/lab3_task1_imu_characteristics.eps
% Requires MATLAB R2020a or newer (tiledlayout, exportgraphics).

clear; close all; clc;

%% ------------------------------ Settings --------------------------------
cfg.dataDir  = fullfile('logs');                 % folder with the .mat file
cfg.pattern  = '*imu_characteristics*.mat';      % file name pattern
cfg.figDir   = fullfile('figurer', 'lab3');      % output folder
cfg.radToDeg = true;    % true if angles, rates and gyro are logged in rad
cfg.tSkip    = 1;       % [s] skip this much at the start (derivative kick)
cfg.width    = 16;      % [cm] figure width (about \textwidth on A4)
cfg.height   = 12;      % [cm] figure height

% Which raw gyro axis (1 = x, 2 = y, 3 = z) and sign belongs to each of
% p_dot, e_dot, lambda_dot. Leave gyroMap empty to pick it automatically
% from the data (the axis/sign that correlates best with each encoder
% rate); the choice is printed so you can check it against the IMU frame.
cfg.gyroMap  = [];      % e.g. [1 2 3]
cfg.gyroSign = [];      % e.g. [1 -1 -1]

% Row layout of the logged array (row 1 is time)
idx.t     = 1;
idx.enc   = 2:7;     % encoder: p, p_dot, e, e_dot, lambda, lambda_dot
idx.imu   = 8:12;    % IMU:     p, p_dot, e, e_dot, lambda_dot
idx.accel = 13:15;   % a_x, a_y, a_z
idx.gyro  = 16:18;   % omega_x, omega_y, omega_z
nRowsExpected = 18;

col.enc   = [0.00 0.45 0.74];
col.imu   = [0.85 0.33 0.10];
col.accel = [0.47 0.67 0.19];
lw = 1.0;

if cfg.radToDeg; a = 'deg'; else; a = 'rad'; end
axisName = {'x', 'y', 'z'};

set(groot, 'defaultTextInterpreter', 'latex', ...
           'defaultLegendInterpreter', 'latex', ...
           'defaultAxesTickLabelInterpreter', 'latex', ...
           'defaultAxesFontSize', 9, ...
           'defaultLegendFontSize', 8);

if ~exist(cfg.figDir, 'dir'); mkdir(cfg.figDir); end

%% -------------------------------- Load ----------------------------------
files = dir(fullfile(cfg.dataDir, cfg.pattern));
if isempty(files)
    error('No file matching %s in "%s".', cfg.pattern, cfg.dataDir);
end
file = fullfile(files(1).folder, files(1).name);

raw = load(file);
fn = fieldnames(raw);
d = raw.(fn{1});
if isa(d, 'timeseries')
    d = [d.Time(:)'; squeeze(d.Data)'];
end
if size(d, 1) > size(d, 2); d = d'; end          % one row per signal
fprintf('%s: %d rows.\n', file, size(d, 1));
if size(d, 1) ~= nRowsExpected
    error('Expected %d rows. Check the idx layout.', nRowsExpected);
end

% Drop the start (encoder derivative kick) from every signal at once
d = d(:, d(idx.t, :) >= cfg.tSkip);

k = 1;
if cfg.radToDeg; k = 180/pi; end
t     = d(idx.t, :);
enc   = k * d(idx.enc, :);       % p, p_dot, e, e_dot, lambda, lambda_dot
imu   = k * d(idx.imu, :);       % p, p_dot, e, e_dot, lambda_dot
accel = d(idx.accel, :);         % left in the logged unit
gyro  = k * d(idx.gyro, :);

%% ------------------------- Gyro axis assignment -------------------------
encRate = enc([2 4 6], :);       % p_dot, e_dot, lambda_dot
if isempty(cfg.gyroMap)
    [cfg.gyroMap, cfg.gyroSign] = matchAxes(gyro, encRate);
elseif isempty(cfg.gyroSign)
    cfg.gyroSign = [1 1 1];
end
rateName = {'\dot{p}', '\dot{e}', '\dot{\lambda}'};
fprintf('Gyro axes used:\n');
for c = 1:3
    sgn = '+'; if cfg.gyroSign(c) < 0; sgn = '-'; end
    fprintf('   %-12s <- %somega_%s\n', strrep(rateName{c}, '\', ''), ...
            sgn, axisName{cfg.gyroMap(c)});
end

%% -------------------------------- Plot ----------------------------------
fig = figure('Units', 'centimeters', 'Color', 'w', ...
             'Position', [2 2 cfg.width cfg.height]);
tl = tiledlayout(fig, 3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

% ---- Row 1: encoder angles vs IMU angles (noisiest at the back) ----
angEnc  = {enc(1, :), enc(3, :), enc(5, :)};
angImu  = {imu(1, :), imu(3, :), []};            % IMU has no travel angle
angName = {'p', 'e', '\lambda'};
for c = 1:3
    ax = nexttile(tl, c);
    hold(ax, 'on');
    h = gobjects(1, 2);
    sig  = {angEnc{c}, angImu{c}};
    cols = {col.enc, col.imu};
    for j = noiseOrder(sig, t)
        h(j) = plot(ax, t, sig{j}, 'Color', cols{j}, 'LineWidth', lw);
    end
    styleAxes(ax, t);
    ylabel(ax, sprintf('$%s$ [%s]', angName{c}, a));
    if c == 1
        lg = legend(ax, h, {'Encoder', 'IMU'}, ...
                    'Orientation', 'horizontal', 'Box', 'off');
        lg.Layout.Tile = 'north';
    end
end

% ---- Row 2: gyroscope vs encoder rates (noisiest at the back) ----
for c = 1:3
    ax = nexttile(tl, 3 + c);
    hold(ax, 'on');
    g = cfg.gyroSign(c) * gyro(cfg.gyroMap(c), :);
    sig  = {encRate(c, :), g};
    cols = {col.enc, col.imu};
    for j = noiseOrder(sig, t)
        plot(ax, t, sig{j}, 'Color', cols{j}, 'LineWidth', lw);
    end
    styleAxes(ax, t);
    ylabel(ax, sprintf('$%s$ [%s/s]', rateName{c}, a));
end

% ---- Row 3: accelerometer by itself ----
for c = 1:3
    ax = nexttile(tl, 6 + c);
    plot(ax, t, accel(c, :), 'Color', col.accel, 'LineWidth', lw);
    styleAxes(ax, t);
    ylabel(ax, sprintf('$a_%s$ [m/s$^2$]', axisName{c}));
    xlabel(ax, 'Time [s]');
end

out = fullfile(cfg.figDir, 'lab3_task1_imu_characteristics.eps');
exportgraphics(fig, out, 'ContentType', 'vector');
fprintf('Saved %s\n', out);

%% ============================ Local functions ===========================
function styleAxes(ax, t)
    box(ax, 'on'); grid(ax, 'on');
    xlim(ax, [t(1) t(end)]);
    set(ax, 'Layer', 'top', 'LineWidth', 0.5);
    ax.Toolbar.Visible = 'off';
end

function [map, sgn] = matchAxes(gyro, encRate)
% For each encoder rate, the gyro axis and sign with the highest
% correlation, each gyro axis used once.
    R = zeros(3);                                    % rate x gyro axis
    for i = 1:3
        for j = 1:3
            ok = isfinite(encRate(i, :)) & isfinite(gyro(j, :));
            C = corrcoef(encRate(i, ok), gyro(j, ok));
            R(i, j) = C(1, 2);
        end
    end
    map = zeros(1, 3); sgn = ones(1, 3);
    best = -inf;
    P = perms(1:3);
    for i = 1:size(P, 1)
        score = sum(abs(R(sub2ind([3 3], 1:3, P(i, :)))));
        if score > best; best = score; map = P(i, :); end
    end
    for c = 1:3
        if R(c, map(c)) < 0; sgn(c) = -1; end
    end
end

function order = noiseOrder(sig, t)
% Indices of the non-empty signals sorted from noisiest to smoothest.
% Noise is the spread of each signal around its own 0.5 s moving average.
    N = max(3, round(0.5 / median(diff(t))));
    noise = -inf(1, numel(sig));
    for j = 1:numel(sig)
        if ~isempty(sig{j})
            x = sig{j};
            noise(j) = std(x - movmean(x, N, 'omitnan'), 'omitnan');
        end
    end
    [noise, order] = sort(noise, 'descend');
    order = order(isfinite(noise));
end