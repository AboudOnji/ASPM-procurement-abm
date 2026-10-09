# Confirmatory protocol (fixed before the confirmatory runs)

**Status.** Written 2026-10-09, before any confirmatory simulation was executed. The SHA-256 of this file is stored in `CONFIRMATORY_PROTOCOL.sha256` at the moment of sealing. Any later change to this file changes the hash.

**Why.** The exploratory stage (experiments E0 to E6, R1) was used to understand the behavior of the model and to formulate the hypotheses below. A hypothesis formulated after seeing data cannot be tested on the same data. The confirmatory stage tests the final hypotheses on independent random seeds, with decision rules and margins fixed here.

## Design
- Model: Adaptive-Supplier Procurement Model (ASPM), default configuration (`abmgov.defaultConfig`) unless a cell says otherwise.
- All suppliers learn (`learnFrac = 1`). Evaluation window: last 1,000 of 5,000 tenders, exploration switched off in the window (`greedyEval = true`).
- 50 independent runs per cell. Seeds `710000 + 1000 * cell + run`; none of them was used in the exploratory stage.
- Cells:

| Cell | Configuration |
|---|---|
| A | Algorithmic allocation, no verification (rho = 0) |
| B | A with discretionary steering D = 0.95, five cartel members |
| C | A with verification rho = 0.5 |
| D | C with reference-price screen tau = 0.05 |
| F | A with ring of 40 learners (lambda = 1, shared Q-table) |
| G | A with ring of 80 learners (lambda = 1, shared Q-table) |
| H | A with weights (0.6, 0.1, 0.3) and a performance record fed with the reported signal |
| I | H with the record fed with delivered quality (truthful record) |

## Hypotheses and decision rules
Each hypothesis is decided by an intersection of one-sided tests (the hypothesis is supported only if every component is supported). Welch's test for two cells, one-sample t-test against a threshold. P-values of the ten hypotheses are adjusted with the Holm procedure; a hypothesis is **supported** if its adjusted p-value is below 0.05, and **not supported** otherwise. Results are reported whatever the outcome.

Margins are set on substantive grounds, not on exploratory results: a reduction of overrun of 1.5 percentage points is about 10% of the baseline overrun; a reduction of the winner price premium of 1.0 percentage point is about one third of a premium of 3%.

| ID | Hypothesis | Tests (H1 = alternative) |
|---|---|---|
| H1a | When all suppliers learn and are not verified, most contracts go to inflated signals. | A: mean share of winners with inflated signal > 0.50 |
| H1b | Learned gaming does not reconstruct a cartel, and the metric can register one. | A: mean HHI < 1,000 and maximum HHI over runs < 1,000; B: mean HHI > 1,000 |
| H2a | Verification (rho = 0.5) cuts inflation substantially. | C - A: difference in inflation share < -0.30 |
| H2b | Verification does not reduce the winner price premium by a material amount. | C - A: difference in mean winner premium > -1.0 percentage point |
| H2c | Verification does not reduce cost overrun by a material amount. | C - A: difference in overrun > -1.5 percentage points |
| H3a | A ring of 40 learners does not change overrun materially and does not exceed its fair share. | F - A: overrun difference within +/-1.5 pp (two one-sided tests); F: ring value share < 45% |
| H3b | A ring of 80 learners raises overrun materially but does not reconcentrate the market. | G - A: overrun difference > +1.5 pp; G: mean HHI < 1,000 |
| H4a | A performance record fed with unverified signals worsens allocation relative to a truthful one. | H - I: inflation share difference > 0 and delivered-quality difference < 0 |
| H4b | Adding a weight on the (poisoned) record still reduces inflation relative to no record. | H - A: inflation share difference < 0 |
| H5 | A reference-price screen (tau = 0.05) reduces overrun, but by less than 1.5 pp. | D - C: overrun difference < 0 and > -1.5 pp |

## Outputs
`results/CONF_runs.csv` (all runs), `results/CONF_hypotheses.csv` (estimates, 95% intervals, raw and Holm p-values, decision).

## Not covered
Pre-specification of tender requirements, re-estimation of scoring weights by the allocator, and real data. These are limitations of the study, not hypotheses.
