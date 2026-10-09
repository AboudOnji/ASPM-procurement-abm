%% REPLICATE_ALL  Run every experiment of the paper in order and regenerate the figures.
% Runtime: roughly 30-60 minutes on 8 cores (Parallel Computing Toolbox recommended;
% parfor falls back to serial execution without it). Results go to ../results,
% figures to ../figures.
here = fileparts(mfilename('fullpath'));
addpath(here);
runtests(fullfile(here, 'tests', 'TestAbmGov.m'));          % unit tests
scripts = {'run_validation', 'run_discovery', 'run_endogenous_gaming', 'run_audit_diagnostics', ...
    'run_blacklist_speed', 'run_ring', 'run_ring_aware', 'run_poisoning', 'run_poisoning_control', ...
    'run_global_sensitivity', 'run_review_checks', 'run_confirmatory', 'make_figures'};
for k = 1:numel(scripts)
    fprintf('\n=== %s ===\n', scripts{k});
    run(fullfile(here, 'scripts', [scripts{k} '.m']));
end
