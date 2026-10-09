classdef SupplierPool < handle
%SUPPLIERPOOL Population of supplier agents with heterogeneous strategy types.
%   Each supplier has a true quality, an efficiency, a policy type
%   (honest / endogenous learner / fixed gamer) and, for learners, a Q-table.
%
%   Action menu (shared by all agents):
%       a   inflation g   markup m   meaning
%       1   0             0          honest bid
%       2   0             0.04       honest signal, overpriced
%       3   0.125         0          mild signal inflation
%       4   0.125         0.04       mild inflation + rent
%       5   0.25          0.04       strong inflation + small rent
%       6   0.25          0.08       strong inflation + rent (assigned gamer of the base study)
%       7   0             0.15       cover bid (supports a ring partner)

    properties (Constant)
        G = [0 0 0.125 0.125 0.25 0.25 0];
        M = [0 0.04 0 0.04 0.04 0.08 0.15];
        COVER = 7;
        NSTATES = 6;      % outcome (lost / won-clean / caught) x competition (low/high)
        POLICY_HONEST = 0;
        POLICY_LEARNER = 1;
        POLICY_FIXED = 2;
    end

    properties
        cfg
        N                 % number of suppliers
        q                 % true (delivered) quality
        eff               % efficiency
        policy            % N x 1 policy type
        ringId            % N x 1, 0 = not in a ring
        learnerId         % N x 1, index into Q
        Q                 % NSTATES x nActions x nLearners
        state             % N x 1 current state
        isCartel          % N x 1 logical, cartel members steerable by a discretionary buyer
        role              % N x 1 ring role in the current tender (0 none, 1 leader, 2 follower)
        perf              % N x 1 recorded past performance
        blacklistUntil    % N x 1 tender index until which supplier is excluded
        rs                % RandStream
    end

    methods
        function obj = SupplierPool(cfg, rs)
            obj.cfg = cfg;
            obj.rs  = rs;
            n = cfg.nSuppliers;
            obj.N   = n;
            obj.q   = cfg.qualityRange(1) + diff(cfg.qualityRange) * rand(rs, n, 1);
            obj.eff = cfg.effRange(1)     + diff(cfg.effRange)     * rand(rs, n, 1);

            % Assign policies on a random permutation (exogenous gamers first,
            % then learners, rest honest).
            perm = randperm(rs, n);
            nFixed = round(cfg.piG * n);
            nLearn = round(cfg.learnFrac * n);
            obj.policy = zeros(n, 1);
            obj.policy(perm(1:nFixed)) = obj.POLICY_FIXED;
            obj.policy(perm(nFixed + (1:nLearn))) = obj.POLICY_LEARNER;

            % Ring of learners (RQ2)
            obj.ringId = zeros(n, 1);
            learners = find(obj.policy == obj.POLICY_LEARNER);
            nRing = min(cfg.ringSize, numel(learners));
            obj.ringId(learners(1:nRing)) = 1;

            obj.learnerId = (1:n)';
            if cfg.shareQ
                obj.learnerId(obj.ringId == 1) = n + 1;
            end
            nA = numel(obj.G);
            obj.Q = zeros(3 * obj.NSTATES, nA, n + 1);   % x3: ring-role copies of the state space
            obj.role = zeros(n, 1);
            obj.Q(:, 2:end, :) = cfg.qInitNonHonest;   % prior belief about non-honest actions
            obj.state = 2 * ones(n, 1);                 % lost-before, high competition
            obj.perf = cfg.initPerf * ones(n, 1);
            obj.blacklistUntil = zeros(n, 1);
            obj.isCartel = false(n, 1);
            if cfg.cartelSize > 0          % drawn last so other experiments keep their RNG stream
                obj.isCartel(randperm(rs, n, cfg.cartelSize)) = true;
            end
        end

        function a = chooseActions(obj, idx, t)
            %CHOOSEACTIONS epsilon-greedy for learners, fixed/honest otherwise.
            a = ones(numel(idx), 1);
            eps0 = obj.cfg.epsilon;
            if obj.cfg.greedyEval && t > obj.cfg.nTenders - obj.cfg.evalWindow
                eps0 = 0;       % no exploration in the evaluation window
            end
            for j = 1:numel(idx)
                i = idx(j);
                switch obj.policy(i)
                    case obj.POLICY_FIXED
                        a(j) = obj.cfg.fixedGamerAction;
                    case obj.POLICY_LEARNER
                        if rand(obj.rs) < eps0
                            a(j) = randi(obj.rs, numel(obj.G));
                        else
                            qs = obj.Q(obj.stateIndex(i), :, obj.learnerId(i));
                            best = find(qs == max(qs));
                            a(j) = best(randi(obj.rs, numel(best)));
                        end
                end
            end
        end

        function si = stateIndex(obj, i)
            %STATEINDEX Row of Q for supplier i (state + 6 x role when partner-aware).
            si = obj.state(i);
            if obj.cfg.partnerAware, si = si + obj.NSTATES * obj.role(i); end
        end

        function share = greedyGamingShare(obj, idx)
            %GREEDYGAMINGSHARE Share of learners in idx whose greedy action inflates the signal.
            L = idx(obj.policy(idx) == obj.POLICY_LEARNER);
            if isempty(L), share = NaN; return; end
            flags = false(numel(L), 1);
            for j = 1:numel(L)
                qs = obj.Q(obj.state(L(j)), :, obj.learnerId(L(j)));
                [~, ga] = max(qs);              % first maximiser (honest wins ties)
                flags(j) = obj.G(ga) > 0;
            end
            share = mean(flags);
        end

        function update(obj, idx, a, r, nextState)
            %UPDATE Q-learning step (Bellman rule, as in the base study) for learners.
            for j = 1:numel(idx)
                i = idx(j);
                if obj.policy(i) == obj.POLICY_LEARNER
                    L = obj.learnerId(i);
                    s = obj.stateIndex(i);
                    nextQ = obj.Q(nextState(j), :, L);
                    if obj.cfg.partnerAware
                        nextQ = [nextQ, obj.Q(nextState(j) + obj.NSTATES, :, L), ...
                                        obj.Q(nextState(j) + 2 * obj.NSTATES, :, L)];
                    end
                    target = r(j) + obj.cfg.gamma * max(nextQ);
                    obj.Q(s, a(j), L) = obj.Q(s, a(j), L) + ...
                        obj.cfg.alpha * (target - obj.Q(s, a(j), L));
                end
                obj.state(i) = nextState(j);
            end
        end
    end
end
