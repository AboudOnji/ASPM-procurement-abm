%% RUN_CONFIRMATORY  Confirmatory test of H1a-H5 (see docs/CONFIRMATORY_PROTOCOL.md).
% Independent seeds, decision rules and margins fixed before execution.
% Holm adjustment across the ten hypotheses; supported if adjusted p < 0.05.
clear; clc;
here = fileparts(mfilename('fullpath')); addpath(fullfile(here, '..'));
outDir = fullfile(here, '..', '..', 'results');
nRuns = 50; cells = {'A', 'B', 'C', 'D', 'F', 'G', 'H', 'I'};
[R, K] = ndgrid(1:nRuns, 1:numel(cells));
out = zeros(numel(R), 9);
parfor c = 1:numel(R)
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = 1; cfg.greedyEval = true;
    switch cells{K(c)}
        case 'B', cfg.discretion = 0.95; cfg.cartelSize = 5;
        case 'C', cfg.rhoAudit = 0.5;
        case 'D', cfg.rhoAudit = 0.5; cfg.priceScreenTau = 0.05;
        case 'F', cfg.ringSize = 40; cfg.lambda = 1; cfg.shareQ = true;
        case 'G', cfg.ringSize = 80; cfg.lambda = 1; cfg.shareQ = true;
        case 'H', cfg.weights = [0.6 0.1 0.3];
        case 'I', cfg.weights = [0.6 0.1 0.3]; cfg.recordTruth = true;
    end
    cfg.seed = 710000 + 1000 * K(c) + R(c);
    mkt = abmgov.ProcurementMarket(cfg); mkt.run(); m = mkt.metrics();
    idx = cfg.nTenders - cfg.evalWindow + 1:cfg.nTenders;
    prem = mean(mkt.pool.M(mkt.winnerAction(idx)));
    inRing = mkt.pool.ringId(mkt.winner(idx)) == 1;
    ringVal = 100 * sum(mkt.price(idx(inRing))) / sum(mkt.price(idx));
    out(c, :) = [K(c) R(c) m.hhi m.overrunPct m.gamingPrevalence 100 * prem m.trueQuality ringVal m.steeredShare];
end
T = array2table(out, 'VariableNames', {'cell', 'run', 'HHI', 'OverrunPct', 'Inflation', ...
    'PremiumPct', 'Quality', 'RingValueSharePct', 'Steered'});
T.cell = categorical(T.cell, 1:numel(cells), cells);
writetable(T, fullfile(outDir, 'CONF_runs.csv'));
g = @(c, v) T.(v)(T.cell == c);


H = {}; P = []; E = {}; 
% H1a
[p, est, ci] = onesample(g('A', 'Inflation'), 0.5, 'right');
H{end+1} = 'H1a'; P(end+1) = p; E{end+1} = sprintf('inflation share %.3f [%.3f, %.3f]', est, ci);
% H1b
[p1, est1, ci1] = onesample(g('A', 'HHI'), 1000, 'left');
[p2, est2, ci2] = onesample(g('B', 'HHI'), 1000, 'right');
okmax = max(g('A', 'HHI')) < 1000;
H{end+1} = 'H1b'; P(end+1) = max([p1 p2, ~okmax]); 
E{end+1} = sprintf('HHI A %.0f [%.0f, %.0f] max %.0f; B %.0f [%.0f, %.0f]', est1, ci1, max(g('A','HHI')), est2, ci2);
% H2a-c
[p, est, ci] = twosample(g('C', 'Inflation'), g('A', 'Inflation'), -0.30, 'left');
H{end+1} = 'H2a'; P(end+1) = p; E{end+1} = sprintf('d inflation %.3f [%.3f, %.3f]', est, ci);
[p, est, ci] = twosample(g('C', 'PremiumPct'), g('A', 'PremiumPct'), -1.0, 'right');
H{end+1} = 'H2b'; P(end+1) = p; E{end+1} = sprintf('d premium %.2f pp [%.2f, %.2f]', est, ci);
[p, est, ci] = twosample(g('C', 'OverrunPct'), g('A', 'OverrunPct'), -1.5, 'right');
H{end+1} = 'H2c'; P(end+1) = p; E{end+1} = sprintf('d overrun %.2f pp [%.2f, %.2f]', est, ci);
% H3a
[pa, est, ci] = twosample(g('F', 'OverrunPct'), g('A', 'OverrunPct'), -1.5, 'right');
[pb, ~, ~] = twosample(g('F', 'OverrunPct'), g('A', 'OverrunPct'), 1.5, 'left');
[pc, estc, cic] = onesample(g('F', 'RingValueSharePct'), 45, 'left');
H{end+1} = 'H3a'; P(end+1) = max([pa pb pc]);
E{end+1} = sprintf('d overrun %.2f pp [%.2f, %.2f]; ring share %.1f%% [%.1f, %.1f]', est, ci, estc, cic);
% H3b
[pa, est, ci] = twosample(g('G', 'OverrunPct'), g('A', 'OverrunPct'), 1.5, 'right');
[pb, estb, cib] = onesample(g('G', 'HHI'), 1000, 'left');
H{end+1} = 'H3b'; P(end+1) = max([pa pb]);
E{end+1} = sprintf('d overrun %.2f pp [%.2f, %.2f]; HHI %.0f [%.0f, %.0f]', est, ci, estb, cib);
% H4a
[pa, est, ci] = twosample(g('H', 'Inflation'), g('I', 'Inflation'), 0, 'right');
[pb, estb, cib] = twosample(g('H', 'Quality'), g('I', 'Quality'), 0, 'left');
H{end+1} = 'H4a'; P(end+1) = max([pa pb]);
E{end+1} = sprintf('d inflation %.3f [%.3f, %.3f]; d quality %.4f [%.4f, %.4f]', est, ci, estb, cib);
% H4b
[p, est, ci] = twosample(g('H', 'Inflation'), g('A', 'Inflation'), 0, 'left');
H{end+1} = 'H4b'; P(end+1) = p; E{end+1} = sprintf('d inflation %.3f [%.3f, %.3f]', est, ci);
% H5
[pa, est, ci] = twosample(g('D', 'OverrunPct'), g('C', 'OverrunPct'), 0, 'left');
[pb, ~, ~] = twosample(g('D', 'OverrunPct'), g('C', 'OverrunPct'), -1.5, 'right');
H{end+1} = 'H5'; P(end+1) = max([pa pb]); E{end+1} = sprintf('d overrun %.2f pp [%.2f, %.2f]', est, ci);

% Holm adjustment
[ps, ord] = sort(P); m = numel(ps);
adj = min(1, cummax((m - (1:m) + 1) .* ps)); padj = zeros(1, m); padj(ord) = adj;
Out = table(string(H'), string(E'), P', padj', padj' < 0.05, ...
    'VariableNames', {'Hypothesis', 'Estimate', 'p_raw', 'p_holm', 'Supported'});
disp(Out); writetable(Out, fullfile(outDir, 'CONF_hypotheses.csv'));
disp(groupsummary(T, 'cell', 'mean', {'HHI', 'OverrunPct', 'Inflation', 'PremiumPct', 'Quality'}));

function [p, est, ci] = onesample(x, null, tail)
    [~, p, ~, ~] = ttest(x, null, 'Tail', tail); est = mean(x);
    [~, ~, ci] = ttest(x); 
end
function [p, est, ci] = twosample(x, y, null, tail)
    d = mean(x) - mean(y);
    se = sqrt(var(x) / numel(x) + var(y) / numel(y));
    df = se^4 / ((var(x) / numel(x))^2 / (numel(x) - 1) + (var(y) / numel(y))^2 / (numel(y) - 1));
    t = (d - null) / se;
    switch tail
        case 'right', p = tcdf(-t, df);
        case 'left', p = tcdf(t, df);
    end
    est = d; ci = d + tinv([0.025 0.975], df) * se;
end
