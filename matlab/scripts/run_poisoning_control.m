%% RUN_POISONING_CONTROL  E4b: isolate the feedback channel.
% Same score weights, record fed with the REPORTED signal (poisoned) or with
% the DELIVERED quality (truthful record). Any difference at equal weights is
% attributable to the poisoning channel itself, not to re-weighting the score.
clear; clc;
here = fileparts(mfilename('fullpath')); addpath(fullfile(here, '..'));
outDir = fullfile(here, '..', '..', 'results');
w3s = [0.1 0.3]; truth = [0 1]; pops = [1 2]; nRuns = 40;
[RR, WW, TT, OO] = ndgrid(1:nRuns, w3s, truth, pops);
out = zeros(numel(RR), 9);
parfor c = 1:numel(RR)
    cfg = abmgov.defaultConfig();
    cfg.weights = [0.6 0.4 - WW(c) WW(c)]; cfg.recordTruth = logical(TT(c));
    if OO(c) == 1, cfg.learnFrac = 1; cfg.greedyEval = true; else, cfg.piG = 0.20; end
    cfg.seed = 25000 + c;
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    out(c, :) = [OO(c) WW(c) TT(c) RR(c) m.hhi m.overrunPct m.gamingPrevalence m.signalGap m.trueQuality];
end
T = array2table(out, 'VariableNames', {'pop', 'w3', 'recordTruth', 'run', 'HHI', ...
    'OverrunPct', 'GamingPrevalence', 'SignalGap', 'TrueQuality'});
disp(groupsummary(T, {'pop', 'w3', 'recordTruth'}, 'mean', {'HHI', 'OverrunPct', ...
    'GamingPrevalence', 'SignalGap', 'TrueQuality'}));
for pp = [1 2]
    for w = w3s
        a = T(T.pop == pp & T.w3 == w & T.recordTruth == 0, :);   % poisoned
        b = T(T.pop == pp & T.w3 == w & T.recordTruth == 1, :);   % truthful
        [~, pG] = ttest2(a.GamingPrevalence, b.GamingPrevalence, 'Vartype', 'unequal');
        [~, pO] = ttest2(a.OverrunPct, b.OverrunPct, 'Vartype', 'unequal');
        [~, pQ] = ttest2(a.TrueQuality, b.TrueQuality, 'Vartype', 'unequal');
        fprintf('pop=%d w3=%.1f poisoned-truthful: d(gaming)=%+.3f (p=%.2g) d(overrun)=%+.2f pp (p=%.2g) d(quality)=%+.4f (p=%.2g)\n', ...
            pp, w, mean(a.GamingPrevalence) - mean(b.GamingPrevalence), pG, ...
            mean(a.OverrunPct) - mean(b.OverrunPct), pO, mean(a.TrueQuality) - mean(b.TrueQuality), pQ);
    end
end
writetable(T, fullfile(outDir, 'E4b_poisoning_control.csv'));
