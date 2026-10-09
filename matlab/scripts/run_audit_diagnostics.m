%% RUN_AUDIT_DIAGNOSTICS  E1b + E6: robustness of discovery and test of H4b.
% All suppliers learn. Three learning variants x five verification rates:
%   base       - epsilon-greedy throughout, neutral Q0   (as E1/E2)
%   greedy     - epsilon = 0 in the evaluation window
%   pessimist  - greedy + Q0 = -1 for non-honest actions (gaming must be discovered)
% H4b: as rho rises, gaming falls but part of the effect is displaced to pure
% overpricing (g = 0, markup > 0), which verification of quality cannot catch.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));

variants = {'base', 'greedy', 'pessimist'};
rhoLevels = [0 0.05 0.10 0.20 0.50];
nRuns = 30;
[R, V, P] = ndgrid(1:nRuns, 1:numel(variants), rhoLevels);
nCells = numel(R);
nA = numel(abmgov.SupplierPool.G);
out = zeros(nCells, 9);
actShare = zeros(nCells, nA);
overpriceValue = zeros(nCells, 1);
firstGaming = zeros(nCells, 1);

parfor c = 1:nCells
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = 1; cfg.blockSize = 20;
    cfg.rhoAudit = P(c);
    if V(c) >= 2, cfg.greedyEval = true; end
    if V(c) == 3, cfg.qInitNonHonest = -1; end
    cfg.seed = 7000 + R(c) + 100 * V(c) + round(1000 * P(c));
    mkt = abmgov.ProcurementMarket(cfg);
    mkt.run();
    m = mkt.metrics();
    out(c, :) = [V(c) P(c) R(c) m.hhi m.overrunPct m.gamingPrevalence ...
                 m.signalGap m.trueQuality m.caughtRate];
    idx = cfg.nTenders - cfg.evalWindow + 1:cfg.nTenders;
    wa = mkt.winnerAction(idx);
    actShare(c, :) = accumarray(wa, 1, [nA 1])' / numel(wa);
    pure = ismember(wa, [2 7]);                 % g = 0, markup > 0
    overpriceValue(c) = 100 * sum(mkt.price(idx(pure))) / sum(mkt.price(idx));
    firstGaming(c) = cfg.blockSize * find(m.series.gaming >= 0.25, 1, 'first');
end

T = array2table(out, 'VariableNames', {'variant', 'rho', 'run', 'HHI', ...
    'OverrunPct', 'GamingPrevalence', 'SignalGap', 'TrueQuality', 'CaughtRate'});
T.OverpriceOnlyValueSharePct = overpriceValue;
T.TendersToQuarterGaming = firstGaming;     % empty -> 0 means never reached
T = [T array2table(actShare, 'VariableNames', compose('act%d', 1:nA))];
T.variant = categorical(T.variant, 1:3, variants);

G = groupsummary(T, {'variant', 'rho'}, 'mean', {'HHI', 'OverrunPct', ...
    'GamingPrevalence', 'OverpriceOnlyValueSharePct', 'TrueQuality', 'TendersToQuarterGaming'});
disp(G(:, [1 2 4:end]));

% H4b tests per variant: correlation across rho of gaming vs overrun, and
% Welch test rho = 0 vs rho = 0.5 on overrun and overpricing share.
for v = variants
    a = T(T.variant == v{1} & T.rho == 0, :);
    b = T(T.variant == v{1} & T.rho == 0.5, :);
    [~, pO, ~, sO] = ttest2(b.OverrunPct, a.OverrunPct, 'Vartype', 'unequal');
    [~, pS] = ttest2(b.OverpriceOnlyValueSharePct, a.OverpriceOnlyValueSharePct, 'Vartype', 'unequal');
    fprintf('%-9s rho 0->0.5: d(overrun) = %+.2f pp (t=%.2f, p=%.2g) | d(overprice share) = %+.1f pp (p=%.2g) | d(gaming) = %+.2f\n', ...
        v{1}, mean(b.OverrunPct) - mean(a.OverrunPct), sO.tstat, pO, ...
        mean(b.OverpriceOnlyValueSharePct) - mean(a.OverpriceOnlyValueSharePct), pS, ...
        mean(b.GamingPrevalence) - mean(a.GamingPrevalence));
end

outDir = fullfile(here, '..', '..', 'results');
writetable(T, fullfile(outDir, 'E1b_E6_audit_diagnostics.csv'));
