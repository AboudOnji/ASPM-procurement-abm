# ODD — Overview, Design concepts, Details (Grimm et al., 2020)

Model: endogenous-gaming procurement ABM, v0.1 (`matlab/+abmgov`, MATLAB R2026a).

## 1. Purpose and patterns
**Purpose.** Test whether the structural result of an algorithmic allocator (no cartel reconstruction) survives when suppliers *learn* to game the scored signal, coordinate, and exploit a performance record; and what ex-post verification achieves and displaces.
**Patterns used to judge the model.** (i) With a fixed share of exogenous gamers (0–20%) overrun rises ~11.7% → ~13.4%, HHI stays flat (reference values: published Table 5); (ii) HHI of the gaming-free market ≈ 250–280; (iii) honest market produces no signal gap.

## 2. Entities, state variables, scales
- **Suppliers (N = 100).** True quality q ~ U(0.7,1.0); efficiency e ~ U(0.7,1.0); policy ∈ {honest, learner, fixed gamer}; ring id; Q-table (18 state rows × 7 actions); last-outcome state; performance record h (init 0.8); blacklist horizon.
- **Allocator (no discretion).** Weights (wP, wQ, wH) = (0.6, 0.4, 0).
- **Verifier.** Probability ρ per winner.
- **Tenders.** Budget A ~ LogNormal(12, 1.5); true cost C = 0.9 A; 4–6 bidders. 5,000 tenders per run; metrics over the last 1,000; time series in blocks of 100.
- No spatial structure; network structure appears only through rings.

## 3. Process overview and scheduling
Per tender: (1) draw bidders from non-blacklisted suppliers; (2) each chooses an action (ε-greedy over Q for learners, fixed action for gamers, honest otherwise); (3) costs and bids; observed signal q̃ = min(1, q+g); (4) allocator picks argmax score; (5) verification, detection, sanction and blacklist; (6) rewards (margin units), ring reward sharing; (7) Q-learning updates for all participants; (8) performance record update of the winner (delivered quality if verified, else reported signal; control: always delivered quality).

## 4. Design concepts
- **Basic principle.** Goodhart/adversarial adaptation: a published score is a target.
- **Emergence.** Gaming prevalence, concentration (HHI), overpricing displacement, ring behavior.
- **Adaptation.** Q-learning (α 0.1, γ 0.9, ε 0.15), bounded rationality (coarse state, satisficing exploration, scripted action menu).
- **Objectives.** Maximize discounted reward in margin units; signaling cost κ·g·C paid even when losing.
- **Learning / prediction.** None beyond Q-values; no model of rivals.
- **Sensing.** Own last outcome, competition level; ring members optionally observe partner presence and role (leader/follower).
- **Interaction.** Competition through the allocator; ring reward sharing λ; optionally shared Q-table.
- **Stochasticity.** Seeded: budgets, bidders, quality/efficiency, cost noise, exploration, verification.
- **Collectives.** One ring of n learners (RQ2).
- **Observation.** HHI, overrun, inflating winners, signal gap, delivered quality, pure-overpricing value share, cover-bid share, ring share, block series, greedy-policy share.

## 5. Initialization
Seeded draws of q, e, policies; Q = 0 for honest action and `qInitNonHonest` (0 or −1) for the others; state = (lost, high competition); h = 0.8.

## 6. Input data
None external. Synthetic data replicate Table 2 of the published paper (no confidential records).

## 7. Submodels (equations)
- Cost: c = C [1 + σc (1 − e)] (1 + ε), ε ~ N(0, σε²); σc = 0.70, σε = 0.07 (calibrated).
- Bid: p = c (1 + 0.10 + m_a); signal q̃ = min(1, q + g_a). Action menu in the manuscript, Table 1.
- Score: S = −wP p/max p + wQ q̃ + wH h.
- Detection: 1 − exp(−g/θ), θ = 0.10; sanction 5 margins; blacklist 50 tenders.
- Record: h ← h + 0.10 (recorded − h).
- Q update: Q(s,a) ← Q(s,a) + α[r + γ max Q(s′,·) − Q(s,a)].
- Ring reward: (1−λ) r_i + λ mean(r_ring present).
- Discretionary regime (positive control): with prob. D the buyer steers the award to one of 5 cartel members (invited at the highest bid if absent).
- Reference-price screen: bids above ref (1+μ)(1+τ) are disqualified; ref = C (1 + 0.15 σc)(1 + η), η ~ N(0, 0.03²).

## Verification and validation
Unit tests `matlab/tests/TestAbmGov.m` (8; the price-screen test is weak: it checks finiteness and a loose price bound, not the exact disqualification rule); calibration in `docs/CALIBRATION.md`; global sensitivity E5 (LHS 1,200 points, PRCC).
