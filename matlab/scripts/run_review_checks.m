%% RUN_REVIEW_CHECKS  Checks requested in the internal peer review (docs/PEER_REVIEW_1.md).
% (a) Positive control: discretionary regime in the SAME engine (can the model produce a cartel?).
% (b) Price screen: does a reference-price screen contain the rent that quality verification leaves?
% (c) Stationarity of learned gaming in the evaluation horizon.
clear; clc;
here = fileparts(mfilename('fullpath')); addpath(fullfile(here, '..'));
outDir = fullfile(here, '..', '..', 'results'); nRuns = 30;

%% (a) Positive control
Ds = [0 0.25 0.5 0.8 0.95]; learn = [0 1];
[R, D, L] = ndgrid(1:nRuns, Ds, learn);
outA = zeros(numel(R), 6);
parfor c = 1:numel(R)
    cfg = abmgov.defaultConfig();
    cfg.discretion = D(c); cfg.cartelSize = 5;
    if L(c) == 1, cfg.learnFrac = 1; cfg.greedyEval = true; end
    cfg.seed = 41000 + c;
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    outA(c, :) = [D(c) L(c) R(c) m.hhi m.overrunPct m.steeredShare];
end
TA = array2table(outA, 'VariableNames', {'discretion', 'learners', 'run', 'HHI', 'OverrunPct', 'SteeredShare'});
disp(groupsummary(TA, {'learners', 'discretion'}, 'mean', {'HHI', 'OverrunPct', 'SteeredShare'}));
writetable(TA, fullfile(outDir, 'R1_positive_control.csv'));

%% (b) Price screen
taus = [Inf 0.10 0.05]; rhos = [0 0.2 0.5];
[R2, T2, P2] = ndgrid(1:nRuns, taus, rhos);
outB = zeros(numel(R2), 9);
parfor c = 1:numel(R2)
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = 1; cfg.greedyEval = true;
    cfg.priceScreenTau = T2(c); cfg.rhoAudit = P2(c); cfg.seed = 43000 + c;
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    idx = cfg.nTenders - cfg.evalWindow + 1:cfg.nTenders; wa = mkt.winnerAction(idx);
    mk = mean(mkt.pool.M(wa));
    over = 100 * sum(mkt.price(idx(ismember(wa, [2 7])))) / sum(mkt.price(idx));
    outB(c, :) = [T2(c) P2(c) R2(c) m.hhi m.overrunPct m.gamingPrevalence m.trueQuality mk over];
end
TB = array2table(outB, 'VariableNames', {'tau', 'rho', 'run', 'HHI', 'OverrunPct', ...
    'GamingPrevalence', 'TrueQuality', 'WinnerMarkup', 'OverpriceValueSharePct'});
disp(groupsummary(TB, {'tau', 'rho'}, 'mean', {'HHI', 'OverrunPct', 'GamingPrevalence', ...
    'TrueQuality', 'WinnerMarkup', 'OverpriceValueSharePct'}));
for t = taus(2:end)
    a = TB.OverrunPct(TB.tau == Inf & TB.rho == 0.5); b = TB.OverrunPct(TB.tau == t & TB.rho == 0.5);
    [~, p, ci] = ttest2(b, a, 'Vartype', 'unequal');
    fprintf('rho=0.5: screen tau=%.2f vs none: d(overrun) = %+.2f pp, 95%% CI [%.2f, %.2f]\n', t, mean(b) - mean(a), ci(1), ci(2));
end
writetable(TB, fullfile(outDir, 'R1_price_screen.csv'));

%% (c) Stationarity of learned gaming (rho = 0, all learn, greedy window)
g1 = zeros(nRuns, 1); g2 = zeros(nRuns, 1); g0 = zeros(nRuns, 1);
parfor r = 1:nRuns
    cfg = abmgov.defaultConfig(); cfg.learnFrac = 1; cfg.seed = 45000 + r;
    mkt = abmgov.ProcurementMarket(cfg); mkt.run();
    gg = mkt.pool.G(mkt.winnerAction)' > 0;
    g0(r) = mean(gg(1001:2000)); g1(r) = mean(gg(3001:4000)); g2(r) = mean(gg(4001:5000));
end
fprintf('\nStationarity: gaming prevalence tenders 1001-2000 = %.3f, 3001-4000 = %.3f, 4001-5000 = %.3f; mean diff (last two) = %+.4f, 95%% CI +-%.4f\n', ...
    mean(g0), mean(g1), mean(g2), mean(g2 - g1), 1.96 * std(g2 - g1) / sqrt(nRuns));
