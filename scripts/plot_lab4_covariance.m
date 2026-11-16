%% plot_lab4_covariance.m
% Lab 4, task 3: diagonal of the Kalman error covariance P_hat during the
% IMU-disconnect test (lab4task3log_imufault.mat). The periods where
% new_data = 0 (IMU off) are shaded.
%
% Three stacked panels with a shared time axis:
%   angles  (p, e, lambda)
%   rates   (p_dot, e_dot, lambda_dot)
%   biases  (b_p, b_p_dot, b_e_dot)
%
% Output: figurer/lab4/lab4_task3_covariance.eps
% Requires MATLAB R2020a or newer (tiledlayout, exportgraphics).

clear; close all; clc;

%% ------------------------------ Settings --------------------------------
cfg.file     = fullfile('logs', 'lab4task3log_imufault.mat');
cfg.figDir   = fullfile('figurer', 'lab4');
cfg.radToDeg = true;    % true if the states are logged in rad (P in rad^2)
cfg.logScale = true;    % log y-axis; the variances span several decades
cfg.minGap   = 0.1;     % [s] new_data = 0 for longer than this = IMU off
cfg.width    = 16;      % [cm] figure width (about \textwidth on A4)
cfg.height   = 14;      % [cm] figure height

idx.t   = 1;            % time row
idx.new = 7;            % new_data row
% P_hat_diag is the last 9 rows, in the Kalman state order:
% p, p_dot, e, e_dot, lambda, lambda_dot, b_p, b_p_dot, b_e_dot

% Units of each variance
if cfg.radToDeg; a = 'deg'; else; a = 'rad'; end
pName = {'\hat{P}_{p}', '\hat{P}_{\dot{p}}', '\hat{P}_{e}', ...
         '\hat{P}_{\dot{e}}', '\hat{P}_{\lambda}', '\hat{P}_{\dot{\lambda}}', ...
         '\hat{P}_{b_p}', '\hat{P}_{b_{\dot{p}}}', '\hat{P}_{b_{\dot{e}}}'};

% Panels: which P elements, and the y-label
panel(1).rows = [1 3 5];  panel(1).ylab = sprintf('Angles [%s$^2$]', a);
panel(2).rows = [2 4 6];  panel(2).ylab = sprintf('Rates [(%s/s)$^2$]', a);
panel(3).rows = [7 8 9];  panel(3).ylab = 'Biases';

col.lines = [0.00 0.45 0.74;      % first state in each panel
             0.85 0.33 0.10;      % second
             0.47 0.67 0.19];     % third
col.off   = [0.90 0.90 0.90];
lw        = 1.2;

set(groot, 'defaultTextInterpreter', 'latex', ...
           'defaultLegendInterpreter', 'latex', ...
           'defaultAxesTickLabelInterpreter', 'latex', ...
           'defaultAxesFontSize', 9, ...
           'defaultLegendFontSize', 8);

if ~exist(cfg.figDir, 'dir'); mkdir(cfg.figDir); end

%% -------------------------------- Load ----------------------------------
raw = load(cfg.file);
fn = fieldnames(raw);
d = raw.(fn{1});
if isa(d, 'timeseries')
    d = [d.Time(:)'; squeeze(d.Data)'];
end
if size(d, 1) > size(d, 2); d = d'; end          % one row per signal
fprintf('%s: %d rows, using the last 9 as P_hat.\n', cfg.file, size(d, 1));

t       = d(idx.t, :);
newData = d(idx.new, :);
P       = d(end-8:end, :);
if cfg.radToDeg
    P = (180/pi)^2 * P;                          % variance scales with k^2
end

off = offIntervals(t, newData, cfg.minGap);
fprintf('IMU off in %d interval(s).\n', size(off, 1));

%% -------------------------------- Plot ----------------------------------
fig = figure('Units', 'centimeters', 'Color', 'w', ...
             'Position', [2 2 cfg.width cfg.height]);
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

for r = 1:3
    ax = nexttile(tl);
    hold(ax, 'on');
    rows = panel(r).rows;
    h = gobjects(1, numel(rows));
    for j = 1:numel(rows)
        y = P(rows(j), :);
        if cfg.logScale; y(y <= 0) = NaN; end     % log axis cannot show <= 0
        h(j) = plot(ax, t, y, 'Color', col.lines(j, :), 'LineWidth', lw);
    end
    if cfg.logScale; set(ax, 'YScale', 'log'); end
    box(ax, 'on'); grid(ax, 'on');
    xlim(ax, [t(1) t(end)]);
    set(ax, 'Layer', 'top', 'LineWidth', 0.5);
    ax.Toolbar.Visible = 'off';

    % Shade IMU-off periods behind the lines (opaque, so the .eps stays vector)
    yl = ylim(ax);
    hp = gobjects(0);
    for k = 1:size(off, 1)
        hp = patch(ax, off(k, [1 2 2 1]), yl([1 1 2 2]), col.off, ...
                   'EdgeColor', 'none');
        uistack(hp, 'bottom');
    end
    ylim(ax, yl);

    ylabel(ax, panel(r).ylab);
    if r == 3; xlabel(ax, 'Time [s]'); end

    names = strcat('$', pName(rows), '$');
    if ~isempty(hp)
        legend(ax, [hp h], ['IMU off', names], 'Location', 'northeastoutside', ...
               'Box', 'off');
    else
        legend(ax, h, names, 'Location', 'northeastoutside', 'Box', 'off');
    end
end
linkaxes(findobj(fig, 'Type', 'axes'), 'x');

out = fullfile(cfg.figDir, 'lab4_task3_covariance.eps');
exportgraphics(fig, out, 'ContentType', 'vector');
fprintf('Saved %s\n', out);

%% ============================ Local functions ===========================
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