%% RUN_RING_AWARE  E3b (RQ2): partner-aware ring with focal leader/follower roles.
% Ring members observe whether a partner is in the tender and their role
% (leader = lowest id). With shared Q and full reward sharing (lambda = 1) a
% rotation policy is learnable. Ring sizes up to 80 locate the threshold at
% which tender-level coincidence lets the ring raise prices / concentrate.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));
outDir = fullfile(here, '..', '..', 'results');

sizes = [0 10 20 40 60 80];
lams = [0 1];
cells = [0 0 0 0];
for n = sizes(2:end)
    for lam = lams
        for aware = [0 1]
            cells(end + 1, :) = [n lam 1 aware]; %#ok<SAGROW>   % shareQ = 1
        end
    end
end
nRuns = 30; nC = size(cells, 1);
[RR, CC] = ndgrid(1:nRuns, 1:nC);
out = zeros(numel(RR), 10);
parfor c = 1:numel(RR)
    cl = cells(CC(c), :);
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = 1; cfg.greedyEval = true;
    cfg.ringSize = cl(1); cfg.lambda = cl(2); cfg.shareQ = logical(cl(3));
    cfg.partnerAware = logical(cl(4));
    cfg.seed = 17000 + 100 * CC(c) + RR(c);
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    idx = cfg.nTenders - cfg.evalWindow + 1:cfg.nTenders;
    inRing = mkt.pool.ringId(mkt.winner(idx)) == 1;
    ringValue = 100 * sum(mkt.price(idx(inRing))) / sum(mkt.price(idx));
    out(c, :) = [cl RR(c) m.hhi m.overrunPct m.coverRate ringValue m.gamingPrevalence];
end
T = array2table(out, 'VariableNames', {'ringSize', 'lambda', 'shareQ', 'aware', 'run', ...
    'HHI', 'OverrunPct', 'CoverRate', 'RingValueSharePct', 'GamingPrevalence'});
G = groupsummary(T, {'ringSize', 'lambda', 'aware'}, 'mean', ...
    {'HHI', 'OverrunPct', 'CoverRate', 'RingValueSharePct'});
disp(G);

% Aware vs unaware at lambda = 1: Welch on overrun and ring share excess
fprintf('\nAware vs unaware (lambda = 1): excess ring share over n%% and overrun difference\n');
for n = sizes(2:end)
    a = T(T.ringSize == n & T.lambda == 1 & T.aware == 1, :);
    u = T(T.ringSize == n & T.lambda == 1 & T.aware == 0, :);
    [~, pO] = ttest2(a.OverrunPct, u.OverrunPct, 'Vartype', 'unequal');
    [~, pR] = ttest(a.RingValueSharePct, n, 'Tail', 'right');
    fprintf('n=%2d: aware ring share %.1f%% (fair %d%%, p=%.2g) | d(overrun aware-unaware) = %+.2f pp (p=%.2g) | HHI aware %.0f\n', ...
        n, mean(a.RingValueSharePct), n, pR, mean(a.OverrunPct) - mean(u.OverrunPct), pO, mean(a.HHI));
end
writetable(T, fullfile(outDir, 'E3b_ring_aware.csv'));
