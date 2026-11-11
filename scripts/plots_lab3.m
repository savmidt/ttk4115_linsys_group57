%% Lab 3 del 2 - Luenberger-observer: plott av målinger vs. estimater
% Legg skriptet i samme mappe som lab3part2_*.mat og kjør.
%
% Kolonner i datafilene:
%  1 t        2 travel      3 travel_dot   4 pitch      5 pitch_dot
%  6 elev     7 elev_dot    8 p_est        9 pdot_est  10 e_est
% 11 edot_est 12 tdot_est  13 x_ref       14 y_ref     15 V_s   16 V_d

clear; close all; clc;

saveFigs = true;                         % lagre figurer som PDF i ./figurer
figDir   = fullfile('figurer', 'lab3');
if saveFigs && ~exist(figDir, 'dir'), mkdir(figDir); end

files = dir(fullfile('logs', 'lab3part2_*.mat'));

stateNames = {'p', '\dot{p}', 'e', '\dot{e}', '\dot{\lambda}'};
measCol    = [4 5 6 7 3];                % encoder (fasit)
estCol     = [8 9 10 11 12];             % estimat fra observer

rmsErr    = zeros(numel(files), 5);
testNames = cell(numel(files), 1);

for k = 1:numel(files)
    % --- Last inn data ---
    S = load(fullfile(files(k).folder, files(k).name));
    fn = fieldnames(S);
    d = S.(fn{1});
    if isa(d, 'timeseries'), d = [d.Time, d.Data]; end
    if size(d,1) == 16, d = d.'; end     % To File lagrer signaler som rader
    t = d(:,1);

    [~, testNames{k}] = fileparts(files(k).name);
    testNames{k} = erase(testNames{k}, 'lab3part2_');

    % --- Figur: tilstander + pådrag ---
    fig = figure('Name', testNames{k}, 'Position', [100 100 900 700]);
    tiledlayout(3, 2, 'TileSpacing', 'compact');

    for i = 1:5
        nexttile; hold on; grid on;
        plot(t, d(:,measCol(i)), 'DisplayName', 'Encoder');
        plot(t, d(:,estCol(i)), '--', 'LineWidth', 1.2, 'DisplayName', 'Estimat');
        if i == 1, plot(t, d(:,13), 'k:', 'DisplayName', 'Referanse'); end  % x_ref = pitch-ref
        if i == 4, plot(t, d(:,14), 'k:', 'DisplayName', 'Referanse'); end  % y_ref = elev.rate-ref
        ylabel(['$' stateNames{i} '$'], 'Interpreter', 'latex');
        legend('Location', 'best');

        err = d(:,measCol(i)) - d(:,estCol(i));
        rmsErr(k,i) = sqrt(mean(err.^2));
    end

    nexttile; hold on; grid on;
    plot(t, d(:,15), 'DisplayName', '$\tilde{V}_s$');
    plot(t, d(:,16), 'DisplayName', '$V_d$');
    ylabel('Spenning [V]');
    legend('Interpreter', 'latex', 'Location', 'best');

    xlabel(findall(fig, 'Type', 'axes'), 'Tid [s]');
    sgtitle(testNames{k}, 'Interpreter', 'none');

    if saveFigs, exportgraphics(fig, fullfile(figDir, [testNames{k} '.pdf'])); end
end

%% Sammenligning: RMS av estimeringsfeil for alle tester
fig = figure('Name', 'RMS-feil', 'Position', [100 100 1100 350]);
tiledlayout(1, 5, 'TileSpacing', 'compact');
for i = 1:5
    nexttile;
    bar(categorical(testNames, testNames), rmsErr(:,i));
    title(['RMS-feil $' stateNames{i} '$'], 'Interpreter', 'latex');
    grid on;
end
if saveFigs, exportgraphics(fig, fullfile(figDir, 'rms_sammenligning.pdf')); end

% Tabell i kommandovinduet
disp(array2table(rmsErr, 'RowNames', testNames, ...
    'VariableNames', {'p', 'pdot', 'e', 'edot', 'traveldot'}));