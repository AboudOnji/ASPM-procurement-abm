%% RUN_BLACKLIST_SPEED  Controls pending after E6.
% Part A: does the audit-induced rise of overpricing / overrun survive when
%         the blacklist is switched off (blacklist = 0)? (isolates H4b)
% Part B: speed of discovery measured with the GREEDY policy (share of
%         learners whose argmax-Q action inflates the signal) for neutral and
%         pessimistic priors and learning rates alpha.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));
outDir = fullfile(here, '..', '..', 'results');

%% Part A
bl = [50 0]; rho = [0 0.2 0.5]; nRuns = 30;
[R, B, P] = ndgrid(1:nRuns, bl, rho);
outA = zeros(numel(R), 7);
parfor c = 1:numel(R)
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = 1; cfg.greedyEval = true;
    cfg.rhoAudit = P(c); cfg.blacklist = B(c);
    cfg.seed = 11000 + R(c) + 10 * B(c) + round(1000 * P(c));
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    idx = cfg.nTenders - cfg.evalWindow + 1:cfg.nTenders;
    wa = mkt.winnerAction(idx);
    over = 100 * sum(mkt.price(idx(ismember(wa, [2 7])))) / sum(mkt.price(idx));
    outA(c, :) = [B(c) P(c) R(c) m.hhi m.overrunPct m.gamingPrevalence over];
end
TA = array2table(outA, 'VariableNames', {'blacklist', 'rho', 'run', 'HHI', ...
    'OverrunPct', 'GamingPrevalence', 'OverpriceOnlyValueSharePct'});
disp(groupsummary(TA, {'blacklist', 'rho'}, 'mean', {'HHI', 'OverrunPct', ...
    'GamingPrevalence', 'OverpriceOnlyValueSharePct'}));
for b = bl
    x0 = TA(TA.blacklist == b & TA.rho == 0, :); x5 = TA(TA.blacklist == b & TA.rho == 0.5, :);
    [~, p] = ttest2(x5.OverrunPct, x0.OverrunPct, 'Vartype', 'unequal');
    fprintf('blacklist=%2d: d(overrun, rho 0->0.5) = %+.2f pp (p=%.2g); d(overprice share) = %+.1f pp\n', ...
        b, mean(x5.OverrunPct) - mean(x0.OverrunPct), p, ...
        mean(x5.OverpriceOnlyValueSharePct) - mean(x0.OverpriceOnlyValueSharePct));
end
writetable(TA, fullfile(outDir, 'E6b_blacklist_control.csv'));

%% Part B
alphas = [0.05 0.10 0.30]; priors = [0 -1]; nR = 8; Tn = 30000; blk = 500;
[R2, A2, Q2] = ndgrid(1:nR, alphas, priors);
nB = Tn / blk;
series = zeros(numel(R2), nB);
parfor c = 1:numel(R2)
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = 1; cfg.nTenders = Tn; cfg.blockSize = blk;
    cfg.alpha = A2(c); cfg.qInitNonHonest = Q2(c);
    cfg.seed = 13000 + c;
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    series(c, :) = m.series.greedyGaming';
end
fprintf('\nTenders until >=50%% of learners greedy-inflate (mean over %d runs; NaN = not reached in %d):\n', nR, Tn);
for q = priors
    for a = alphas
        s = mean(series(A2 == a & Q2 == q, :), 1);
        k = find(s >= 0.5, 1);
        if isempty(k), t50 = NaN; else, t50 = k * blk; end
        fprintf('  Q0=%+d alpha=%.2f -> %g tenders (final share %.2f)\n', q, a, t50, s(end));
    end
end
save(fullfile(outDir, 'E1c_discovery_speed.mat'), 'series', 'A2', 'Q2', 'blk');
