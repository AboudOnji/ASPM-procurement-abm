%% RUN_POISONING  E4 (RQ3): feedback loop between unverified signals and the performance record.
% The allocator weights the recorded past performance (w3). The record of a
% winner is fed with the delivered quality only if the contract is verified
% (prob. rho); otherwise with the reported (possibly inflated) signal.
% Score weights: [0.6, 0.4 - w3, w3] so the total quality weight is constant.
% Populations: all learners, and 20% exogenous fixed gamers (no learning).
% NOT covered here: an allocator that re-estimates its weights from outcomes.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));
outDir = fullfile(here, '..', '..', 'results');

w3s = [0 0.1 0.2 0.3]; rhos = [0 0.1 0.3]; pops = [1 2]; nRuns = 30;
[RR, WW, PP, OO] = ndgrid(1:nRuns, w3s, rhos, pops);
nB = abmgov.defaultConfig().nTenders / abmgov.defaultConfig().blockSize;
out = zeros(numel(RR), 10); gapSeries = zeros(numel(RR), nB); qSeries = zeros(numel(RR), nB);
parfor c = 1:numel(RR)
    cfg = abmgov.defaultConfig();
    cfg.weights = [0.6 0.4 - WW(c) WW(c)];
    cfg.rhoAudit = PP(c);
    if OO(c) == 1, cfg.learnFrac = 1; cfg.greedyEval = true; else, cfg.piG = 0.20; end
    cfg.seed = 21000 + c;
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    out(c, :) = [OO(c) WW(c) PP(c) RR(c) m.hhi m.overrunPct m.gamingPrevalence ...
                 m.signalGap m.trueQuality m.gamerValueShare];
    gapSeries(c, :) = m.series.signalGap'; qSeries(c, :) = m.series.trueQuality';
end
T = array2table(out, 'VariableNames', {'pop', 'w3', 'rho', 'run', 'HHI', 'OverrunPct', ...
    'GamingPrevalence', 'SignalGap', 'TrueQuality', 'GamerValueSharePct'});
T.pop = categorical(T.pop, [1 2], {'learners', 'fixed20'});
disp(groupsummary(T, {'pop', 'rho', 'w3'}, 'mean', {'HHI', 'OverrunPct', ...
    'GamingPrevalence', 'SignalGap', 'TrueQuality'}));

fprintf('\nEffect of w3 = 0 -> 0.3 (Welch), by population and rho:\n');
for pp = {'learners', 'fixed20'}
    for r = rhos
        a = T(T.pop == pp{1} & T.rho == r & T.w3 == 0, :);
        b = T(T.pop == pp{1} & T.rho == r & T.w3 == 0.3, :);
        [~, pQ] = ttest2(b.TrueQuality, a.TrueQuality, 'Vartype', 'unequal');
        [~, pG] = ttest2(b.GamingPrevalence, a.GamingPrevalence, 'Vartype', 'unequal');
        [~, pO] = ttest2(b.OverrunPct, a.OverrunPct, 'Vartype', 'unequal');
        fprintf('%-8s rho=%.1f: d(quality)=%+.4f (p=%.2g) | d(gaming)=%+.3f (p=%.2g) | d(overrun)=%+.2f pp (p=%.2g)\n', ...
            pp{1}, r, mean(b.TrueQuality) - mean(a.TrueQuality), pQ, ...
            mean(b.GamingPrevalence) - mean(a.GamingPrevalence), pG, ...
            mean(b.OverrunPct) - mean(a.OverrunPct), pO);
    end
end
writetable(T, fullfile(outDir, 'E4_poisoning.csv'));
save(fullfile(outDir, 'E4_series.mat'), 'gapSeries', 'qSeries', 'WW', 'PP', 'OO');
