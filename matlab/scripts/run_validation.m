%% RUN_VALIDATION  Phase 1: does the model reproduce the exogenous-gaming results of the base study?
% Sweeps the share of exogenous gamers piG in {0, .05, .10, .15, .20} under AI
% Meritocracy (composite score) and compares with Table 5 of the base study (2026): HHI ~ 240 (flat), overrun 11.6% -> 13.3%.
% Acceptance: HHI < 1000 for every run and overrun monotone increasing in piG.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));

piLevels = [0 0.05 0.10 0.15 0.20];
nRuns = 30;
rows = zeros(numel(piLevels) * nRuns, 6);
k = 0;
for p = 1:numel(piLevels)
    for r = 1:nRuns
        cfg = abmgov.defaultConfig();
        cfg.nTenders = 1000; cfg.evalWindow = 1000;   % same horizon as the base study
        cfg.piG = piLevels(p);
        cfg.seed = 2026 + r + 10000 * p;
        mkt = abmgov.ProcurementMarket(cfg);
        mkt.run();
        m = mkt.metrics();
        k = k + 1;
        rows(k, :) = [piLevels(p) r m.hhi m.overrunPct m.gamerValueShare m.trueQuality];
    end
end

T = array2table(rows, 'VariableNames', ...
    {'piG', 'run', 'HHI', 'OverrunPct', 'GamerValueSharePct', 'TrueQuality'});
S = groupsummary(T, 'piG', {'mean', 'std'}, {'HHI', 'OverrunPct', 'GamerValueSharePct', 'TrueQuality'});
disp(S(:, {'piG', 'mean_HHI', 'std_HHI', 'mean_OverrunPct', 'std_OverrunPct', ...
           'mean_GamerValueSharePct', 'mean_TrueQuality'}));
fprintf('Max HHI over all runs: %.1f (competitive threshold 1000; base-study Status Quo 1752)\n', max(T.HHI));

outDir = fullfile(here, '..', '..', 'results');
if ~exist(outDir, 'dir'), mkdir(outDir); end
writetable(T, fullfile(outDir, 'validation_exogenous_gaming.csv'));
