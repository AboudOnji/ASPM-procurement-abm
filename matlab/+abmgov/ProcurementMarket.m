classdef ProcurementMarket < handle
%PROCUREMENTMARKET Algorithmic-allocation procurement market with learning suppliers.
%   m = abmgov.ProcurementMarket(cfg);  m.run();  res = m.metrics();
%
%   Per tender t:
%     1. Budget A_t, true cost C_t = trueCostShare * A_t, admitted bidders drawn
%        among non-blacklisted suppliers.
%     2. Every bidder picks an action (SupplierPool): signal inflation g, markup.
%     3. The allocator scores OBSERVED attributes only (as in the base study):
%            score = -wP * price/maxPrice + wQ * qObs + wH * pastPerformance
%     4. With prob. rhoAudit the winner is verified ex post; inflation is
%        caught with prob. 1 - exp(-g/catchScale) -> sanction + blacklist.
%     5. Rewards are in units of the honest margin; learners update Q.
%     6. The winner's performance record is fed with the delivered quality if
%        audited, otherwise with the (possibly inflated) signal (data poisoning
%        channel when wH > 0).

    properties
        cfg
        data
        pool
        rs
        % Per-tender logs (nTenders x 1)
        winner; price; trueCost; winnerQ; winnerQObs; winnerAction
        audited; caught; coverShare; ringWon; greedyGaming; steered
    end

    methods
        function obj = ProcurementMarket(cfg)
            obj.cfg = cfg;
            obj.rs  = RandStream('mt19937ar', 'Seed', cfg.seed);
            obj.data = abmgov.generateSyntheticData(cfg.nTenders, obj.rs);
            obj.pool = abmgov.SupplierPool(cfg, obj.rs);
            T = cfg.nTenders;
            obj.winner = zeros(T, 1);      obj.price = zeros(T, 1);
            obj.trueCost = zeros(T, 1);    obj.winnerQ = zeros(T, 1);
            obj.winnerQObs = zeros(T, 1);  obj.winnerAction = zeros(T, 1);
            obj.audited = false(T, 1);     obj.caught = false(T, 1);
            obj.coverShare = zeros(T, 1);  obj.ringWon = false(T, 1);
            obj.greedyGaming = nan(T, 1);   obj.steered = false(T, 1);
        end

        function run(obj)
            cfg = obj.cfg; P = obj.pool; rs = obj.rs;
            w = cfg.weights;
            for t = 1:cfg.nTenders
                C = cfg.trueCostShare * obj.data.amount(t);
                unit = cfg.margin * C;

                active = find(P.blacklistUntil < t);
                k = min(obj.data.nBidders(t), numel(active));
                part = active(randperm(rs, numel(active), k));
                part = part(:);

                P.role(:) = 0;
                if cfg.partnerAware
                    rp = part(P.ringId(part) == 1);
                    if numel(rp) >= 2
                        [~, ord] = sort(rp);
                        P.role(rp(ord(1))) = 1;
                        P.role(rp(ord(2:end))) = 2;
                    end
                end
                obj.greedyGaming(t) = P.greedyGamingShare(part);
                a = P.chooseActions(part, t);
                cost = C * (1 + cfg.costSpread * (1 - P.eff(part))) ...
                         .* (1 + cfg.costNoise * randn(rs, k, 1));
                price = cost .* (1 + cfg.margin + P.M(a)');
                qObs  = min(1, P.q(part) + P.G(a)');

                score = -w(1) * price / max(price) + w(2) * qObs + w(3) * P.perf(part);
                if isfinite(cfg.priceScreenTau)
                    ref = C * (1 + cfg.costSpread * 0.15) * (1 + cfg.refNoise * randn(rs));
                    valid = price <= ref * (1 + cfg.margin) * (1 + cfg.priceScreenTau);
                    if ~any(valid), valid = price == min(price); end
                    score(~valid) = -Inf;
                end
                [~, jw] = max(score);
                isSteered = false;
                if cfg.discretion > 0 && rand(rs) < cfg.discretion
                    pc = find(P.isCartel(part));
                    if ~isempty(pc)
                        jw = pc(randi(rs, numel(pc))); isSteered = true;
                    else
                        pool = find(P.isCartel & P.blacklistUntil < t);
                        if ~isempty(pool)           % cartel member is invited and wins at the highest bid
                            cm = pool(randi(rs, numel(pool)));
                            part = [part; cm]; a = [a; 1]; %#ok<AGROW>
                            cost = [cost; C * (1 + cfg.costSpread * (1 - P.eff(cm))) * (1 + cfg.costNoise * randn(rs))]; %#ok<AGROW>
                            price = [price; max(price)]; qObs = [qObs; P.q(cm)]; %#ok<AGROW>
                            k = k + 1; jw = k; isSteered = true;
                        end
                    end
                end
                iw = part(jw);

                % Ex-post verification of the winner
                isAudited = rand(rs) < cfg.rhoAudit;
                gW = P.G(a(jw));
                isCaught = isAudited && gW > 0 && ...
                           rand(rs) < 1 - exp(-gW / cfg.catchScale);

                % Rewards in margin units
                gameCost = cfg.kappa * P.G(a)' * C;
                r = -gameCost / unit;
                if isCaught
                    r(jw) = -cfg.penaltyMult;
                    P.blacklistUntil(iw) = t + cfg.blacklist;
                else
                    r(jw) = (price(jw) - cost(jw) - gameCost(jw)) / unit;
                end

                % Reward sharing inside the ring (RQ2)
                if cfg.lambda > 0
                    inRing = P.ringId(part) == 1;
                    if any(inRing)
                        rr = r;
                        rr(inRing) = (1 - cfg.lambda) * r(inRing) + cfg.lambda * mean(r(inRing));
                        r = rr;
                    end
                end

                % Next states: outcome (1 lost, 2 won clean, 3 caught) x competition
                outcome = ones(k, 1); outcome(jw) = 2 + isCaught;
                comp = 1 + (k > 4);
                nextState = (outcome - 1) * 2 + comp;
                P.update(part, a, r, nextState);

                % Performance record of the winner
                recorded = qObs(jw);
                if isAudited || cfg.recordTruth, recorded = P.q(iw); end
                P.perf(iw) = P.perf(iw) + cfg.perfRate * (recorded - P.perf(iw));

                % Logs
                obj.winner(t) = iw;        obj.price(t) = price(jw);
                obj.trueCost(t) = C;       obj.winnerQ(t) = P.q(iw);
                obj.winnerQObs(t) = qObs(jw);
                obj.winnerAction(t) = a(jw);
                obj.audited(t) = isAudited; obj.caught(t) = isCaught; obj.steered(t) = isSteered;
                obj.coverShare(t) = mean(a == P.COVER);
                obj.ringWon(t) = P.ringId(iw) == 1;
            end
        end

        function res = metrics(obj)
            %METRICS End-state indicators over the last evalWindow tenders
            %   plus block-level time series.
            T = obj.cfg.nTenders;
            idx = (T - obj.cfg.evalWindow + 1):T;
            res = abmgov.computeMetrics(obj, idx);
            B = obj.cfg.blockSize;
            nB = floor(T / B);
            res.series.gaming = zeros(nB, 1);
            res.series.overrun = zeros(nB, 1);
            res.series.hhi = zeros(nB, 1);
            res.series.greedyGaming = zeros(nB, 1);
            res.series.signalGap = zeros(nB, 1);
            res.series.trueQuality = zeros(nB, 1);
            for b = 1:nB
                m = abmgov.computeMetrics(obj, (b - 1) * B + (1:B));
                res.series.gaming(b) = m.gamingPrevalence;
                res.series.overrun(b) = m.overrunPct;
                res.series.hhi(b) = m.hhi;
                res.series.signalGap(b) = m.signalGap;
                res.series.trueQuality(b) = m.trueQuality;
                res.series.greedyGaming(b) = mean(obj.greedyGaming((b - 1) * B + (1:B)), 'omitnan');
            end
        end
    end
end
