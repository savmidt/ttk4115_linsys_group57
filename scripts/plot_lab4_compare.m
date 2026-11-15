%% plot_lab4_compare.m
% Lab 4, task 3: encoder vs Kalman estimate for selected tests.
% One .eps per test with two stacked panels: pitch and elevation rate.
% Drawing order: encoder (back), Kalman estimate, reference (front).
%
% Output folder: figurer/lab4
% Requires MATLAB R2020a or newer (tiledlayout, exportgraphics).

clear; close all; clc;

%% ------------------------------ Settings --------------------------------
cfg.tests    = [1 2 6];                      % which tests to plot
cfg.dataDir  = fullfile('logs');                          % folder with the .mat files
cfg.figDir   = fullfile('figurer', 'lab4');  % output folder
cfg.radToDeg = true;    % true if the logged angles/rates are in rad
cfg.width    = 20;      % [cm] figure width (about \textwidth on A4)
cfg.height   = 9;       % [cm] figure height

% Row layout of the logged array (same as in plot_lab4.m)
idx.t    = 1;
idx.enc  = 8:16;     % encoder: p, p_dot, e, e_dot, lambda, lambda_dot + 3 zeros
idx.kf   = 17:25;    % Kalman:  the six states + three bias states
idx.xref = 28;       % pitch reference
idx.yref = 29;       % elevation-rate reference

col.enc = [0.00 0.45 0.74];
col.kf  = [0.85 0.33 0.10];
col.ref = [0.00 0.00 0.00];

% Line widths [pt]
lw.enc = 1.2;
lw.kf  = 1.5;
lw.ref = 1.5;

angUnit = 'deg';
if ~cfg.radToDeg; angUnit = 'rad'; end

set(groot, 'defaultTextInterpreter', 'latex', ...
           'defaultLegendInterpreter', 'latex', ...
           'defaultAxesTickLabelInterpreter', 'latex', ...
           'defaultAxesFontSize', 9, ...
           'defaultLegendFontSize', 8);

if ~exist(cfg.figDir, 'dir'); mkdir(cfg.figDir); end

%% -------------------------------- Plots ---------------------------------
for n = cfg.tests
    file = fullfile(cfg.dataDir, sprintf('lab4task3logtest%d.mat', n));
    if ~exist(file, 'file')
        warning('Did not find %s, skipping.', file);
        continue
    end

    % ---- Load (array or timeseries format) ----
    raw = load(file);
    fn = fieldnames(raw);
    d = raw.(fn{1});
    if isa(d, 'timeseries')
        d = [d.Time(:)'; squeeze(d.Data)'];
    end
    if size(d, 1) > size(d, 2); d = d'; end          % one row per signal
    if size(d, 1) < idx.yref
        error('%s has %d rows, expected at least %d.', file, size(d, 1), idx.yref);
    end
    k = 1;
    if cfg.radToDeg; k = 180/pi; end
    t   = d(idx.t, :);
    enc = k * d(idx.enc, :);
    kf  = k * d(idx.kf, :);
    ref = {k * d(idx.xref, :), k * d(idx.yref, :)};

    % ---- Figure: pitch on top, elevation rate below ----
    fig = figure('Units', 'centimeters', 'Color', 'w', ...
                 'Position', [2 2 cfg.width cfg.height]);
    tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    state = [1 4];                                    % p and e_dot
    ylab  = {sprintf('$p$ [%s]', angUnit), sprintf('$\\dot{e}$ [%s/s]', angUnit)};
    for r = 1:2
        s = state(r);
        ax = nexttile(tl);
        hold(ax, 'on');
        % Noisiest of encoder/Kalman is drawn first (at the back)
        sig  = {enc(s, :), kf(s, :)};
        cols = {col.enc, col.kf};
        lws  = [lw.enc, lw.kf];
        h = gobjects(1, 3);
        for j = noiseOrder(sig, t, {'Encoder', 'Kalman'})
            h(j) = plot(ax, t, sig{j}, 'Color', cols{j}, 'LineWidth', lws(j));
        end
        h(3) = plot(ax, t, ref{r}, '--', 'Color', col.ref, 'LineWidth', lw.ref);
        box(ax, 'on'); grid(ax, 'on');
        xlim(ax, [t(1) t(end)]);
        set(ax, 'Layer', 'top', 'LineWidth', 0.5);
        ax.Toolbar.Visible = 'off';
        ylabel(ax, ylab{r});
        if r == 2; xlabel(ax, 'Time [s]'); end
        if r == 1
            lg = legend(ax, h, {'Encoder', 'Kalman', 'Reference'}, ...
                        'Orientation', 'horizontal', 'Box', 'off');
            lg.Layout.Tile = 'north';
        end
    end

    out = fullfile(cfg.figDir, sprintf('lab4_task3_compare_test%d_alt.eps', n));
    exportgraphics(fig, out, 'ContentType', 'vector');
    fprintf('Saved %s\n', out);
end

%% ============================ Local functions ===========================
function order = noiseOrder(sig, t, names)
% Indices of the signals sorted from noisiest to smoothest. Noise is the
% spread of each signal around its own 0.5 s moving average: dense jitter
% (an oscillating estimate) scores high, while the occasional quantisation
% spike from the encoder scores low.
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
    fprintf('   back to front: %s\n', strjoin(names(order), ' -> '));
end