%% RUN_DISCOVERY  E1 (RQ1): do suppliers discover signal inflation on their own?
% Sweeps the share of Q-learning suppliers (learnFrac) with no verification
% (rhoAudit = 0). Saves end-state metrics, the winning-action distribution and
% the block-level gaming trajectory of every run.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));

fracLevels = [0.10 0.25 0.50 1.00];
nRuns = 30;
[R, F] = ndgrid(1:nRuns, fracLevels);
nCells = numel(R);
nA = numel(abmgov.SupplierPool.G);
nBlocks = floor(abmgov.defaultConfig().nTenders / abmgov.defaultConfig().blockSize);

out = zeros(nCells, 9);
actShare = zeros(nCells, nA);
gamingSeries = zeros(nCells, nBlocks);

parfor c = 1:nCells
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = F(c);
    cfg.rhoAudit = 0;
    cfg.seed = 5000 + R(c) + round(1000 * F(c));
    mkt = abmgov.ProcurementMarket(cfg);
    mkt.run();
    m = mkt.metrics();
    out(c, :) = [F(c) R(c) m.hhi m.overrunPct m.gamingPrevalence ...
                 m.gamerValueShare m.signalGap m.trueQuality m.coverRate];
    last = mkt.winnerAction(end - cfg.evalWindow + 1:end);
    actShare(c, :) = accumarray(last, 1, [nA 1])' / numel(last);
    gamingSeries(c, :) = m.series.gaming';
end

T = array2table(out, 'VariableNames', {'learnFrac', 'run', 'HHI', 'OverrunPct', ...
    'GamingPrevalence', 'GamerValueSharePct', 'SignalGap', 'TrueQuality', 'CoverRate'});
A = array2table(actShare, 'VariableNames', compose('act%d', 1:nA));
T = [T A];

% Block at which mean gaming prevalence first exceeds half its final level
tHalf = zeros(numel(fracLevels), 1);
for j = 1:numel(fracLevels)
    s = mean(gamingSeries(F == fracLevels(j), :), 1);
    tHalf(j) = find(s >= 0.5 * mean(s(end - 4:end)), 1);
end

disp(groupsummary(T, 'learnFrac', 'mean', {'HHI', 'OverrunPct', 'GamingPrevalence', ...
    'GamerValueSharePct', 'SignalGap', 'TrueQuality'}));
disp(table(fracLevels', tHalf * abmgov.defaultConfig().blockSize, ...
    'VariableNames', {'learnFrac', 'TendersToHalfFinalGaming'}));
disp(groupsummary(T, 'learnFrac', 'mean', compose('act%d', 1:nA)));

% Test against the competitive-market threshold (one-sided, learnFrac = 1)
h = T.HHI(T.learnFrac == 1);
[~, p] = ttest(h, 1000, 'Tail', 'left');
fprintf('learnFrac=1: HHI mean %.1f, max %.1f, one-sided p(HHI<1000) = %.2e\n', ...
    mean(h), max(h), p);

outDir = fullfile(here, '..', '..', 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end
writetable(T, fullfile(outDir, 'E1_discovery.csv'));
save(fullfile(outDir, 'E1_gaming_series.mat'), 'gamingSeries', 'F', 'R', 'fracLevels');
