# Input and output parity with G\*Power (E1–E14)

*Last updated: 17 October 2026.*

For each end point powerkit runs, what a user can enter and what they get
back, set against the matching G\*Power test. It records gaps; nothing
here changes what powerkit does. The decisions it raises are judgement
calls G4–G6 in [`judgement-calls.md`](judgement-calls.md).

## Sources and limits

- **powerkit:** the input screens (`app/routing/forms.yaml`, and the
  fields every screen adds in `app/routing/R/forms.R`) and the result
  object (`run_spec()`'s help, `engine/R/run.R`), as on `main` after PR
  #34 (pwr's formula for E1–E6, Spower simulation as an option).
- **Backends:** the help pages of pwr 1.3-0, Spower 0.7, Superpower
  0.2.4.1, InteractionPoweR 0.2.4 and power4mome 0.2.1 (CRAN sources,
  opened 17 October 2026).
- **G\*Power:** no G\*Power screen was available here. The G\*Power
  column lists only (a) the inputs and outputs the maintainer named in
  the request (tails, effect size, alpha, power, N and allocation, ρ H0,
  df, number of groups, covariates, marginal proportions; power, required
  N, actual power, noncentrality parameter, critical value, df), and (b)
  what Spower's `gpower_examples` vignette says G\*Power asks for, marked
  *(Spower vignette)*. Every G\*Power cell needs confirming from a
  screenshot of that test's input panel; the maintainer offered these.

**Marks** for powerkit's side:

| Mark | Meaning |
| --- | --- |
| **Has** | powerkit has it |
| **Not exposed** | the backend supports it, powerkit doesn't expose it |
| **Not possible** | not possible with this backend (for example, no noncentrality parameter from a simulation) |
| **n/a** | doesn't apply to this test |

**Common to every end point** (not repeated below): alpha (**Has**, default
0.05 from the backend's own default); target power for "the sample size I
need" (**Has**); N for "the power I'd have" (**Has**, total N); attrition
(**Has**, turns the analysed N into a recruitment target); seed (**Has**,
for simulation). Sensitivity ("the smallest effect I could detect") is
**Has** for E7 and E8 only; for E1–E6 pwr supports it (any one argument
left `NULL` is solved for) and for E9–E14 the backends support it by a
search over effect sizes, so it is **Not exposed** there. Criterion (alpha
from power and N) is **Not exposed** for E1–E6 (pwr solves for
`sig.level`; Spower with `sig.level = NA`) and unknown for the rest.
Compromise is **Not exposed** for Spower (`beta_alpha`) and Superpower
(`ANOVA_compromise()`), and not offered by pwr.

**Outputs common to every end point:**

| Output | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Power | Yes | Power at N | **Has** | |
| Required N | Yes | Total N (and per group in the headline for two-group tests) | **Has** | |
| Actual power at the rounded N | Yes (maintainer's list) | Computed: for exact results the curve holds the power at every N searched, including the one reported; not shown on the result screen | **Not exposed** | Judgement call G5 |
| Noncentrality parameter | Yes (maintainer's list) | — | See each end point | Not returned by pwr's functions (their value is the arguments plus power, "method" and "note"); none for a simulation |
| Critical value | Yes (maintainer's list) | — | See each end point | As above |
| df | Yes (maintainer's list) | — | See each end point | pwr takes df as an input for the chi-square test only |

Computing a noncentrality parameter or critical value in powerkit itself
would be new statistical maths, which the project rules rule out while a
backend doesn't return it.

## E1: one-sample t-test

Matching G\*Power test: Means, "One group: difference from constant".

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes | Two-sided, greater, less | **Has** | pwr and Spower `alternative` |
| Effect size | d | Cohen's d | **Has** | |
| Effect size from means and SD | "Determine" (to confirm) | — | **Not exposed** | Spower `p_t.test()` takes `means` and `sds`; pwr takes d only |
| Non-zero null value | n/a (d is relative to the constant) | — | n/a | |
| Allocation | n/a | — | n/a | |
| Method | — | Formula (pwr) or simulation (Spower) | **Has** | |

Outputs: noncentrality, critical value, df: **Not possible** (pwr
`pwr.t.test()` doesn't return them; Spower simulates).

## E2: independent-samples t-test

Matching G\*Power test: Means, "Two independent groups".

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes | Two-sided, greater, less | **Has** | |
| Effect size | d | Cohen's d | **Has** | |
| Effect size from means and SDs | "Determine" (to confirm) | — | **Not exposed** | Spower `p_t.test(means, sds)` |
| Effect size as r (point-biserial) | Separate test (Correlation: point biserial model) | — | **Not exposed** | Spower `p_t.test(r = )` |
| Allocation ratio | N2/N1 | Size of group 2 / group 1 | **Has** | pwr `pwr.t2n.test()` |
| Unequal variances (Welch) | Not in the maintainer's list | Student or Welch | **Has** | Welch is simulation only (pwr has none) |
| Method | — | Formula or simulation | **Has** | |

Outputs: noncentrality, critical value, df: **Not possible**.

## E3: paired-samples t-test

Matching G\*Power test: Means, "Two dependent groups (matched pairs)".

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes | Yes | **Has** | |
| Effect size | d_z | d_z | **Has** | |
| d_z from means, SDs and their correlation | "Determine" (to confirm) | — | unknown | Spower `p_t.test()`'s `r` is a point-biserial correlation, not the correlation between the two measures; no d_z calculator found in pwr or Spower help |
| Method | — | Formula or simulation | **Has** | |

Outputs: noncentrality, critical value, df: **Not possible**.

## E4: Pearson correlation

Matching G\*Power test: Correlation and regression, "Correlation:
bivariate normal model".

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes | Yes | **Has** | |
| Effect size | ρ H1 | r | **Has** | |
| Null value ρ H0 | Yes (Spower vignette, Example 3.3: ρ0 = .60) | 0 only | **Not exposed** with Spower (`p_r(rho = )`); **Not possible** with pwr (`pwr.r.test()` has no null value) | With Spower 0.7, a non-zero `rho` gives a two-sided p-value whatever `alternative` says (`R/p_r.R`) |
| Method | Exact below N = 10,000 by default, Fisher's z above (maintainer) | Formula (pwr: Fisher's z) or simulation (Spower: Monte Carlo of the exact t test of ρ = 0) | **Has** (both) | Size of the difference: judgement call G6 |

Outputs: critical r, df: **Not possible** with pwr (it uses a critical
value internally but doesn't return it).

## E5: two proportions

Matching G\*Power test: Proportions, "Two independent groups: z-test"
(also "Fisher's exact" and the unconditional exact tests, which powerkit
doesn't run).

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes | Yes | **Has** | |
| Effect size | Proportions p1, p2 (to confirm whether also h or an odds ratio) | p1, p2 | **Has** | pwr gets Cohen's h from them (`ES.h()`), so this already works like "Determine" from proportions |
| Allocation ratio | Yes | Yes | **Has** | `pwr.2p2n.test(n1, n2)` |
| Continuity correction | To confirm | No correction (Departure 5) | **Not exposed** (Spower `correct = TRUE`) | |
| Exact test | Separate tests | — | **Not exposed** (Spower `exact = TRUE`) | Judgement call 3.9 |
| Method | z test (normal approximation; to confirm pooled or unpooled) | Formula (pwr: Cohen's h, the arcsine transformation) or simulation (Spower: `prop.test()`) | **Has** | The arcsine formula differs from a pooled z test by up to 0.018 in power and 3 per group in N (judgement call G6) |

Outputs: noncentrality, critical value: **Not possible**.

## E6: chi-square test of independence

Matching G\*Power test: none by that name in the maintainer's list; the
nearest are "Generic: chi²" and "Multigroup: goodness-of-fit" (to
confirm which G\*Power uses for contingency tables).

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | w (to confirm) | Cell probabilities | **Has** | pwr gets w from them (`ES.w2()`), a "Determine" from probabilities |
| Effect size as w | Yes (to confirm) | — | **Not exposed** | pwr `pwr.chisq.test(w = )`; Spower `p_chisq.test(w = )` |
| df | Yes | (rows − 1) × (columns − 1), from the table | **Has** (derived) | |
| Marginal proportions | Maintainer's list | Implied by the cell probabilities | **Has** (implied) | |
| Tails | n/a | n/a | n/a | |
| Continuity correction (2 x 2) | To confirm | None: the engine passes `correct = FALSE` to Spower (`engine/R/backend-spower.R`); pwr has none | **Not exposed** (Spower `correct = TRUE`) | |

Outputs: noncentrality, critical value: **Not possible** with pwr; df is
known from the inputs.

## E7: 2 x 2 between-participants ANOVA

Matching G\*Power test: Means, "ANOVA: main effects and interactions (two
or more IVs)".

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | f (to confirm; partial η² through "Determine") | Four cell means and an SD (one or per cell), raw or in SD units | **Has** | Superpower works from means and SDs |
| Effect size as f or partial η² | Yes (to confirm) | — | **Not exposed** | Superpower `mu_from_ES()` is one-way only; `power_twoway_between()` takes means (candidate) |
| Numerator df | Yes | From the effect chosen (1 for each 2 x 2 effect) | n/a (always 1) | |
| Number of groups | Yes | 4 (fixed) | **Has** (fixed) | |
| Effect tested | Main effect or interaction | A, B or A x B | **Has** | |
| Unequal group sizes | Total N only (to confirm) | Equal | **Not exposed** (Superpower `ANOVA_power()` with an n vector, simulation only) | |
| Covariates | Separate test (ANCOVA) | — | **Not exposed** (Superpower `ANCOVA_analytic()`) | |

Outputs: Cohen's f and partial η² are given for sensitivity results
(**Has**). Noncentrality: **Not exposed**: Superpower documents it as
f² × error df and has a `liberal_lambda` option; whether `ANOVA_exact()`'s
`main_result` carries it is to check. Critical value, df: **Not exposed**
(in `aov_result`, an `afex` object; to check).

## E8: 2 x 2 mixed ANOVA

Matching G\*Power tests: Means, "Repeated measures: within-between
interactions, ANOVA-approach" (and "between factors" for the group
effect).

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | f (to confirm) | Four cell means and an SD | **Has** | |
| Correlation among repeated measures | Yes (to confirm) | One r | **Has** | |
| Number of measurements | Yes (to confirm) | 2 (fixed) | **Has** (fixed) | |
| Nonsphericity correction ε | To confirm | — | n/a with two levels | Superpower `correction` (GG, HF) for more levels |
| MANOVA approach | Separate test | — | **Not exposed** (`manova_results`) | Roadmap A28, A30 |
| Per-cell SDs | To confirm | One SD | **Not exposed** (Superpower `sd` vector) | |

Outputs: as E7.

## E9: moderated regression (continuous × continuous)

Matching G\*Power test: none directly. "Linear multiple regression:
fixed model, R² increase" is the cross-check in
[`conventions.md`](conventions.md).

| Input | G\*Power (R² increase) | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | f² (to confirm) | Correlations r_X_Y, r_W_Y, r_XW_Y, r_X_W | **Has** | InteractionPoweR's inputs |
| Number of predictors, tested and total | Yes (to confirm) | 1 tested of 3 (fixed) | **Has** (fixed) | |
| Reliability of X, W, Y | n/a | Optional | **Has** | |
| Tails | n/a (F test) | Two-sided | n/a | |
| Covariates | Through the predictor counts | — | **Not exposed** (`power_interaction_r2_covs()`, analytic only) | |
| Binary or ordinal X, W | n/a | — | **Not exposed** (`k.x1`, `k.x2`; phase 3b) | |

Outputs: noncentrality, critical value: **Not possible** (simulation).
Simple slopes and interaction shape: **Not exposed**
(`detailed_results = TRUE`).

## E10–E14: mediation and moderated mediation

Matching G\*Power test: none.

| Input | powerkit | Mark | Note |
| --- | --- | --- | --- |
| Effect sizes | Standardised paths | **Has** | power4mome `pop_es` |
| Mediators | E11: up to 9 parallel; E12: up to 4 in sequence | **Has** | Validated with two |
| Residual correlations between mediators (E11) | Free | **Has** | Departure 7 |
| Moderator correlation with X (E13, E14) | c_X_W | **Has** | |
| Monte Carlo draws per CI (E10) | Yes | **Has** | |
| Test | Monte Carlo CI | **Has**; bootstrap **Not exposed** (`ci_type = "boot"`) | |
| Covariates | — | **Not exposed** (any lavaan model) | Roadmap B15 |
| Latent variables | — | **Not exposed** (`number_of_indicators`, `reliability`) | Roadmap B16 |

Outputs: power with its Monte Carlo interval (**Has**); noncentrality,
critical value, df: **Not possible** (simulation of a CI-based test).

## Effect-size calculators ("Determine")

| End point | powerkit | Backend support | Mark |
| --- | --- | --- | --- |
| E1–E3 | d or d_z only | Spower `p_t.test(means, sds)` for E1 and E2; none found for d_z | **Not exposed** (E1, E2) |
| E4 | r | — | n/a |
| E5 | From two proportions (h computed) | pwr `ES.h()` | **Has** |
| E6 | From cell probabilities (w computed) | pwr `ES.w2()`; `ES.w1()` for goodness-of-fit | **Has** |
| E7, E8 | From means and SDs (Superpower's input) | Superpower; f or partial η² as input: **Not exposed** | **Has** (means) |
| E9 | From correlations | — | **Has** (correlations) |
| E10–E14 | Standardised paths | power4mome | **Has** (paths) |

Conversions between formats (for example d from t, or f from partial η²)
are planned as phase 5 effect-size helpers ([`coverage.md`](coverage.md))
and are judgement call B10.
