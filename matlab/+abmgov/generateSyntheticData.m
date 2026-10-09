function data = generateSyntheticData(nTenders, rngStream)
%GENERATESYNTHETICDATA Synthetic procurement dataset replicating the profile of a confidential dataset.
%   data = abmgov.generateSyntheticData(nTenders, rngStream) returns a struct
%   with one entry per tender:
%       amount   - budget, log-normal(mu = 12, sigma = 1.5) in MXN
%       procType - 1 Direct Award (43%), 2 Public Tender (28.5%), 3 Invitation (28.5%)
%       nBidders - bidders admitted. Algorithmic allocation opens every tender,
%                  so Direct Awards also receive 4-6 bidders.
%       collusive- ground-truth flag, ~20% of competitive tenders (confidential profile)
%
%   Port of generate_synthetic_data.py; nothing here is derived from the
%   confidential agency data.

arguments
    nTenders (1,1) double {mustBePositive, mustBeInteger}
    rngStream (1,1) RandStream = RandStream.getGlobalStream
end

data.amount = exp(12 + 1.5 * randn(rngStream, nTenders, 1));

u = rand(rngStream, nTenders, 1);
data.procType = 1 + (u > 0.43) + (u > 0.715);

data.nBidders = randi(rngStream, [4 6], nTenders, 1);

data.collusive = (data.procType ~= 1) & (rand(rngStream, nTenders, 1) < 0.20);
data.nTenders = nTenders;
end
