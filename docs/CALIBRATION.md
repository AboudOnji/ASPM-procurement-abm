# Calibration of the model

**Goal.** The gaming-free configuration and the exogenous-gaming configuration should reproduce the pattern of the sensitivity analysis of the base study (2026): overrun of about 11.6% and HHI of about 250 without gaming, overrun rising to about 13.3% with 20% of assigned gamers, HHI flat.

**Why it is needed.** The base study takes bids from a fixed dataset in which the winning bid is always the lowest. Here, bids are generated inside the model, because suppliers choose their own price and signal. The cost parameters therefore need their own calibration.

## Grid (20 runs per cell, 1,000 tenders, composite score)

Target (no gaming): HHI 247 +/- 13, overrun 11.64%, delivered quality of winners 0.89.

| costSpread | costNoise | HHI | Overrun (%) | Quality |
|---|---|---|---|---|
| 0.30 | 0.02 | 331 | 12.91 | 0.937 |
| 0.30 | 0.06 | 270 | 8.97 | 0.919 |
| 0.50 | 0.07 | 266 | 9.82 | 0.912 |
| 0.60 | 0.07 | 271 | 10.79 | 0.911 |
| **0.70** | **0.07** | **276** | **11.74** | **0.909** |
| 0.70 | 0.08 | 267 | 10.64 | 0.906 |

Selected: `costSpread = 0.70`, `costNoise = 0.07`. Two moments were fitted (overrun and HHI at no gaming).

## Out-of-sample consistency check (30 runs per level)

| Share of assigned gamers | HHI | Overrun (%) | Gamers' value share (%) | Base study: overrun / share (%) |
|---|---|---|---|---|
| 0.00 | 282.8 | 11.69 | 0 | 11.64 / - |
| 0.05 | 287.1 | 11.96 | 5.6 | 12.08 / 5.5 |
| 0.10 | 266.5 | 12.31 | 13.0 | 12.54 / 11.6 |
| 0.15 | 258.8 | 13.01 | 19.4 | 12.89 / 15.8 |
| 0.20 | 285.4 | 13.37 | 26.5 | 13.34 / 22.0 |

Maximum HHI in any run: 677.

## Known deviations

1. Baseline HHI of about 280 versus 247, with larger dispersion between runs (sd about 50 versus 13).
2. Delivered quality of winners 0.91 versus 0.89.
3. Gamers' value share somewhat higher (26.5% versus 22.0% at 20% gamers).

None changes the qualitative result that is checked: HHI stays below 1,000 and overrun increases with the share of gamers.
