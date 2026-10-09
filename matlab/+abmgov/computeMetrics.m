function m = computeMetrics(mkt, idx)
%COMPUTEMETRICS Market indicators over the tenders in idx.
%   hhi              - Herfindahl-Hirschman index of contract-value shares (0-10,000)
%   overrunPct       - value-weighted overrun, (sum price - sum trueCost)/sum trueCost
%   gamingPrevalence - share of tenders won with an inflated signal (g > 0)
%   gamerValueShare  - share of contract value won with an inflated signal
%   signalGap        - mean (observed - true) quality of winners
%   trueQuality      - mean delivered quality of winners
%   caughtRate       - share of tenders where a sanction was imposed
%   coverRate        - share of bids that are cover bids
%   ringShare        - share of tenders won by the ring (RQ2)
%   steeredShare     - share of tenders steered to a cartel member (discretionary regime)
%   rentLeakagePct   - overrun attributable to winners that inflated

winner = mkt.winner(idx);
price  = mkt.price(idx);
cost   = mkt.trueCost(idx);
g      = mkt.pool.G(mkt.winnerAction(idx))';

total = sum(price);
byFirm = accumarray(winner, price, [mkt.pool.N 1]);
m.hhi = sum((100 * byFirm / total).^2);
m.overrunPct = 100 * (total - sum(cost)) / sum(cost);

inflated = g > 0;
m.gamingPrevalence = mean(inflated);
m.gamerValueShare  = 100 * sum(price(inflated)) / total;
m.signalGap   = mean(mkt.winnerQObs(idx) - mkt.winnerQ(idx));
m.trueQuality = mean(mkt.winnerQ(idx));
m.caughtRate  = mean(mkt.caught(idx));
m.coverRate   = mean(mkt.coverShare(idx));
m.ringShare   = mean(mkt.ringWon(idx));
m.steeredShare = mean(mkt.steered(idx));
m.rentLeakagePct = 100 * (sum(price(inflated)) - sum(cost(inflated))) / sum(cost);
end
