%% Lab 1 - plott av helikopterdata
% Kjør fra mappen Innlevering. Datafilene ligger i logs/lab1*.mat
%
% Kolonner i datafilene:
%  1 t   2 travel   3 travel_dot   4 pitch   5 pitch_dot
%  6 elevation   7 elevation_dot   8 X_ref   9 Y_ref

clear; close all; clc;

saveFigs = true;
figDir   = fullfile('figurer', 'lab1');
if saveFigs && ~exist(figDir, 'dir'), mkdir(figDir); end

files = dir(fullfile('logs', 'lab1*.mat'));

stateNames = {'\lambda', '\dot{\lambda}', 'p', '\dot{p}', 'e', '\dot{e}'};
stateCol   = [2 3 4 5 6 7];
tileOrder  = [3 4 5 6 1 2];   % rekkefølge i figuren: p, pdot, e, edot, travel, travel_dot

rmsPitchErr = zeros(numel(files), 1);
testNames   = cell(numel(files), 1);

for k = 1:numel(files)
    % --- Last inn data ---
    S = load(fullfile(files(k).folder, files(k).name));
    fn = fieldnames(S);
    d = S.(fn{1});
    if isa(d, 'timeseries'), d = [d.Time, d.Data]; end
    if size(d,1) == 9, d = d.'; end      % To File lagrer signaler som rader
    t = d(:,1);

    [~, testNames{k}] = fileparts(files(k).name);

    % --- Figur: alle tilstander ---
    fig = figure('Name', testNames{k}, 'Position', [100 100 900 700]);
    tiledlayout(3, 2, 'TileSpacing', 'compact');

    for i = tileOrder
        nexttile; hold on; grid on;
        plot(t, d(:,stateCol(i)), 'DisplayName', 'Måling');
        if i == 3, plot(t, d(:,8), 'k:', 'LineWidth', 1.2, 'DisplayName', 'Referanse'); end  % X_ref = pitch-ref
        if i == 6, plot(t, d(:,9), 'k:', 'LineWidth', 1.2, 'DisplayName', 'Referanse'); end  % Y_ref = elev.rate-ref
        ylabel(['$' stateNames{i} '$'], 'Interpreter', 'latex');
        if i == 3 || i == 6, legend('Location', 'best'); end
    end

    xlabel(findall(fig, 'Type', 'axes'), 'Tid [s]');
    sgtitle(testNames{k}, 'Interpreter', 'none');

    rmsPitchErr(k) = sqrt(mean((d(:,4) - d(:,8)).^2));

    if saveFigs, exportgraphics(fig, fullfile(figDir, [testNames{k} '.pdf'])); end
end

%% Sammenligning: RMS av pitch-følgefeil for alle tester
fig = figure('Name', 'RMS pitch-feil');
bar(categorical(testNames, testNames), rmsPitchErr);
set(gca, 'TickLabelInterpreter', 'none');
ylabel('RMS$(p - p_{ref})$', 'Interpreter', 'latex');
title('Pitch-følgefeil per test');
grid on;
if saveFigs, exportgraphics(fig, fullfile(figDir, 'rms_pitch_sammenligning.pdf')); end

disp(table(rmsPitchErr, 'RowNames', testNames));