%% Lab 2 - LQR: rapportfigurer
% Kjør fra mappen Innlevering. Datafilene ligger i logs/lab2*.mat
%
% Kolonner i datafilene (vinkler i rad fra Heli 3D):
%  1 t   2 travel   3 travel_dot   4 pitch   5 pitch_dot   6 elevation
%  7 elevation_dot   8 X_ref (pitch-ref)   9 Y_ref (elev.rate-ref)   10 V_s   11 V_d

clear; close all; clc;

%% Innstillinger
dataDir     = 'logs';
filePattern = 'part2prob2_*.mat';    % bytt til 'part2prob1_*.mat' for oppgave 1
figDir      = fullfile('figurer', 'lab2', erase(filePattern, '_*.mat'));
saveFigs = true;
perTest  = true;     % lag figurer for hver enkelt test

% Figurstørrelse i cm. Sett figW lik \textwidth i rapporten (skriv
% \the\textwidth i LaTeX for å finne den), og inkluder med
% \includegraphics{...} UTEN skalering, så blir skriftstørrelsen riktig.
figW   = 13;
fontSz = 9;

% Valgfritt: beskrivende navn i legend og tabell (f.eks. Q/R-valg).
% Nøkkel = filnavn uten .mat. Filer som ikke står her får filnavnet.
legendNames = containers.Map();
% legendNames('lab2part2_test1') = '$Q = I$, $R = I$';

% Hvilke tester som skal være med i sammenligningsfigurene (tom = alle).
% Velg gjerne 3-4 stykker, ellers blir figuren uleselig.
compareTests = {};

%% Standardoppsett for alle figurer: LaTeX-tekst, rutenett, fast font
set(groot, 'defaultTextInterpreter', 'latex', ...
           'defaultAxesTickLabelInterpreter', 'latex', ...
           'defaultLegendInterpreter', 'latex', ...
           'defaultAxesFontSize', fontSz, ...
           'defaultLegendFontSize', fontSz, ...
           'defaultLineLineWidth', 1.0, ...
           'defaultAxesXGrid', 'on', 'defaultAxesYGrid', 'on', ...
           'defaultAxesBox', 'on');

if saveFigs && ~exist(figDir, 'dir'), mkdir(figDir); end

%% Last inn alle tester
files = dir(fullfile(dataDir, filePattern));
r2d = 180/pi;
D = struct([]);

for k = 1:numel(files)
    S = load(fullfile(files(k).folder, files(k).name));
    fn = fieldnames(S);
    d = S.(fn{1});
    if isa(d, 'timeseries'), d = [d.Time, d.Data]; end
    if size(d,1) == 11, d = d.'; end     % To File lagrer signaler som rader

    [~, name] = fileparts(files(k).name);
    D(k).name = name;
    if isKey(legendNames, name)
        D(k).label = legendNames(name);
    else
        D(k).label = strrep(name, '_', '\_');
    end

    D(k).t       = d(:,1);
    D(k).p       = d(:,4) * r2d;
    D(k).edot    = d(:,7) * r2d;
    D(k).pref    = d(:,8) * r2d;
    D(k).edotref = d(:,9) * r2d;
    D(k).Vs      = d(:,10);
    D(k).Vd      = d(:,11);

    D(k).rmsP = sqrt(mean((D(k).p    - D(k).pref   ).^2));
    D(k).rmsE = sqrt(mean((D(k).edot - D(k).edotref).^2));
end

%% Figurer per test: følging av referanse + pådrag
if perTest
    for k = 1:numel(D)
        % Referansefølging
        fig = newFig(figW, 8);
        tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

        nexttile; hold on;
        plot(D(k).t, D(k).pref, 'k--');
        plot(D(k).t, D(k).p);
        ylabel('$p$ [deg]');
        legend('$p_{ref}$', '$p$', 'Location', 'best');

        nexttile; hold on;
        plot(D(k).t, D(k).edotref, 'k--');
        plot(D(k).t, D(k).edot);
        ylabel('$\dot{e}$ [deg/s]');
        legend('$\dot{e}_{ref}$', '$\dot{e}$', 'Location', 'best');

        xlabel(tl, 'Time [s]', 'Interpreter', 'latex', 'FontSize', fontSz);
        linkaxes(findall(fig, 'Type', 'axes'), 'x');
        saveFig(fig, figDir, [D(k).name '_tracking'], saveFigs);

        % Pådrag
        fig = newFig(figW, 5);
        hold on;
        plot(D(k).t, D(k).Vs);
        plot(D(k).t, D(k).Vd, '--');
        xlabel('Time [s]');
        ylabel('Voltage [V]');
        legend('$V_s$', '$V_d$', 'Location', 'best');
        saveFig(fig, figDir, [D(k).name '_inputs'], saveFigs);
    end
end

%% Sammenligningsfigurer (samme referanse fra Signal Builder i alle tester)
if isempty(compareTests)
    idx = 1:numel(D);
else
    idx = find(ismember({D.name}, compareTests));
end

styles = {'-', '--', '-.', ':'};           % ulike linjetyper -> lesbar i svart-hvitt
cols   = lines(numel(idx));
refCol = [0.6 0.6 0.6];

% Referansefølging
fig = newFig(figW, 9);
tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile; hold on;
plot(D(idx(1)).t, D(idx(1)).pref, 'Color', refCol, 'LineWidth', 2, 'DisplayName', 'Reference');
for j = 1:numel(idx)
    k = idx(j);
    plot(D(k).t, D(k).p, styles{mod(j-1,4)+1}, 'Color', cols(j,:), 'DisplayName', D(k).label);
end
ylabel('$p$ [deg]');
lgd = legend('NumColumns', min(numel(idx)+1, 3));
lgd.Layout.Tile = 'south';

nexttile; hold on;
plot(D(idx(1)).t, D(idx(1)).edotref, 'Color', refCol, 'LineWidth', 2);
for j = 1:numel(idx)
    k = idx(j);
    plot(D(k).t, D(k).edot, styles{mod(j-1,4)+1}, 'Color', cols(j,:));
end
ylabel('$\dot{e}$ [deg/s]');

xlabel(tl, 'Time [s]', 'Interpreter', 'latex', 'FontSize', fontSz);
linkaxes(findall(fig, 'Type', 'axes'), 'x');
saveFig(fig, figDir, 'compare_tracking', saveFigs);

% Pådrag
fig = newFig(figW, 9);
tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile; hold on;
for j = 1:numel(idx)
    k = idx(j);
    plot(D(k).t, D(k).Vs, styles{mod(j-1,4)+1}, 'Color', cols(j,:), 'DisplayName', D(k).label);
end
ylabel('$V_s$ [V]');
lgd = legend('NumColumns', min(numel(idx), 3));
lgd.Layout.Tile = 'south';

nexttile; hold on;
for j = 1:numel(idx)
    k = idx(j);
    plot(D(k).t, D(k).Vd, styles{mod(j-1,4)+1}, 'Color', cols(j,:));
end
ylabel('$V_d$ [V]');

xlabel(tl, 'Time [s]', 'Interpreter', 'latex', 'FontSize', fontSz);
linkaxes(findall(fig, 'Type', 'axes'), 'x');
saveFig(fig, figDir, 'compare_inputs', saveFigs);

%% RMS-feil som LaTeX-tabell (bedre enn et stolpediagram i rapporten)
disp(table([D.rmsP]', [D.rmsE]', 'RowNames', {D.name}, ...
    'VariableNames', {'rms_pitch_deg', 'rms_edot_degps'}));

if saveFigs
    fid = fopen(fullfile(figDir, 'rms_table.tex'), 'w');
    fprintf(fid, '\\begin{tabular}{lcc}\n\\hline\n');
    fprintf(fid, 'Test & RMS$(p - p_{ref})$ [deg] & RMS$(\\dot{e} - \\dot{e}_{ref})$ [deg/s] \\\\\n\\hline\n');
    for k = 1:numel(D)
        fprintf(fid, '%s & %.2f & %.2f \\\\\n', D(k).label, D(k).rmsP, D(k).rmsE);
    end
    fprintf(fid, '\\hline\n\\end{tabular}\n');
    fclose(fid);
end

%% Hjelpefunksjoner
function fig = newFig(w, h)
    fig = figure('Units', 'centimeters', 'Position', [2 2 w h], 'Color', 'w');
end

function saveFig(fig, figDir, name, doSave)
    if doSave
        exportgraphics(fig, fullfile(figDir, [name '.pdf']), 'ContentType', 'vector');
    end
end