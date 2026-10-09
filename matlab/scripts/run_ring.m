%% RUN_RING  E3 (RQ2): can learners form a ring that reconcentrates the market?
% A ring of n learners shares reward (lambda) and optionally one Q-table.
% All suppliers learn, no verification (rho = 0), greedy evaluation window.
% Key reading: ring value share vs the fair share n/100, and HHI vs the
% competitive-market threshold of 1,000. Note that a PERFECT ring of n
% equal members has HHI = 10,000/n, so only n <= 9 can exceed 1,000 on its own.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));
outDir = fullfile(here, '..', '..', 'results');

% Cell list: baseline (n = 0) + n x lambda x shareQ
cells = [0 0 0];
for n = [5 10 20 40]
    for lam = [0 0.5 1]
        for sq = [0 1]
            cells(end + 1, :) = [n lam sq]; %#ok<SAGROW>
        end
    end
end
nRuns = 30;
nC = size(cells, 1);
out = zeros(nC * nRuns, 11);
[RR, CC] = ndgrid(1:nRuns, 1:nC);
parfor c = 1:numel(RR)
    cl = cells(CC(c), :);
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = 1; cfg.greedyEval = true;
    cfg.ringSize = cl(1); cfg.lambda = cl(2); cfg.shareQ = logical(cl(3));
    cfg.seed = 15000 + 100 * CC(c) + RR(c);
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    idx = cfg.nTenders - cfg.evalWindow + 1:cfg.nTenders;
    inRing = mkt.pool.ringId(mkt.winner(idx)) == 1;
    ringValue = 100 * sum(mkt.price(idx(inRing))) / sum(mkt.price(idx));
    out(c, :) = [cl RR(c) m.hhi m.overrunPct m.gamingPrevalence ...
                 m.coverRate m.ringShare ringValue baselineGuard(cl(1))];
end
T = array2table(out, 'VariableNames', {'ringSize', 'lambda', 'shareQ', 'run', ...
    'HHI', 'OverrunPct', 'GamingPrevalence', 'CoverRate', 'RingTenderShare', ...
    'RingValueSharePct', 'FairSharePct'});
T.FairSharePct = T.ringSize;                       % n/100 of 100 suppliers, in %
G = groupsummary(T, {'ringSize', 'lambda', 'shareQ'}, 'mean', ...
    {'HHI', 'OverrunPct', 'CoverRate', 'RingValueSharePct'});
disp(G);

% Excess ring share over fair share, one-sided test per cell
fprintf('\nCells where ring value share significantly exceeds fair share (Holm over %d tests):\n', height(G) - 1);
p = nan(height(G), 1);
for i = 1:height(G)
    s = T(T.ringSize == G.ringSize(i) & T.lambda == G.lambda(i) & T.shareQ == G.shareQ(i), :);
    if G.ringSize(i) > 0
        [~, p(i)] = ttest(s.RingValueSharePct, G.ringSize(i), 'Tail', 'right');
    end
end
valid = ~isnan(p); pv = p(valid);
[ps, ord] = sort(pv); m = numel(ps);
adj = min(1, cummax((m - (1:m)' + 1) .* ps)); pAdj = zeros(m, 1); pAdj(ord) = adj;
G.pHolm = nan(height(G), 1); G.pHolm(valid) = pAdj;
disp(G(G.pHolm < 0.05, {'ringSize', 'lambda', 'shareQ', 'mean_RingValueSharePct', 'mean_HHI', 'pHolm'}));
if ~any(G.pHolm < 0.05), disp('  none'); end
writetable(T, fullfile(outDir, 'E3_ring.csv'));

function v = baselineGuard(n), v = n; end
