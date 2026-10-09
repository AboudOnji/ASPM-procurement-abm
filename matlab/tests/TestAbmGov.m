classdef TestAbmGov < matlab.unittest.TestCase
%TESTABMGOV Unit and regression tests of the abmgov package.
%   Run with: results = runtests('TestAbmGov') from the matlab/tests folder
%   (the matlab/ folder must be on the path).

    methods (TestClassSetup)
        function addPackagePath(~)
            here = fileparts(mfilename('fullpath'));
            addpath(fullfile(here, '..'));
        end
    end

    methods (Test)
        function dataMatchesTable2(tc)
            d = abmgov.generateSyntheticData(20000, RandStream('mt19937ar', 'Seed', 1));
            tc.verifyEqual(mean(d.procType == 1), 0.43, 'AbsTol', 0.02);
            tc.verifyEqual(mean(log(d.amount)), 12, 'AbsTol', 0.05);
            tc.verifyEqual(std(log(d.amount)), 1.5, 'AbsTol', 0.05);
            tc.verifyTrue(all(d.nBidders >= 4 & d.nBidders <= 6));
            tc.verifyEqual(mean(d.collusive(d.procType ~= 1)), 0.20, 'AbsTol', 0.02);
        end

        function reproducibleWithSeed(tc)
            cfg = abmgov.defaultConfig(); cfg.nTenders = 300; cfg.learnFrac = 1;
            a = abmgov.ProcurementMarket(cfg); a.run();
            b = abmgov.ProcurementMarket(cfg); b.run();
            tc.verifyEqual(a.winner, b.winner);
            tc.verifyEqual(a.price, b.price);
        end

        function honestMarketHasNoGaming(tc)
            cfg = abmgov.defaultConfig(); cfg.nTenders = 1000;
            m = abmgov.ProcurementMarket(cfg); m.run();
            r = m.metrics();
            tc.verifyEqual(r.gamingPrevalence, 0);
            tc.verifyEqual(r.signalGap, 0);
            tc.verifyLessThan(r.hhi, 1000);
        end

        function exogenousGamersRaiseOverrunNotHHI(tc)
            res = zeros(1, 2);
            for j = 1:2
                ov = zeros(10, 1); hh = zeros(10, 1);
                for s = 1:10
                    cfg = abmgov.defaultConfig(); cfg.nTenders = 1000;
                    cfg.piG = (j - 1) * 0.20; cfg.seed = 40 + s;
                    m = abmgov.ProcurementMarket(cfg); m.run();
                    r = m.metrics(); ov(s) = r.overrunPct; hh(s) = r.hhi;
                end
                res(j) = mean(ov); hhi(j) = mean(hh); %#ok<AGROW>
            end
            tc.verifyGreaterThan(res(2), res(1));
            tc.verifyLessThan(max(hhi), 1000);
        end

        function auditReducesLearnedGaming(tc)
            g = zeros(1, 2);
            for j = 1:2
                v = zeros(5, 1);
                for s = 1:5
                    cfg = abmgov.defaultConfig(); cfg.learnFrac = 1;
                    cfg.rhoAudit = (j - 1) * 0.5; cfg.seed = 90 + s;
                    m = abmgov.ProcurementMarket(cfg); m.run();
                    r = m.metrics(); v(s) = r.gamingPrevalence;
                end
                g(j) = mean(v);
            end
            tc.verifyLessThan(g(2), g(1));
        end

        function blacklistExcludesCaughtSuppliers(tc)
            cfg = abmgov.defaultConfig(); cfg.nTenders = 600; cfg.piG = 0.5;
            cfg.rhoAudit = 1; cfg.blacklist = 40;
            m = abmgov.ProcurementMarket(cfg); m.run();
            idx = find(m.caught);
            tc.assertNotEmpty(idx);
            for t = idx(1:min(5, end))'
                until = t + cfg.blacklist;
                later = (t + 1):min(until, cfg.nTenders);
                tc.verifyFalse(any(m.winner(later) == m.winner(t)));
            end
        end
        function discretionCreatesConcentration(tc)
            cfg = abmgov.defaultConfig(); cfg.nTenders = 1000; cfg.discretion = 0.95; cfg.cartelSize = 5;
            m = abmgov.ProcurementMarket(cfg); m.run(); r = m.metrics();
            tc.verifyGreaterThan(r.hhi, 1000);
            tc.verifyEqual(r.steeredShare, 0.95, 'AbsTol', 0.04);
        end

        function priceScreenRemovesExpensiveBids(tc)
            cfg = abmgov.defaultConfig(); cfg.nTenders = 800; cfg.piG = 0.3; cfg.priceScreenTau = 0.0;
            m = abmgov.ProcurementMarket(cfg); m.run();
            ref = 1 + 0.10;                         % ceiling relative to the cheapest-possible reference
            tc.verifyTrue(all(isfinite(m.price)));
            tc.verifyLessThan(mean(m.price ./ m.trueCost), 1.5 * ref);
        end
    end
end
