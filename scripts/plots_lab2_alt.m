%% Lab 2 - LQR: rapportfigurer
% Kjør fra mappen Innlevering. Datafilene ligger i logs/part2prob1_*.mat
% (LQR uten integralvirkning) og logs/part2prob2_*.mat (med integralvirkning).
% Figurer per test lagres i figurer/lab2/part2prob1 og figurer/lab2/part2prob2
%
% Kolonner i datafilene (vinkler i rad fra Heli 3D):
%  part2prob2 (11):  1 t   2 travel   3 travel_dot   4 pitch   5 pitch_dot
%                    6 elevation   7 elevation_dot   8 X_ref   9 Y_ref   10 V_s   11 V_d
%  part2prob1 (9):   som over, men uten V_s og V_d
% Endre grp-tabellen under Innstillinger hvis rekkefølgen er annerledes.

clear; close all; clc;

%% Innstillinger
dataDir  = 'logs';
saveFigs = true;

% Grupper og kolonneoppsett. cols = kolonnenummer for
% [t  pitch  elevation_dot  X_ref  Y_ref  V_s  V_d], 0 = ikke logget
grp = struct('name', {'part2prob1',          'part2prob2'}, ...
             'nSig', {9,                     11}, ...
             'cols', {[1 4 7 8 9 0 0],       [1 4 7 8 9 10 11]});
perTest  = true;     % lag figurer for hver enkelt test

% Figurstørrelse i cm. Sett figW lik \textwidth i rapporten (\the\textwidth)
% og inkluder med \includegraphics{...} uten skalering.
figW   = 13;
fontSz = 9;

% Valgfritt: overstyr automatiske legendnavn. Nøkkel = filnavn uten .mat.
legendNames = containers.Map();

% Sammenligningsfigur
makeCompare   = true;
compareTests  = {};             % tom = én figur per gruppe (prob1 og prob2) med alle testene
                                % ikke tom = én figur med akkurat disse testene, også på
                                % tvers av prob1/prob2. Lagres da i figurer/lab2. F.eks.
                                % {'part2prob1_q_10_r_01', 'part2prob2_q_10_r_01'}
compareStates = [1 2];          % 1 p, 2 edot, 3 V_s, 4 V_d
compareMode   = 'signal';       % 'signal' : selve signalene + referanse (krever lik
                                %            referanse i alle testene, ellers -> 'error')
                                % 'error'  : følgefeil p - p_ref og edot - edot_ref
compareName   = 'compare_tracking'; % filnavn; endre for å lagre flere varianter

%% Oppsett
setDefaults(fontSz);
r2d = 180/pi;

% Tilstander som kan sammenlignes: felt, referansefelt ('' = ingen), navn, enhet
st = struct('field', {'p', 'edot', 'Vs', 'Vd'}, ...
            'ref',   {'pref', 'edotref', '', ''}, ...
            'name',  {'p', '\dot{e}', 'V_s', 'V_d'}, ...
            'unit',  {'deg', 'deg/s', 'V', 'V'});

%% Last inn alle grupper
groups = {grp.name};
D = struct([]);
for g = 1:numel(grp)
    files = dir(fullfile(dataDir, [grp(g).name '_*.mat']));
    if isempty(files)
        warning('Fant ingen filer for %s i %s', grp(g).name, dataDir);
        continue;
    end
    c = grp(g).cols;
    for f = 1:numel(files)
        d = loadLog(fullfile(files(f).folder, files(f).name), grp(g).nSig);
        [~, name] = fileparts(files(f).name);
        k = numel(D) + 1;
        D(k).name  = name;
        D(k).group = grp(g).name;
        if isKey(legendNames, name), D(k).label = legendNames(name);
        else, D(k).label = qrLabel(name); end

        D(k).t       = d(:,c(1));
        D(k).p       = d(:,c(2)) * r2d;
        D(k).edot    = d(:,c(3)) * r2d;
        D(k).pref    = d(:,c(4)) * r2d;
        D(k).edotref = d(:,c(5)) * r2d;
        D(k).Vs      = [];
        D(k).Vd      = [];
        if c(6) > 0, D(k).Vs = d(:,c(6)); end
        if c(7) > 0, D(k).Vd = d(:,c(7)); end
        D(k).rmsP = sqrt(mean((D(k).p    - D(k).pref   ).^2));
        D(k).rmsE = sqrt(mean((D(k).edot - D(k).edotref).^2));
    end
end
if isempty(D), error('Fant ingen lab 2-filer i %s', dataDir); end

for g = 1:numel(groups)
    gDir = fullfile('figurer', 'lab2', groups{g});
    if saveFigs && any(strcmp({D.group}, groups{g})) && ~exist(gDir, 'dir'), mkdir(gDir); end
end

%% Figurer per test (i gruppens egen mappe)
if perTest
    for k = 1:numel(D)
        gDir = fullfile('figurer', 'lab2', D(k).group);

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
        saveFig(fig, gDir, [D(k).name '_tracking'], saveFigs);

        % Pådrag (bare hvis de er logget)
        if ~isempty(D(k).Vs) && ~isempty(D(k).Vd)
            fig = newFig(figW, 5);
            hold on;
            plot(D(k).t, D(k).Vs);
            plot(D(k).t, D(k).Vd, '--');
            xlabel('Time [s]');
            ylabel('Voltage [V]');
            legend('$V_s$', '$V_d$', 'Location', 'best');
            saveFig(fig, gDir, [D(k).name '_inputs'], saveFigs);
        end
    end
end

%% Sammenligningsfigur
if makeCompare
    if isempty(compareTests)
        % Én figur per gruppe, i gruppens mappe
        for g = 1:numel(groups)
            idx = find(strcmp({D.group}, groups{g}));
            if numel(idx) < 2, continue; end
            makeCompareFig(D, idx, st, compareStates, compareMode, figW, fontSz, ...
                           fullfile('figurer', 'lab2', groups{g}), compareName, saveFigs);
        end
    else
        % Én figur med de valgte testene, i figurer/lab2
        idx = find(ismember({D.name}, compareTests));
        if isempty(idx)
            error('Ingen av navnene i compareTests matcher: %s', strjoin({D.name}, ', '));
        end
        makeCompareFig(D, idx, st, compareStates, compareMode, figW, fontSz, ...
                       fullfile('figurer', 'lab2'), compareName, saveFigs);
    end
end

%% RMS-feil som LaTeX-tabell, én per gruppe
for g = 1:numel(groups)
    idx = find(strcmp({D.group}, groups{g}));
    if isempty(idx), continue; end
    fprintf('\n%s\n', groups{g});
    disp(table([D(idx).rmsP]', [D(idx).rmsE]', 'RowNames', {D(idx).name}, ...
        'VariableNames', {'rms_pitch_deg', 'rms_edot_degps'}));
    if saveFigs
        writeTexTable(fullfile('figurer', 'lab2', groups{g}, 'rms_table.tex'), ...
            {'Tuning', 'RMS$(p - p_{ref})$ [deg]', 'RMS$(\dot{e} - \dot{e}_{ref})$ [deg/s]'}, ...
            {D(idx).label}, [[D(idx).rmsP]', [D(idx).rmsE]']);
    end
end

%% Hjelpefunksjoner
function lbl = qrLabel(name)
    % part2prob2_q_10_05_10_2_5_r_01 -> $Q = diag(10, 0.5, 10, 2, 5)$, $R = 0.1I$
    tok = regexp(name, 'q_(.*)_r_(.*)$', 'tokens', 'once');
    if isempty(tok), lbl = strrep(name, '_', '\_'); return; end
    lbl = ['$Q = ' fmtMat(tok{1}) '$, $R = ' fmtMat(tok{2}) '$'];
end

function s = fmtMat(str)
    v = strsplit(str, '_');
    for i = 1:numel(v)
        if numel(v{i}) > 1 && v{i}(1) == '0'
            v{i} = ['0.' v{i}(2:end)];       % '05' -> 0.5, '01' -> 0.1
        end
    end
    if numel(v) == 1
        if strcmp(v{1}, '1'), s = 'I'; else, s = [v{1} 'I']; end
    else
        s = ['\mathrm{diag}(' strjoin(v, ', ') ')'];
    end
end

function makeCompareFig(D, idx, st, sel, mode, figW, fontSz, outDir, outName, doSave)
    styles = {'-', '--', '-.', ':'};     % ulike linjetyper -> lesbar i svart-hvitt
    cols   = lines(numel(idx));
    refCol = [0.6 0.6 0.6];

    if strcmp(mode, 'signal')
        for i = sel
            if ~isempty(st(i).ref) && ~sameRef(D, idx, st(i).ref)
                warning('Referansen for %s er ulik mellom testene, bruker compareMode = ''error''.', st(i).field);
                mode = 'error';
                break;
            end
        end
    end

    % Dropp paneler for signaler som ingen av testene har logget (f.eks. V_s i prob1)
    keep = true(size(sel));
    for s = 1:numel(sel)
        if all(cellfun(@isempty, {D(idx).(st(sel(s)).field)}))
            warning('Ingen av testene har logget %s, hopper over det panelet.', st(sel(s)).field);
            keep(s) = false;
        end
    end
    sel = sel(keep);
    if isempty(sel), return; end

    nS  = numel(sel);
    fig = newFig(figW, 2 + 3*nS);
    tl  = tiledlayout(nS, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    for s = 1:nS
        i = sel(s);
        hasRef = ~isempty(st(i).ref);
        nexttile; hold on;
        if strcmp(mode, 'signal') && hasRef
            plot(D(idx(1)).t, D(idx(1)).(st(i).ref), 'Color', refCol, 'LineWidth', 2, ...
                 'DisplayName', 'Reference');
        end
        for j = 1:numel(idx)
            k = idx(j);
            y = D(k).(st(i).field);
            if isempty(y), continue; end         % signalet er ikke logget i denne testen
            if strcmp(mode, 'error') && hasRef, y = y - D(k).(st(i).ref); end
            plot(D(k).t, y, styles{mod(j-1,4)+1}, 'Color', cols(j,:), 'DisplayName', D(k).label);
        end
        if strcmp(mode, 'error') && hasRef
            ylabel(['$' st(i).name ' - ' st(i).name '_{ref}$ [' st(i).unit ']']);
        else
            ylabel(['$' st(i).name '$ [' st(i).unit ']']);
        end
        if s == 1
            lgd = legend('NumColumns', 2);
            lgd.Layout.Tile = 'south';
        end
    end
    xlabel(tl, 'Time [s]', 'Interpreter', 'latex', 'FontSize', fontSz);
    linkaxes(findall(fig, 'Type', 'axes'), 'x');
    saveFig(fig, outDir, outName, doSave);
end

function ok = sameRef(D, idx, field)
    r0 = D(idx(1)).(field);
    ok = true;
    for k = idx(2:end)
        r = D(k).(field);
        n = min(numel(r), numel(r0));
        if max(abs(r(1:n) - r0(1:n))) > 1e-6, ok = false; return; end
    end
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
        if ~exist(figDir, 'dir'), mkdir(figDir); end
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