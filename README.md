# ASPM: Adaptive-Supplier Procurement Model

An agent-based model of public procurement under algorithmic allocation, in which suppliers **learn** (Q-learning) how to bid: honest bids, signal inflation, overpricing and cover bids. It supports ex-post verification, tacit coordination (rings), a performance record that can be poisoned, a discretionary regime (positive control) and a reference-price screen.

**Author:** Aboud Barsekh-Onji, Escuela Superior de Comercio y Administración, Instituto Politécnico Nacional (Mexico City). ORCID: [0009-0004-5440-8092](https://orcid.org/0009-0004-5440-8092).

This repository accompanies the article *Learning to Game the Algorithm: Endogenous Adversarial Adaptation in Algorithmic Public Procurement*. It builds on a previous study: Barsekh-Onji, A., & Cardoso Espinosa, E. O. (2026). The Algorithmic Bureaucrat: Dismantling Clientelist Networks in Public Procurement Through Agent-Based Modeling. *Urban Governance*, 6(3), 1-18. https://doi.org/10.1177/26643286261493873

## Contents

```
matlab/+abmgov/     model: defaultConfig, generateSyntheticData, SupplierPool, ProcurementMarket, computeMetrics
matlab/scripts/     one script per experiment, make_figures, generate_hypothetical_data
matlab/tests/       unit tests (TestAbmGov)
matlab/replicate_all.m   runs the tests, every experiment and the figures
results/            output of every experiment (CSV / MAT), including the confirmatory stage
figures/            figures of the paper (PDF)
docs/               ODD description, calibration notes, confirmatory protocol (with SHA-256)
data/               hypothetical tender datasets written by generate_hypothetical_data
```

## Requirements

MATLAB R2025b or later. Statistics and Machine Learning Toolbox (`ttest`, `lhsdesign`, `partialcorr`). Parallel Computing Toolbox is optional (`parfor` runs serially without it).

## Quick start

```matlab
addpath('matlab');
cfg = abmgov.defaultConfig();
cfg.learnFrac = 1;          % every supplier learns
cfg.greedyEval = true;      % no exploration in the evaluation window
cfg.rhoAudit = 0.5;         % ex-post verification of 50% of winners
mkt = abmgov.ProcurementMarket(cfg);
mkt.run();
res = mkt.metrics();        % HHI, cost overrun, share of inflating winners, ...
```

From a terminal: `matlab -batch "run('matlab/scripts/run_validation.m')"`.
Tests: `matlab -batch "runtests('matlab/tests/TestAbmGov.m')"`.

## Data

The statistical specification of the model derives from a **confidential** micro-dataset of a non-disclosed public agency, which cannot be shared. The model never reads that dataset. It uses **hypothetical** tenders that reproduce its statistical profile (log-normal budgets, about 43% direct awards, 4-6 bidders, a collusion flag). `matlab/scripts/generate_hypothetical_data.m` exports the hypothetical tenders that a run with a given seed uses:

```matlab
generate_hypothetical_data(2026, 5000)   % writes data/hypothetical_tenders_seed2026.csv
```

Bids are not data: they are produced by the model, because suppliers choose their own price and signal.

## Reproducing the paper

| Paper element | Script | Output |
|---|---|---|
| Consistency check (exogenous gaming) | `run_validation.m` | `results/validation_exogenous_gaming.csv` |
| Discovery | `run_discovery.m`, `run_blacklist_speed.m` | `results/E1_*`, `E1c_*`, `E6b_*` |
| Verification and displacement | `run_audit_diagnostics.m` | `results/E1b_E6_audit_diagnostics.csv` |
| Rings | `run_ring.m`, `run_ring_aware.m` | `results/E3_ring.csv`, `E3b_ring_aware.csv` |
| Performance record | `run_poisoning.m`, `run_poisoning_control.m` | `results/E4_*`, `E4b_*` |
| Global sensitivity | `run_global_sensitivity.m` | `results/E5_*` |
| Positive control, price screen, stationarity | `run_review_checks.m` | `results/R1_*` |
| **Confirmatory stage** | `run_confirmatory.m` | `results/CONF_runs.csv`, `CONF_hypotheses.csv` |
| Figures | `make_figures.m` | `figures/` |

The confirmatory protocol (`docs/CONFIRMATORY_PROTOCOL.md`) was sealed with the SHA-256 in `docs/CONFIRMATORY_PROTOCOL.sha256` before the confirmatory runs. Check it with `sha256sum -c CONFIRMATORY_PROTOCOL.sha256` inside `docs/`.

All runs are seeded. Exploratory experiments use seeds below 710,000; the confirmatory stage uses seeds `710000 + 1000*cell + run`.

## Citation

If you use this model, please cite the article above (details will be added after publication) and the previous study.

## License

MIT. See `LICENSE`.
