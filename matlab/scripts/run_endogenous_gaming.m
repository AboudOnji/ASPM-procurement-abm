%% RUN_ENDOGENOUS_GAMING  Phase 2 (RQ1, RQ4): learned gaming vs ex-post verification.
% All suppliers learn (Q-learning). Sweeps the verification rate rhoAudit and
% reports end-state HHI, overrun, gaming prevalence and signal gap.
% Uses parfor when the Parallel Computing Toolbox is available.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));

rhoLevels = [0 0.05 0.10 0.20 0.50];
nRuns = 30;
[R, P] = ndgrid(1:nRuns, rhoLevels);
nCells = numel(R);
out = zeros(nCells, 9);

parfor c = 1:nCells
    cfg = abmgov.defaultConfig();
    cfg.learnFrac = 1;
    cfg.rhoAudit = P(c);
    cfg.seed = 3000 + R(c) + round(1000 * P(c));
    mkt = abmgov.ProcurementMarket(cfg);
    mkt.run();
    m = mkt.metrics();
    out(c, :) = [P(c) R(c) m.hhi m.overrunPct m.gamingPrevalence ...
                 m.gamerValueShare m.signalGap m.trueQuality m.caughtRate];
end

T = array2table(out, 'VariableNames', {'rho', 'run', 'HHI', 'OverrunPct', ...
    'GamingPrevalence', 'GamerValueSharePct', 'SignalGap', 'TrueQuality', 'CaughtRate'});
disp(groupsummary(T, 'rho', 'mean', {'HHI', 'OverrunPct', 'GamingPrevalence', ...
    'SignalGap', 'TrueQuality'}));

outDir = fullfile(here, '..', '..', 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end
writetable(T, fullfile(outDir, 'endogenous_gaming_audit_sweep.csv'));
