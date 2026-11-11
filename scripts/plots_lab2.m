%% Lab 2 - LQR: plott av helikopterdata
% Kjør fra mappen Innlevering. Datafilene ligger i logs/lab2*.mat
%
% Kolonner i datafilene:
%  1 t   2 travel   3 travel_dot   4 pitch   5 pitch_dot   6 elevation
%  7 elevation_dot   8 X_ref (pitch-ref)   9 Y_ref (elev.rate-ref)   10 V_s   11 V_d

clear; close all; clc;

saveFigs = true;
figDir   = fullfile('figurer', 'lab2');
if saveFigs && ~exist(figDir, 'dir'), mkdir(figDir); end

files = dir(fullfile('logs', 'part2*.mat'));

stateNames = {'\lambda', '\dot{\lambda}', 'p', '\dot{p}', 'e', '\dot{e}'};
stateCol   = [2 3 4 5 6 7];
tileOrder  = [3 4 5 6 1 2];   % rekkefølge i figuren: p, pdot, e, edot, travel, travel_dot

rmsErr    = zeros(numel(files), 2);   % [pitch-feil, elev.rate-feil]
testNames = cell(numel(files), 1);

for k = 1:numel(files)
    % --- Last inn data ---
    S = load(fullfile(files(k).folder, files(k).name));
    fn = fieldnames(S);
    d = S.(fn{1});
    if isa(d, 'timeseries'), d = [d.Time, d.Data]; end
    if size(d,1) == 11, d = d.'; end     % To File lagrer signaler som rader
    t = d(:,1);

    [~, testNames{k}] = fileparts(files(k).name);

    % --- Figur: tilstander + pådrag ---
    fig = figure('Name', testNames{k}, 'Position', [100 100 900 850]);
    tiledlayout(4, 2, 'TileSpacing', 'compact');

    for i = tileOrder
        nexttile; hold on; grid on;
        plot(t, d(:,stateCol(i)), 'DisplayName', 'Måling');
        if i == 3, plot(t, d(:,8), 'k:', 'LineWidth', 1.2, 'DisplayName', 'Referanse'); end
        if i == 6, plot(t, d(:,9), 'k:', 'LineWidth', 1.2, 'DisplayName', 'Referanse'); end
        ylabel(['$' stateNames{i} '$'], 'Interpreter', 'latex');
        if i == 3 || i == 6, legend('Location', 'best'); end
    end

    nexttile([1 2]); hold on; grid on;
    plot(t, d(:,10), 'DisplayName', '$\tilde{V}_s$');
    plot(t, d(:,11), 'DisplayName', '$V_d$');
    ylabel('Spenning [V]');
    legend('Interpreter', 'latex', 'Location', 'best');

    xlabel(findall(fig, 'Type', 'axes'), 'Tid [s]');
    sgtitle(testNames{k}, 'Interpreter', 'none');

    rmsErr(k,1) = sqrt(mean((d(:,4) - d(:,8)).^2));   % p - p_ref
    rmsErr(k,2) = sqrt(mean((d(:,7) - d(:,9)).^2));   % edot - edot_ref

    if saveFigs, exportgraphics(fig, fullfile(figDir, [testNames{k} '.pdf'])); end
end

%% Sammenligning: RMS av følgefeil for alle tester
fig = figure('Name', 'RMS følgefeil', 'Position', [100 100 900 350]);
tiledlayout(1, 2, 'TileSpacing', 'compact');
errNames = {'p - p_{ref}', '\dot{e} - \dot{e}_{ref}'};
for i = 1:2
    nexttile;
    bar(categorical(testNames, testNames), rmsErr(:,i));
    set(gca, 'TickLabelInterpreter', 'none');
    title(['RMS$(' errNames{i} ')$'], 'Interpreter', 'latex');
    grid on;
end
if saveFigs, exportgraphics(fig, fullfile(figDir, 'rms_sammenligning.pdf')); end

disp(array2table(rmsErr, 'RowNames', testNames, ...
    'VariableNames', {'pitch_err', 'edot_err'}));