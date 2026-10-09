%% GENERATE_HYPOTHETICAL_DATA  Export the hypothetical tender dataset used by the model.
% The confidential dataset that motivated the statistical specification cannot be
% shared. This script generates hypothetical tenders that reproduce its profile:
%   budget   ~ LogNormal(mu = 12, sigma = 1.5)  (MXN)
%   procType   1 direct award (43%), 2 public tender, 3 invitation
%   nBidders   4-6 competing bids (algorithmic allocation opens every tender)
%   collusive  ground-truth flag, ~20% of competitive tenders (not used by the allocator)
% The model draws exactly the same data internally for a given seed, so this export
% shows what a run with that seed uses. Usage: generate_hypothetical_data(seed, nTenders).

function generate_hypothetical_data(seed, nTenders)
arguments
    seed (1,1) double = 2026
    nTenders (1,1) double = 5000
end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..'));
rs = RandStream('mt19937ar', 'Seed', seed);
d = abmgov.generateSyntheticData(nTenders, rs);
T = table((1:nTenders)', d.amount, d.procType, d.nBidders, d.collusive, ...
    'VariableNames', {'tender', 'budget_mxn', 'procedure_type', 'n_bidders', 'collusive_flag'});
outDir = fullfile(here, '..', '..', 'data');
if ~exist(outDir, 'dir'), mkdir(outDir); end
f = fullfile(outDir, sprintf('hypothetical_tenders_seed%d.csv', seed));
writetable(T, f);
fprintf('Wrote %d hypothetical tenders to %s\n', nTenders, f);
fprintf('Direct awards: %.1f%% | mean log budget %.2f (sd %.2f) | collusive among competitive: %.1f%%\n', ...
    100 * mean(d.procType == 1), mean(log(d.amount)), std(log(d.amount)), 100 * mean(d.collusive(d.procType ~= 1)));
end
