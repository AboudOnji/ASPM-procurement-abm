%% RUN_GLOBAL_SENSITIVITY  E5: global sensitivity of the endogenous-gaming results.
% Latin Hypercube sample over learning, cost, verification and calibration
% parameters (all suppliers learn, greedy evaluation window). One run per
% design point. Outputs: PRCC (partial rank correlation) of each parameter on
% each indicator, and the share of the parameter space where HHI < 1,000.
% PRCC captures monotone effects only; interactions are not decomposed.

clear; clc;
here = fileparts(mfilename('fullpath')); addpath(fullfile(here, '..'));
outDir = fullfile(here, '..', '..', 'results');

names  = {'alpha', 'epsilon', 'gamma', 'kappa', 'catchScale', 'penaltyMult', ...
          'costSpread', 'costNoise', 'rhoAudit', 'wQuality', 'qInitNonHonest'};
lo     = [0.02 0.05 0.50 0.02 0.05  2 0.30 0.03 0.00 0.20 -1.0];
hi     = [0.30 0.30 0.99 0.30 0.30 10 1.00 0.10 0.50 0.60  0.0];
N = 1200;
rng(2026);
U = lhsdesign(N, numel(names));
X = lo + U .* (hi - lo);

Y = zeros(N, 6);     % HHI, overrun, gaming, quality, overprice share, signal gap
parfor c = 1:N
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = 1; cfg.greedyEval = true;
    x = X(c, :);
    cfg.alpha = x(1); cfg.epsilon = x(2); cfg.gamma = x(3); cfg.kappa = x(4);
    cfg.catchScale = x(5); cfg.penaltyMult = x(6); cfg.costSpread = x(7);
    cfg.costNoise = x(8); cfg.rhoAudit = x(9);
    cfg.weights = [1 - x(10), x(10), 0]; cfg.qInitNonHonest = x(11);
    cfg.seed = 31000 + c;
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    idx = cfg.nTenders - cfg.evalWindow + 1:cfg.nTenders;
    wa = mkt.winnerAction(idx);
    over = 100 * sum(mkt.price(idx(ismember(wa, [2 7])))) / sum(mkt.price(idx));
    Y(c, :) = [m.hhi m.overrunPct m.gamingPrevalence m.trueQuality over m.signalGap];
end
outNames = {'HHI', 'OverrunPct', 'GamingPrevalence', 'TrueQuality', 'OverpriceSharePct', 'SignalGap'};

% PRCC
P = zeros(numel(names), numel(outNames)); Pp = P;
for j = 1:numel(outNames)
    [r, p] = partialcorr(tiedrank(X), tiedrank(Y(:, j)));
    P(:, j) = r(:, 1) * 0;   %#ok<NASGU>
    for i = 1:numel(names)
        others = setdiff(1:numel(names), i);
        [P(i, j), Pp(i, j)] = partialcorr(tiedrank(X(:, i)), tiedrank(Y(:, j)), tiedrank(X(:, others)));
    end
end
R = array2table(P, 'RowNames', names, 'VariableNames', outNames);
disp('PRCC (rows: parameters; * = |PRCC| > 0.2 and p < 0.001):');
disp(round(R, 2));
fprintf('\nSignificant influences (|PRCC| > 0.2, p < 0.001):\n');
for j = 1:numel(outNames)
    k = find(abs(P(:, j)) > 0.2 & Pp(:, j) < 1e-3);
    [~, o] = sort(abs(P(k, j)), 'descend'); k = k(o);
    fprintf('  %-18s: %s\n', outNames{j}, strjoin(compose('%s (%+.2f)', string(names(k))', P(k, j)), ', '));
end

T = [array2table(X, 'VariableNames', names) array2table(Y, 'VariableNames', outNames)];
fprintf('\nHHI over %d design points: mean %.0f, 95th pct %.0f, max %.0f; share < 1000: %.1f%%\n', ...
    N, mean(T.HHI), prctile(T.HHI, 95), max(T.HHI), 100 * mean(T.HHI < 1000));
fprintf('Overrun: mean %.2f%%, range [%.2f, %.2f]; share below Status Quo 19.24%%: %.1f%%\n', ...
    mean(T.OverrunPct), min(T.OverrunPct), max(T.OverrunPct), 100 * mean(T.OverrunPct < 19.24));
fprintf('Gaming prevalence: mean %.2f, range [%.2f, %.2f]\n', mean(T.GamingPrevalence), min(T.GamingPrevalence), max(T.GamingPrevalence));

% Overpricing displacement across the space: among points with rho > 0.3, is the
% overpricing share higher than for rho < 0.1?
hi_r = T.rhoAudit > 0.3; lo_r = T.rhoAudit < 0.1;
[~, pd] = ttest2(T.OverpriceSharePct(hi_r), T.OverpriceSharePct(lo_r), 'Vartype', 'unequal');
[~, po] = ttest2(T.OverrunPct(hi_r), T.OverrunPct(lo_r), 'Vartype', 'unequal');
fprintf('rho>0.3 vs rho<0.1: overprice share %.1f vs %.1f%% (p=%.2g); overrun %.2f vs %.2f%% (p=%.2g)\n', ...
    mean(T.OverpriceSharePct(hi_r)), mean(T.OverpriceSharePct(lo_r)), pd, ...
    mean(T.OverrunPct(hi_r)), mean(T.OverrunPct(lo_r)), po);
writetable(T, fullfile(outDir, 'E5_global_sensitivity.csv'));
writetable(R, fullfile(outDir, 'E5_prcc.csv'), 'WriteRowNames', true);
