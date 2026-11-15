%% plot_lab4.m
% Lab 4 (Kalman filter), task 3: plots (.eps) and RMSE tables (.tex).
%
%   lab4task3logtest*.mat      -> one figure per test + RMSE tables
%   lab4task3log_imufault.mat  -> pitch / elevation-rate figure with the
%                                 periods without IMU data shaded
%
% Output folder: figurer/lab4
% Requires MATLAB R2020a or newer (tiledlayout, exportgraphics).

clear; close all; clc;

%% ------------------------------ Settings --------------------------------
cfg.dataDir  = '.';                          % folder with the .mat files
cfg.figDir   = fullfile('figurer', 'lab4');  % output folder
cfg.radToDeg = true;    % true if the logged angles/rates are in rad
cfg.tStart   = 5;       % [s] samples before this are left out of the RMSE
                        %     (the IMU delivers nothing for the first ~4 s)
cfg.minGap   = 0.1;     % [s] new_data = 0 for longer than this = IMU off
cfg.width    = 16;      % [cm] figure width (about \textwidth on A4)

% Row layout of the logged array (row 1 is time, then the mux top to bottom)
idx.t    = 1;
idx.imu  = 2:6;      % IMU:     p, p_dot, e, e_dot, lambda_dot
idx.new  = 7;        % new_data
idx.enc  = 8:16;     % encoder: p, p_dot, e, e_dot, lambda, lambda_dot + 3 zeros
idx.kf   = 17:25;    % Kalman:  the six states + three bias states
idx.u    = 26:27;    % Vs, Vd
idx.xref = 28;       % pitch reference
idx.yref = 29;       % elevation-rate reference
nRowsExpected = [29 38];  % without / with P_hat_diag (9)

imuState = [1 2 3 4 6];   % which of the six states each IMU row measures

% Colours: the noisiest signal is light and drawn first, reference last
col.imu = [0.62 0.74 0.86];
col.enc = [0.00 0.45 0.74];
col.kf  = [0.85 0.33 0.10];
col.ref = [0.00 0.00 0.00];
col.off = [0.90 0.90 0.90];

stateName = {'p', '\dot{p}', 'e', '\dot{e}', '\lambda', '\dot{\lambda}'};
stateUnit = {'deg', 'deg/s', 'deg', 'deg/s', 'deg', 'deg/s'};
if ~cfg.radToDeg
    stateUnit = {'rad', 'rad/s', 'rad', 'rad/s', 'rad', 'rad/s'};
end

set(groot, 'defaultTextInterpreter', 'latex', ...
           'defaultLegendInterpreter', 'latex', ...
           'defaultAxesTickLabelInterpreter', 'latex', ...
           'defaultAxesFontSize', 9, ...
           'defaultLegendFontSize', 8);

if ~exist(cfg.figDir, 'dir'); mkdir(cfg.figDir); end

%% --------------------------- Test-case files ----------------------------
files = dir(fullfile(cfg.dataDir, 'lab4task3logtest*.mat'));
if isempty(files)
    warning('No files matching lab4task3logtest*.mat in "%s".', cfg.dataDir);
end

% Label = whatever follows "logtest" in the file name; sort numerically
labels = cell(numel(files), 1);
for k = 1:numel(files)
    tok = regexp(files(k).name, 'logtest(.*)\.mat$', 'tokens', 'once');
    labels{k} = tok{1};
end
num = str2double(labels);
if ~isempty(num) && all(~isnan(num))
    [~, order] = sort(num);
    files = files(order);
    labels = labels(order);
end

rmseKF  = nan(numel(files), 6);   % Kalman estimate vs encoder
rmseIMU = nan(numel(files), 6);   % IMU measurement vs encoder

for k = 1:numel(files)
    S = loadLog(fullfile(files(k).folder, files(k).name), idx, ...
                nRowsExpected, cfg.radToDeg);

    % ---- RMSE with the encoder as ground truth ----
    use = S.t >= cfg.tStart;
    for s = 1:6
        rmseKF(k, s) = rmse(S.kf(s, use), S.enc(s, use));
    end
    for m = 1:5
        s = imuState(m);
        rmseIMU(k, s) = rmse(S.imu(m, use), S.enc(s, use));
    end

    % ---- Figure: angles in the left column, rates in the right ----
    fig = newFigure(cfg.width, 13);
    tl = tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    tileOf = [1 2 3 4 5 6];       % p, p_dot / e, e_dot / lambda, lambda_dot
    for s = 1:6
        ax = nexttile(tl, tileOf(s));
        hold(ax, 'on');
        h = gobjects(1, 4);
        m = find(imuState == s);
        if ~isempty(m)
            h(1) = plot(ax, S.t, S.imu(m, :), 'Color', col.imu, 'LineWidth', 0.5);
        end
        h(2) = plot(ax, S.t, S.enc(s, :), 'Color', col.enc, 'LineWidth', 0.8);
        h(3) = plot(ax, S.t, S.kf(s, :),  'Color', col.kf,  'LineWidth', 1.0);
        if s == 1
            h(4) = plot(ax, S.t, S.xref, '--', 'Color', col.ref, 'LineWidth', 1.0);
        elseif s == 4
            h(4) = plot(ax, S.t, S.yref, '--', 'Color', col.ref, 'LineWidth', 1.0);
        end
        styleAxes(ax, S.t);
        ylabel(ax, sprintf('$%s$ [%s]', stateName{s}, stateUnit{s}));
        if s >= 5; xlabel(ax, 'Time [s]'); end
        if s == 1
            lg = legend(ax, h, {'IMU', 'Encoder', 'Kalman', 'Reference'}, ...
                        'Orientation', 'horizontal', 'Box', 'off');
            lg.Layout.Tile = 'north';
        end
    end
    saveEps(fig, fullfile(cfg.figDir, sprintf('lab4_task3_test%s.eps', labels{k})));
end

%% ----------------------------- RMSE tables ------------------------------
if ~isempty(files)
    varNames = {'p', 'p_dot', 'e', 'e_dot', 'lambda', 'lambda_dot'};
    fprintf('\nRMSE, Kalman estimate vs encoder [%s, %s]:\n', stateUnit{1}, stateUnit{2});
    disp(array2table(rmseKF, 'VariableNames', varNames, 'RowNames', labels));
    fprintf('RMSE, IMU measurement vs encoder [%s, %s]:\n', stateUnit{1}, stateUnit{2});
    disp(array2table(rmseIMU, 'VariableNames', varNames, 'RowNames', labels));

    writeRmseTable(fullfile(cfg.figDir, 'rmse_kalman.tex'), rmseKF, labels, ...
        stateName, stateUnit, ...
        'RMSE between the Kalman filter estimate and the encoder values.', ...
        'tab:lab4_rmse_kalman');
    writeRmseTable(fullfile(cfg.figDir, 'rmse_imu.tex'), rmseIMU, labels, ...
        stateName, stateUnit, ...
        'RMSE between the IMU measurements and the encoder values.', ...
        'tab:lab4_rmse_imu');
end

%% ---------------------------- IMU-fault file ----------------------------
faultFile = fullfile(cfg.dataDir, 'lab4task3log_imufault.mat');
if exist(faultFile, 'file')
    S = loadLog(faultFile, idx, nRowsExpected, cfg.radToDeg);
    off = offIntervals(S.t, S.newData, cfg.minGap);
    fprintf('IMU off in %d interval(s):\n', size(off, 1));
    fprintf('   %7.2f s  to %7.2f s\n', off');

    fig = newFigure(cfg.width, 10);
    tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    panelState = [1 4];                    % pitch and elevation rate
    panelRef   = {S.xref, S.yref};
    for r = 1:2
        s = panelState(r);
        m = find(imuState == s);
        ax = nexttile(tl);
        hold(ax, 'on');
        h = gobjects(1, 5);
        h(2) = plot(ax, S.t, S.imu(m, :), 'Color', col.imu, 'LineWidth', 0.5);
        h(3) = plot(ax, S.t, S.enc(s, :), 'Color', col.enc, 'LineWidth', 0.8);
        h(4) = plot(ax, S.t, S.kf(s, :),  'Color', col.kf,  'LineWidth', 1.0);
        h(5) = plot(ax, S.t, panelRef{r}, '--', 'Color', col.ref, 'LineWidth', 1.0);
        styleAxes(ax, S.t);
        yl = ylim(ax);
        for j = 1:size(off, 1)             % opaque patches keep the .eps vector
            hp = patch(ax, off(j, [1 2 2 1]), yl([1 1 2 2]), col.off, ...
                       'EdgeColor', 'none');
            uistack(hp, 'bottom');
            h(1) = hp;
        end
        ylim(ax, yl);
        ylabel(ax, sprintf('$%s$ [%s]', stateName{s}, stateUnit{s}));
        if r == 2; xlabel(ax, 'Time [s]'); end
        if r == 1
            names = {'IMU off', 'IMU', 'Encoder', 'Kalman', 'Reference'};
            keep = isgraphics(h);
            lg = legend(ax, h(keep), names(keep), ...
                        'Orientation', 'horizontal', 'Box', 'off');
            lg.Layout.Tile = 'north';
        end
    end
    saveEps(fig, fullfile(cfg.figDir, 'lab4_task3_imufault.eps'));
else
    warning('Did not find %s.', faultFile);
end

fprintf('\nDone. Output written to %s\n', cfg.figDir);

%% ============================ Local functions ===========================
function S = loadLog(file, idx, nRowsExpected, radToDeg)
% Loads a "To File" log (array or timeseries format) and splits the rows.
    raw = load(file);
    fn = fieldnames(raw);
    d = raw.(fn{1});
    if isa(d, 'timeseries')
        d = [d.Time(:)'; squeeze(d.Data)'];
    end
    if size(d, 1) > size(d, 2); d = d'; end          % one row per signal
    if size(d, 1) < idx.yref
        error('%s has %d rows, expected at least %d. Check the idx layout.', ...
              file, size(d, 1), idx.yref);
    elseif ~ismember(size(d, 1), nRowsExpected)
        warning('%s has %d rows, expected %s. Check the idx layout.', ...
                file, size(d, 1), mat2str(nRowsExpected));
    end
    k = 1;
    if radToDeg; k = 180/pi; end
    S.t       = d(idx.t, :);
    S.imu     = k * d(idx.imu, :);
    S.newData = d(idx.new, :);
    S.enc     = k * d(idx.enc, :);
    S.kf      = k * d(idx.kf, :);
    S.u       = d(idx.u, :);
    S.xref    = k * d(idx.xref, :);
    S.yref    = k * d(idx.yref, :);
end

function e = rmse(a, b)
    e = sqrt(mean((a - b).^2, 'omitnan'));
end

function iv = offIntervals(t, newData, minGap)
% Start/stop times of the periods where new_data stays 0 longer than minGap.
% (The IMU is slower than Simulink, so short runs of zeros are normal.)
    isOff = newData(:)' < 0.5;
    d = diff([0 isOff 0]);
    iStart = find(d == 1);
    iStop  = find(d == -1) - 1;
    iv = [t(iStart)', t(iStop)'];
    iv = iv(iv(:, 2) - iv(:, 1) >= minGap, :);
end

function fig = newFigure(widthCm, heightCm)
    fig = figure('Units', 'centimeters', 'Color', 'w', ...
                 'Position', [2 2 widthCm heightCm]);
end

function styleAxes(ax, t)
    box(ax, 'on'); grid(ax, 'on');
    xlim(ax, [t(1) t(end)]);
    set(ax, 'Layer', 'top', 'LineWidth', 0.5);
    ax.Toolbar.Visible = 'off';
end

function saveEps(fig, file)
    exportgraphics(fig, file, 'ContentType', 'vector');
    fprintf('Saved %s\n', file);
end

function writeRmseTable(file, R, labels, stateName, stateUnit, capText, lbl)
% Writes a booktabs table (needs \usepackage{booktabs} in the report).
    fid = fopen(file, 'w');
    fprintf(fid, '\\begin{table}[htbp]\n  \\centering\n');
    fprintf(fid, '  \\caption{%s}\n  \\label{%s}\n', capText, lbl);
    fprintf(fid, '  \\begin{tabular}{l%s}\n    \\toprule\n', repmat('r', 1, size(R, 2)));
    fprintf(fid, '    Test');
    for s = 1:size(R, 2)
        fprintf(fid, ' & $%s$ [%s]', stateName{s}, stateUnit{s});
    end
    fprintf(fid, ' \\\\\n    \\midrule\n');
    for k = 1:size(R, 1)
        fprintf(fid, '    %s', strrep(labels{k}, '_', '\_'));
        for s = 1:size(R, 2)
            if isnan(R(k, s))
                fprintf(fid, ' & --');
            else
                fprintf(fid, ' & %.3f', R(k, s));
            end
        end
        fprintf(fid, ' \\\\\n');
    end
    fprintf(fid, '    \\bottomrule\n  \\end{tabular}\n\\end{table}\n');
    fclose(fid);
end