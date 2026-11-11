%% Lab 1 - PD-regulering av pitch: rapportfigurer
% Kjør fra mappen Innlevering. Datafilene ligger i logs/lab1*.mat
% Figurer lagres i figurer/lab1
%
% Kolonner i datafilene (vinkler i rad fra Heli 3D):
%  1 t   2 travel   3 travel_dot   4 pitch   5 pitch_dot
%  6 elevation   7 elevation_dot   8 X_ref (pitch-ref, joystick)   9 Y_ref

clear; close all; clc;

%% Innstillinger
dataDir  = 'logs';
figDir   = fullfile('figurer', 'lab1');
saveFigs = true;

% Figurstørrelse i cm. Sett figW lik \textwidth i rapporten (\the\textwidth)
% og inkluder med \includegraphics{...} uten skalering.
figW   = 13;
fontSz = 9;

% Valgfritt: overstyr automatiske legendnavn. Nøkkel = filnavn uten .mat.
legendNames = containers.Map();

%% Oppsett
setDefaults(fontSz);
r2d = 180/pi;

files = dir(fullfile(dataDir, 'lab1*.mat'));
if isempty(files), error('Fant ingen filer i %s som matcher lab1*.mat', dataDir); end
if saveFigs && ~exist(figDir, 'dir'), mkdir(figDir); end

%% Last inn
D = struct([]);
for k = 1:numel(files)
    d = loadLog(fullfile(files(k).folder, files(k).name), 9);
    [~, name] = fileparts(files(k).name);
    D(k).name = name;
    if isKey(legendNames, name), D(k).label = legendNames(name);
    else, D(k).label = poleLabel(name); end

    D(k).t    = d(:,1);
    D(k).p    = d(:,4) * r2d;
    D(k).pdot = d(:,5) * r2d;
    D(k).pref = d(:,8) * r2d;
    D(k).rmsP = sqrt(mean((D(k).p - D(k).pref).^2));
end

%% Én figur per test: pitch mot referanse og pitchrate
% Referansen kommer fra joysticken og er ulik i hver test, så testene
% plottes hver for seg i stedet for oppå hverandre.
for k = 1:numel(D)
    fig = newFig(figW, 8);
    tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile; hold on;
    plot(D(k).t, D(k).pref, 'k--');
    plot(D(k).t, D(k).p);
    ylabel('$p$ [deg]');
    legend('$p_{ref}$', '$p$', 'Location', 'best');

    nexttile;
    plot(D(k).t, D(k).pdot);
    ylabel('$\dot{p}$ [deg/s]');

    xlabel(tl, 'Time [s]', 'Interpreter', 'latex', 'FontSize', fontSz);
    linkaxes(findall(fig, 'Type', 'axes'), 'x');
    saveFig(fig, figDir, [D(k).name '_pitch'], saveFigs);
end

%% RMS av pitch-følgefeil som LaTeX-tabell
disp(table([D.rmsP]', 'RowNames', {D.name}, 'VariableNames', {'rms_pitch_deg'}));
if saveFigs
    writeTexTable(fullfile(figDir, 'rms_table.tex'), ...
        {'Poles', 'RMS$(p - p_{ref})$ [deg]'}, {D.label}, [D.rmsP]');
end

%% Hjelpefunksjoner
function lbl = poleLabel(name)
    % lab1minus1minus10 -> $\lambda_{1,2} = -1, -10$
    % lab1minus1plussminus_i -> $\lambda_{1,2} = -1 \pm i$
    if ~startsWith(name, 'lab1minus'), lbl = strrep(name, '_', '\_'); return; end
    s = erase(name, 'lab1');
    s = strrep(s, 'plussminus_i', ' \pm i');
    s = strrep(s, 'minus', ', -');
    lbl = ['$\lambda_{1,2} = ' s(3:end) '$'];
end

function d = loadLog(path, nSig)
    S = load(path);
    fn = fieldnames(S);
    d = S.(fn{1});
    if isa(d, 'timeseries'), d = [d.Time, d.Data]; end
    if size(d,1) == nSig, d = d.'; end            % To File lagrer signaler som rader
    if size(d,2) ~= nSig
        error('%s har %d kolonner, forventet %d', path, size(d,2), nSig);
    end
end

function setDefaults(fontSz)
    set(groot, 'defaultTextInterpreter', 'latex', ...
               'defaultAxesTickLabelInterpreter', 'latex', ...
               'defaultLegendInterpreter', 'latex', ...
               'defaultAxesFontSize', fontSz, ...
               'defaultLegendFontSize', fontSz, ...
               'defaultLineLineWidth', 1.0, ...
               'defaultAxesXGrid', 'on', 'defaultAxesYGrid', 'on', ...
               'defaultAxesBox', 'on', 'defaultFigureColor', 'w');
end

function fig = newFig(w, h)
    fig = figure('Units', 'centimeters', 'Position', [2 2 w h]);
end

function saveFig(fig, figDir, name, doSave)
    if doSave
        exportgraphics(fig, fullfile(figDir, [name '.pdf']), 'ContentType', 'vector');
    end
end

function writeTexTable(path, header, labels, vals)
    fid = fopen(path, 'w');
    fprintf(fid, '\\begin{tabular}{l%s}\n\\hline\n', repmat('c', 1, size(vals,2)));
    fprintf(fid, '%s \\\\\n\\hline\n', strjoin(header, ' & '));
    for k = 1:numel(labels)
        fprintf(fid, '%s', labels{k});
        fprintf(fid, ' & %.2f', vals(k,:));
        fprintf(fid, ' \\\\\n');
    end
    fprintf(fid, '\\hline\n\\end{tabular}\n');
    fclose(fid);
end