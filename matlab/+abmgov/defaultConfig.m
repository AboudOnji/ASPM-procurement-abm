function cfg = defaultConfig()
%DEFAULTCONFIG Default parameters of the endogenous-gaming procurement ABM.
%   cfg = abmgov.defaultConfig() returns a struct with every model parameter.
%   Override fields before calling abmgov.ProcurementMarket, e.g.
%       cfg = abmgov.defaultConfig(); cfg.rhoAudit = 0.10;
%
%   Parameters inherited from the base study (2026) are marked [base];
%   new parameters of this study are marked [new].

% --- Reproducibility and horizon
cfg.seed        = 2026;     % base RNG seed
cfg.nSuppliers  = 100;      % [base] supplier pool
cfg.nTenders    = 5000;     % [new] learning needs a longer horizon than the base study (1,000)
cfg.evalWindow  = 1000;     % [new] last tenders used for end-state metrics
cfg.blockSize   = 100;      % [new] block length for time series

% --- Market primitives
cfg.trueCostShare = 0.90;   % [base] true market cost = 0.9 x budget
cfg.margin        = 0.10;   % [base] honest margin
cfg.costSpread    = 0.70;   % [new] cost penalty of an inefficient supplier (eff 0.7 -> +21%)
cfg.costNoise     = 0.07;   % [new] tender-specific cost noise (sd)
                            % costSpread/costNoise calibrated (grid, 20 runs) so that the
                            % piG = 0 baseline matches Table 5 of the base study: overrun ~11.7% (11.64),
                            % HHI ~276 (247 +/- 13). See docs/CALIBRATION.md.
cfg.qualityRange  = [0.7 1.0];   % [base] true quality ~ U
cfg.effRange      = [0.7 1.0];   % [base] efficiency ~ U

% --- Allocation algorithm (AI Meritocracy), as in the base study
cfg.weights  = [0.6 0.4 0.0];   % [wPrice wQuality wPastPerformance]
cfg.initPerf = 0.8;             % [new] initial past-performance record
cfg.perfRate = 0.10;            % [new] EMA rate of the performance record
cfg.recordTruth = false;        % [new] control: record is always fed with delivered quality

% --- Ex-post verification of delivered quality (countermeasure R)
cfg.rhoAudit    = 0.0;      % [new] probability the winner is verified ex post
cfg.catchScale  = 0.10;     % [new] detection prob = 1-exp(-inflation/catchScale)
cfg.penaltyMult = 5;        % [base] sanction = 5 x honest margin
cfg.blacklist   = 50;       % [new] tenders a caught supplier is excluded

% --- Supplier population: who games and how
cfg.piG         = 0.0;      % [base] share of EXOGENOUS gamers (fixed policy)
cfg.learnFrac   = 0.0;      % [new] share of ENDOGENOUS learners (Q-learning)
cfg.kappa       = 0.10;     % [new] cost of signal inflation (x inflation x true cost)
cfg.fixedGamerAction = 6;   % [base] delta_g = 0.25, markup 8%

% --- Learning (Q-learning, same hyperparameters as the base study)
cfg.alpha   = 0.10;
cfg.gamma   = 0.90;
cfg.epsilon = 0.15;
cfg.greedyEval = false;     % [new] epsilon = 0 during the evaluation window
cfg.qInitNonHonest = 0;     % [new] initial Q of actions 2-7 (0 neutral, <0 pessimistic)

% --- Discretionary regime (positive control) and price screen (countermeasure)
cfg.discretion  = 0.0;      % [new] prob. that a buyer steers the award to a cartel member (0 = algorithmic)
cfg.cartelSize  = 0;        % [new] number of cartel members the buyer can steer to
cfg.priceScreenTau = Inf;   % [new] bids above ref*(1+margin)*(1+tau) are disqualified (Inf = no screen)
cfg.refNoise    = 0.03;     % [new] noise (sd) of the allocator's reference-price estimate

% --- Tacit coordination among learners (RQ2)
cfg.ringSize = 0;           % [new] number of learners that form a ring
cfg.lambda   = 0.0;         % [new] reward sharing inside the ring (0 = independent)
cfg.shareQ   = false;       % [new] ring members share one Q-table
cfg.partnerAware = false;   % [new] ring members observe a role when a partner is in the tender
                            %      (0 none, 1 leader = lowest id, 2 follower): focal rotation device
end
