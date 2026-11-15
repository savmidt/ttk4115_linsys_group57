%% Lab 3 - Luenberger-observer: rapportfigurer
% Kjør fra mappen Innlevering. Datafilene ligger i logs/lab3part2_*.mat
% Figurer lagres i figurer/lab3
%
% Kolonner i datafilene (vinkler i rad):
%  1 t        2 travel      3 travel_dot   4 pitch      5 pitch_dot
%  6 elev     7 elev_dot    8 p_est        9 pdot_est  10 e_est
% 11 edot_est 12 tdot_est  13 x_ref       14 y_ref     15 V_s   16 V_d

clear; close all; clc;

%% Innstillinger
dataDir  = 'logs';
figDir   = fullfile('figurer', 'lab3');
saveFigs = true;

% Hvilke tester som skal brukes i hele skriptet (figurer, sammenligning, tabell).
% Filnavn uten .mat. Tom = alle lab3part2_*.mat i dataDir.
tests = {'lab3part2_baseline', 'lab3part2_test6', 'lab3part2_test8'};

% Figurstørrelse i cm. Sett figW lik \textwidth i rapporten (\the\textwidth)
% og inkluder med \includegraphics{...} uten skalering.
figW   = 16;
fontSz = 9;

% Filformat for figurene: 'eps' (vektor, krever epstopdf med pdfLaTeX) eller 'pdf'
figFormat = 'eps';

% Navn på estimatet i legenden
estName = 'Luenberger';

% Valgfritt: beskrivende navn i tabellen (f.eks. polplassering eller C-matrise).
% Nøkkel = filnavn uten .mat.
legendNames = containers.Map();
% legendNames('lab3part2_test2') = 'Fast observer';

% Sammenligningsfigur: estimeringsfeil (encoder - estimat) for flere tester
makeCompare   = true;
compareTests  = {'lab3part2_baseline', 'lab3part2_test6', 'lab3part2_test8'}; % filnavn uten .mat, tom = alle. Velg helst 3-4, f.eks.
                                % {'lab3part2_baseline', 'lab3part2_test3', 'lab3part2_test5'}
compareStates = [1 2 3 4 5];    % 1 p, 2 pdot, 3 e, 4 edot, 5 lambdadot
compareName   = 'compare_error';% filnavn; endre for å lagre flere varianter

%% Oppsett
setDefaults(fontSz);
r2d = 180/pi;

files = dir(fullfile(dataDir, 'lab3part2_*.mat'));
if isempty(files), error('Fant ingen filer i %s som matcher lab3part2_*.mat', dataDir); end
if ~isempty(tests)
    [~, fNames] = cellfun(@fileparts, {files.name}, 'UniformOutput', false);
    missing = setdiff(tests, fNames);
    if ~isempty(missing)
        error('Fant ikke disse testene i %s: %s', dataDir, strjoin(missing, ', '));
    end
    files = files(ismember(fNames, tests));
end
if saveFigs && ~exist(figDir, 'dir'), mkdir(figDir); end

% Tilstander: navn, enhet, kolonne for encoder, kolonne for estimat
names  = {'p', '\dot{p}', 'e', '\dot{e}', '\dot{\lambda}'};
units  = {'deg', 'deg/s', 'deg', 'deg/s', 'deg/s'};
measC  = [4 5 6 7 3];
estC   = [8 9 10 11 12];

%% Last inn
D = struct([]);
for k = 1:numel(files)
    d = loadLog(fullfile(files(k).folder, files(k).name), 16);
    [~, name] = fileparts(files(k).name);
    D(k).name = name;
    if isKey(legendNames, name), D(k).label = legendNames(name);
    else, D(k).label = strrep(erase(name, 'lab3part2_'), '_', '\_'); end

    D(k).t    = d(:,1);
    D(k).meas = d(:,measC) * r2d;
    D(k).est  = d(:,estC)  * r2d;
    D(k).ref  = nan(size(D(k).meas));      % referanse per tilstand, NaN = ingen
    D(k).ref(:,1) = d(:,13) * r2d;         % x_ref -> pitch
    D(k).ref(:,4) = d(:,14) * r2d;         % y_ref -> elevasjonsrate
    D(k).rms  = sqrt(mean((D(k).meas - D(k).est).^2, 1));
end

%% Figur per test: pitch og elevasjonsrate med encoder, estimat og referanse
for k = 1:numel(D)
    fig = newFig(figW, 9);
    tl = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    for i = [1 4]                          % 1 = p, 4 = edot
        nexttile; hold on;
        h = plotNoisyFirst(D(k).t, D(k).meas(:,i), D(k).est(:,i), D(k).ref(:,i));
        ylabel(['$' names{i} '$ [' units{i} ']']);
        if i == 1
            lgd = legend(h, 'Encoder', estName, 'Reference', ...
                         'Orientation', 'horizontal', 'Box', 'off');
            lgd.Layout.Tile = 'north';
        end
    end
    xlabel(tl, 'Time [s]', 'Interpreter', 'latex', 'FontSize', fontSz);
    linkaxes(findall(fig, 'Type', 'axes'), 'x');
    xlim([D(k).t(1) D(k).t(end)]);
    saveFig(fig, figDir, D(k).name, saveFigs, figFormat);
end

%% Sammenligningsfigur: estimeringsfeil for valgte tester
if makeCompare
    idx = 1:numel(D);
    if ~isempty(compareTests)
        idx = find(ismember({D.name}, compareTests));
        if isempty(idx)
            error('Ingen av navnene i compareTests matcher: %s', strjoin({D.name}, ', '));
        end
    end

    styles = {'-', '--', '-.', ':'};    % ulike linjetyper -> lesbar i svart-hvitt
    cols   = lines(numel(idx));
    nS     = numel(compareStates);

    fig = newFig(figW, 2 + 3*nS);
    tl = tiledlayout(nS, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    for s = 1:nS
        i = compareStates(s);
        nexttile; hold on;
        % Støyeste test tegnes først (bakerst); farge/linjetype følger testen
        nz = arrayfun(@(k) noiseLevel(D(k).meas(:,i) - D(k).est(:,i)), idx);
        [~, order] = sort(nz, 'descend');
        h = gobjects(1, numel(idx));
        for j = order
            k = idx(j);
            h(j) = plot(D(k).t, D(k).meas(:,i) - D(k).est(:,i), styles{mod(j-1,4)+1}, ...
                'Color', cols(j,:), 'DisplayName', D(k).label);
        end
        ylabel(['$' names{i} ' - \hat{' names{i} '}$ [' units{i} ']']);
        if s == 1
            lgd = legend(h, 'NumColumns', 2);   % legend i fast testrekkefølge
            lgd.Layout.Tile = 'south';
        end
    end
    xlabel(tl, 'Time [s]', 'Interpreter', 'latex', 'FontSize', fontSz);
    linkaxes(findall(fig, 'Type', 'axes'), 'x');
    saveFig(fig, figDir, compareName, saveFigs, figFormat);
end

%% RMS av estimeringsfeil (encoder - estimat) som LaTeX-tabell
rmsAll = vertcat(D.rms);
disp(array2table(rmsAll, 'RowNames', {D.name}, ...
    'VariableNames', {'p', 'pdot', 'e', 'edot', 'traveldot'}));

if saveFigs
    header = [{'Test'}, cellfun(@(n, u) ['$' n '$ [' u ']'], names, units, 'UniformOutput', false)];
    writeTexTable(fullfile(figDir, 'rms_table.tex'), header, {D.label}, rmsAll);
end

%% Hjelpefunksjoner
function h = plotNoisyFirst(t, meas, est, ref)
    % Tegner encoder og estimat med det støyeste signalet først (bakerst),
    % så det rolige signalet blir synlig oppå. Referansen (svart stiplet)
    % tegnes til slutt, øverst. Farge følger alltid signalet:
    % encoder = blå, estimat = oransje (tykkere).
    % h = [encoder, estimat, referanse] for en legend i fast rekkefølge.
    c = lines(2);
    h = gobjects(1, 3);
    if noiseLevel(est) > noiseLevel(meas)
        h(2) = plot(t, est,  '-', 'Color', c(2,:), 'LineWidth', 1.5);
        h(1) = plot(t, meas, '-', 'Color', c(1,:), 'LineWidth', 1.0);
    else
        h(1) = plot(t, meas, '-', 'Color', c(1,:), 'LineWidth', 1.0);
        h(2) = plot(t, est,  '-', 'Color', c(2,:), 'LineWidth', 1.5);
    end
    if nargin > 3 && ~all(isnan(ref))
        h(3) = plot(t, ref, '--', 'Color', 'k', 'LineWidth', 1.5);
    else
        h(3) = plot(nan, nan, '--', 'Color', 'k', 'LineWidth', 1.5);   % tom, for legenden
    end
end

function n = noiseLevel(y)
    % Mål på høyfrekvent støy: standardavvik av sample-til-sample-endringen.
    % Upåvirket av langsomme bevegelser, stort for et støyete signal.
    n = std(diff(y(~isnan(y))));
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

function saveFig(fig, figDir, name, doSave, fmt)
    if nargin < 5, fmt = 'pdf'; end
    if doSave
        exportgraphics(fig, fullfile(figDir, [name '.' fmt]), 'ContentType', 'vector');
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