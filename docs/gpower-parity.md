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
- **G\*Power:** the G\*Power 3.1 manual, version of June 1, 2023,
  supplied by the maintainer on 17 October 2026. Cells cite it as
  "section N, p. P". The manual's section titles are not the Tests-menu
  names used here, so each end point names the section it was matched
  to. No G\*Power program or screen was used; nothing here is written
  from memory of G\*Power.
- **Not in the manual:** the manual says it "is not yet complete". It has
  no section for the z test of two independent proportions (E5), for a
  chi-square test of a contingency table (E6), or for repeated measures
  ANOVA (E8). Those cells say "to confirm (not in the 2023 manual;
  screenshot needed)". The maintainer offered screenshots of those
  tests. One E4 point (the default of the exact-distribution threshold)
  also needs a screenshot.

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
(asked and stored, but not yet applied: no recruitment target is shown); seed (**Has**,
for simulation). Sensitivity ("the smallest effect I could detect") is
**Has** for E7 and E8 only; for E1–E6 pwr supports it (any one argument
left `NULL` is solved for) and for E9–E14 the backends support it by a
search over effect sizes, so it is **Not exposed** there. Criterion (alpha
from power and N) is **Not exposed** for E1–E6 (pwr solves for
`sig.level`; Spower with `sig.level = NA`) and unknown for the rest.
Compromise is **Not exposed** for Spower (`beta_alpha`) and Superpower
(`ANOVA_compromise()`), and not offered by pwr. G\*Power offers five
types of analysis: a priori, compromise, criterion, post hoc and
sensitivity (manual, section 1.1, p. 2).

**Outputs common to every end point:**

| Output | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Power | Yes: "Power (1-β err prob)" in post hoc results (for example section 11.3.1, p. 27) | Power at N | **Has** | |
| Required N | Yes: "Total sample size"; the two-group t test also shows "Sample size group 1" and "Sample size group 2" (section 1.2.3, p. 4) | Total N (and per group in the headline for two-group tests) | **Has** | |
| Actual power at the rounded N | Yes: "Actual power" in a priori results. Non-integer sample sizes "are always rounded up" (section 1.2.3, p. 4) | Shown for exact results ("With 64 per group, power is 80.1%."); not for a simulated N | **Has** (exact results) | Judgement call G5, decided 17 October 2026 |
| Noncentrality parameter | Yes for t tests (δ) and F tests (λ) (sections 1.2.3, 11, 14, 16, 19, 20). The exact correlation example shows none (section 3.3, p. 9) | — | See each end point | Not returned by pwr's functions (their value is the arguments plus power, "method" and "note"); none for a simulation |
| Critical value | Yes: critical t (sections 16, 19, 20), critical F (sections 11, 14), lower and upper critical r (section 3.3, p. 9) | — | See each end point | As above |
| df | Yes: df for t tests; numerator and denominator df for F tests (sections 11, 14, 19, 20). None in the exact correlation example (section 3.3) | — | See each end point | pwr takes df as an input for the chi-square test only |

Computing a noncentrality parameter or critical value in powerkit itself
would be new statistical maths, which the project rules rule out while a
backend doesn't return it.

## E1: one-sample t-test

Matching G\*Power test: Means, "One group: difference from constant".
Manual section 20, "t test: Means - difference from constant (one sample
case)", pp. 50–51.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes: "Tail(s)", one or two (section 20.3, p. 50) | Two-sided, greater, less | **Has** | pwr and Spower `alternative` |
| Effect size | d = (μ − μ0)/σ (section 20.1, p. 50) | Cohen's d | **Has** | |
| Effect size from means and SD | Yes: the "Determine" drawer takes "Mean H0", "Mean H1" and "SD σ" (section 20.1, p. 50, Figure 27) | — | **Not exposed** | Spower `p_t.test()` takes `means` and `sds`; pwr takes d only |
| Non-zero null value | n/a: d is relative to μ0, which the drawer's "Mean H0" sets (section 20.1) | — | n/a | |
| Allocation | n/a | — | n/a | |
| Method | "This test has no options" (section 20.2, p. 50) | Formula (pwr) or simulation (Spower) | **Has** | |

Outputs: G\*Power shows noncentrality parameter δ, critical t, df, total
sample size and actual power (section 20.3, p. 50). powerkit:
noncentrality, critical value, df: **Not possible** (pwr `pwr.t.test()`
doesn't return them; Spower simulates).

## E2: independent-samples t-test

Matching G\*Power test: Means, "Two independent groups". Manual section
21, "t test: Means - difference between two independent means (two
groups)", p. 52 (no worked example there), and the two-group example in
section 1.2.3, p. 4.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes: "Tail(s)" (section 1.2.3, p. 4) | Two-sided, greater, less | **Has** | |
| Effect size | d = (μ1 − μ2)/σ (section 21.1, p. 52) | Cohen's d | **Has** | |
| Effect size from means and SDs | Yes: the drawer has two options. "n1 != n2" takes "Mean group 1", "Mean group 2" and "SD σ within each group"; "n1 = n2" takes the two means and "SD σ group 1", "SD σ group 2" (section 21.1, p. 52, Figure 28) | — | **Not exposed** | Spower `p_t.test(means, sds)` |
| Effect size as r (point-biserial) | Separate test: section 16, "t test: Correlation - point biserial model", pp. 40–41, shown in the main window as "Correlation: Point biserial model" (Figure 1, p. 3). It takes total sample size only (section 16.3, p. 40) | — | **Not exposed** | Spower `p_t.test(r = )` |
| Allocation ratio | Yes: "Allocation ratio N2/N1" (section 1.2.3, p. 4) | Size of group 2 / group 1 | **Has** | pwr `pwr.t2n.test()` |
| Unequal variances (Welch) | No: "The t-test assumes the variances in both populations to be equal", and "This test has no options" (sections 21.1 and 21.2, p. 52). With equal n the drawer can average two SDs as σ′ = √((σ1² + σ2²)/2) | Student or Welch | **Has** | Welch is simulation only (pwr has none) |
| Method | No options (section 21.2) | Formula or simulation | **Has** | |

Outputs: G\*Power shows noncentrality parameter δ, critical t, df,
sample size of each group, total sample size and actual power (section
1.2.3, p. 4). powerkit: noncentrality, critical value, df: **Not
possible**.

## E3: paired-samples t-test

Matching G\*Power test: Means, "Two dependent groups (matched pairs)".
Manual section 19, "t test: Means - difference between two dependent
means (matched pairs)", pp. 48–49.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes: "Tail(s)" (section 19.3, p. 48) | Yes | **Has** | |
| Effect size | d_z = \|μz\|/σz (section 19.1, p. 48) | d_z | **Has** | |
| d_z from means, SDs and their correlation | Yes: the drawer works "from differences" ("Mean of difference", "SD of difference") or "from group parameters" ("Mean group 1", "Mean group 2", "SD group 1", "SD group 2", "Correlation between groups") (section 19.1, p. 48, Figure 25) | — | unknown | Spower `p_t.test()`'s `r` is a point-biserial correlation, not the correlation between the two measures; no d_z calculator found in pwr or Spower help |
| Method | "This test has no options" (section 19.2, p. 48) | Formula or simulation | **Has** | |

Outputs: G\*Power shows noncentrality parameter δ, critical t, df and
power (section 19.3, p. 48). powerkit: noncentrality, critical value,
df: **Not possible**.

## E4: Pearson correlation

Matching G\*Power test: Correlation and regression, "Correlation:
bivariate normal model". Manual section 3, "Exact: Correlation -
Difference from constant (one sample case)", pp. 9–10. The manual
doesn't give this test's Tests-menu name; it describes the test of ρ = ρ0
for "two bivariate normally distributed random variables", which is
matched here to "Correlation: bivariate normal model".

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes: "Tail(s)" (section 3.3, p. 9) | Yes | **Has** | |
| Effect size | "Correlation ρ H1" (section 3.3, p. 9) | r | **Has** | |
| Null value ρ H0 | Yes: "Correlation ρ H0"; the worked example uses 0.60 (section 3.3, p. 9) | 0 only | **Not exposed** with Spower (`p_r(rho = )`); **Not possible** with pwr (`pwr.r.test()` has no null value) | With Spower 0.7, a non-zero `rho` gives a two-sided p-value whatever `alternative` says (`R/p_r.R`) |
| Method | The options dialog offers "Use exact distribution if N < x" or "Use large sample approximation (Fisher Z)" (section 3.2, p. 9). The worked example sets x = 10000 (section 3.3); the manual doesn't state the default: to confirm (screenshot needed) | Formula (pwr: Fisher's z) or simulation (Spower: Monte Carlo of the exact t test of ρ = 0) | **Has** (both) | Size of the difference: judgement call G6. Fisher's z kept: Departure 10 (`conventions.md`) |

Outputs: G\*Power shows lower and upper critical r (or z when the
approximation is used), total sample size and actual power (sections 3.2
and 3.3, p. 9). powerkit: critical r, df: **Not possible** with pwr (it
uses a critical value internally but doesn't return it).

## E5: two proportions

Matching G\*Power test: Proportions, "Two independent groups: z-test"
(also "Fisher's exact" and the unconditional exact tests, which powerkit
doesn't run). The manual has no section for the z test. Section 6,
"Exact: Proportions - inequality of two independent groups (Fisher's
exact-test)", p. 17, covers Fisher's exact test only.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes | Yes | **Has** | |
| Effect size | To confirm (not in the 2023 manual; screenshot needed): proportions p1, p2, and whether also h or an odds ratio | p1, p2 | **Has** | pwr gets Cohen's h from them (`ES.h()`), so this already works like "Determine" from proportions |
| Allocation ratio | Yes | Yes | **Has** | `pwr.2p2n.test(n1, n2)` |
| Continuity correction | To confirm (not in the 2023 manual; screenshot needed) | No correction (Departure 5) | **Not exposed** (Spower `correct = TRUE`) | |
| Exact test | Separate tests. Fisher's exact test: effect size by "directly specifying the two proportions π1 and π2", and "This test has no options" (sections 6.2 and 6.3, p. 17). The manual has no section on the unconditional exact tests | — | **Not exposed** (Spower `exact = TRUE`) | Judgement call 3.9 |
| Method | To confirm (not in the 2023 manual; screenshot needed): z test, pooled or unpooled | Formula (pwr: Cohen's h, the arcsine transformation) or simulation (Spower: `prop.test()`) | **Has** | The arcsine formula differs from a pooled z test by up to 0.018 in power and 3 per group in N (judgement call G6) |

Outputs: noncentrality, critical value: **Not possible**.

## E6: chi-square test of independence

Matching G\*Power test: none by that name in the maintainer's list; the
nearest are "Generic: chi²" and "Multigroup: goodness-of-fit". Which one
G\*Power uses for contingency tables is to confirm (not in the 2023
manual; screenshot needed).

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | To confirm (not in the 2023 manual; screenshot needed): w | Cell probabilities | **Has** | pwr gets w from them (`ES.w2()`), a "Determine" from probabilities |
| Effect size as w | To confirm (not in the 2023 manual; screenshot needed) | — | **Not exposed** | pwr `pwr.chisq.test(w = )`; Spower `p_chisq.test(w = )` |
| df | To confirm (not in the 2023 manual; screenshot needed) | (rows − 1) × (columns − 1), from the table | **Has** (derived) | |
| Marginal proportions | To confirm (not in the 2023 manual; screenshot needed); from the maintainer's list | Implied by the cell probabilities | **Has** (implied) | |
| Tails | n/a | n/a | n/a | |
| Continuity correction (2 x 2) | To confirm (not in the 2023 manual; screenshot needed) | None: the engine passes `correct = FALSE` to Spower (`engine/R/backend-spower.R`); pwr has none | **Not exposed** (Spower `correct = TRUE`) | |

Outputs: noncentrality, critical value: **Not possible** with pwr; df is
known from the inputs.

## E7: 2 x 2 between-participants ANOVA

Matching G\*Power test: Means, "ANOVA: main effects and interactions (two
or more IVs)". Manual section 11, "F test: Fixed effects ANOVA - special,
main effects and interactions", pp. 26–30.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | f = σm/σ (section 11.1, p. 26). The "Determine" drawer works "From Variances" ("Variance explained by special effect", "Error variance") or "Direct" ("Partial η²") (section 11.1, p. 27, Figure 12) | Four cell means and an SD (one or per cell), raw or in SD units | **Has** | Superpower works from means and SDs |
| Effect size as f or partial η² | Yes: f in the main window, partial η² through "Direct" (section 11.1, p. 27). G\*Power's partial η² is f²/(1 + f²) and "is not identical to the SPSS partial η²" (section 11.3.1, p. 27) | — | **Not exposed** | Superpower `mu_from_ES()` is one-way only; `power_twoway_between()` takes means (candidate) |
| Numerator df | Yes: "Numerator df", entered by the user (section 11.3.1, p. 27) | From the effect chosen (1 for each 2 x 2 effect) | n/a (always 1) | |
| Number of groups | Yes: "Number of groups", the "total number of groups in the design" (section 11.3.1, p. 27) | 4 (fixed) | **Has** (fixed) | |
| Effect tested | Main effect, interaction or planned comparison, set through f and the numerator df (sections 11.3.1 and 11.3.3, pp. 27–29) | A, B or A x B | **Has** | |
| Unequal group sizes | No group-size input: total sample size and number of groups only; denominator df = N − k and λ = f²N (section 11.5, p. 30). An a priori N need not be a multiple of the number of groups; the manual says to round up by hand (section 11.3.2, p. 29) | Equal | **Not exposed** (Superpower `ANOVA_power()` with an n vector, simulation only) | |
| Covariates | Separate test (ANCOVA); not in the 2023 manual | — | **Not exposed** (Superpower `ANCOVA_analytic()`) | |

Outputs: G\*Power shows noncentrality parameter λ, critical F,
denominator df, and power (post hoc) or total sample size and actual
power (a priori) (section 11.3, pp. 27–29). powerkit: Cohen's f and
partial η² are given for sensitivity results (**Has**). Noncentrality:
**Not exposed**: Superpower documents it as f² × error df and has a
`liberal_lambda` option; whether `ANOVA_exact()`'s `main_result` carries
it is to check. Critical value, df: **Not exposed** (in `aov_result`, an
`afex` object; to check).

## E8: 2 x 2 mixed ANOVA

Matching G\*Power tests: Means, "Repeated measures: within-between
interactions, ANOVA-approach" (and "between factors" for the group
effect). The manual has no section for repeated measures ANOVA; it only
lists "ANOVA: Repeated measures, between factors" as a related test
(section 10.4, p. 25).

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | To confirm (not in the 2023 manual; screenshot needed): f | Four cell means and an SD | **Has** | |
| Correlation among repeated measures | To confirm (not in the 2023 manual; screenshot needed) | One r | **Has** | |
| Number of measurements | To confirm (not in the 2023 manual; screenshot needed) | 2 (fixed) | **Has** (fixed) | |
| Nonsphericity correction ε | To confirm (not in the 2023 manual; screenshot needed) | — | n/a with two levels | Superpower `correction` (GG, HF) for more levels |
| MANOVA approach | Separate test; not in the 2023 manual | — | **Not exposed** (`manova_results`) | Roadmap A28, A30 |
| Per-cell SDs | To confirm (not in the 2023 manual; screenshot needed) | One SD | **Not exposed** (Superpower `sd` vector) | |

Outputs: as E7 on powerkit's side. G\*Power's outputs for this test: to
confirm (not in the 2023 manual; screenshot needed).

## E9: moderated regression (continuous × continuous)

Matching G\*Power test: none directly. "Linear multiple regression:
fixed model, R² increase" is the cross-check in
[`conventions.md`](conventions.md). Manual section 14, "F test: Multiple
Regression - special (increase of R²), fixed model", pp. 36–38.

| Input | G\*Power (R² increase) | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | f² = VS/VE (section 14.1, p. 36). The drawer works "From Variances" ("Variance explained by special effect", "Residual variance") or "Direct" ("Partial R²") (section 14.1, p. 36, Figure 18) | Correlations r_X_Y, r_W_Y, r_XW_Y, r_X_W | **Has** | InteractionPoweR's inputs |
| Number of predictors, tested and total | Yes: "Number of tested predictors" and "Total number of predictors" (section 14.3.1, p. 37) | 1 tested of 3 (fixed) | **Has** (fixed) | |
| Reliability of X, W, Y | n/a | Optional | **Has** | |
| Tails | n/a (F test; the alternative is directional, section 14, p. 36) | Two-sided | n/a | |
| Covariates | Through the predictor counts: a further set C counts toward "Total number of predictors" and lowers the residual variance (case 2, sections 14.1 and 14.3.2, pp. 36–37) | — | **Not exposed** (`power_interaction_r2_covs()`, analytic only) | |
| Binary or ordinal X, W | n/a | — | **Not exposed** (`k.x1`, `k.x2`; phase 3b) | |

Outputs: G\*Power shows noncentrality parameter λ, critical F, numerator
and denominator df, and power (section 14.3.1, p. 37). powerkit:
noncentrality, critical value: **Not possible** (simulation). Simple
slopes and interaction shape: **Not exposed** (`detailed_results =
TRUE`).

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

| End point | G\*Power drawer | powerkit | Backend support | Mark |
| --- | --- | --- | --- | --- |
| E1 | d from Mean H0, Mean H1 and SD σ (section 20.1, p. 50) | d only | Spower `p_t.test(means, sds)` | **Not exposed** |
| E2 | d from two means and one SD, or two means and two SDs with equal n (section 21.1, p. 52) | d only | Spower `p_t.test(means, sds)` | **Not exposed** |
| E3 | d_z from the mean and SD of the differences, or from two means, two SDs and their correlation (section 19.1, p. 48) | d_z only | None found for d_z | unknown |
| E4 | ρ H1 from the coefficient of determination r² (section 3.1, p. 9) | r | — | n/a |
| E5 | To confirm (not in the 2023 manual; screenshot needed) | From two proportions (h computed) | pwr `ES.h()` | **Has** |
| E6 | To confirm (not in the 2023 manual; screenshot needed) | From cell probabilities (w computed) | pwr `ES.w2()`; `ES.w1()` for goodness-of-fit | **Has** |
| E7 | f from the effect and error variances, or from partial η² (section 11.1, p. 27) | From means and SDs (Superpower's input) | Superpower; f or partial η² as input: **Not exposed** | **Has** (means) |
| E8 | To confirm (not in the 2023 manual; screenshot needed) | From means and SDs (Superpower's input) | Superpower; f or partial η² as input: **Not exposed** | **Has** (means) |
| E9 | f² from the effect and residual variances, or from partial R² (section 14.1, p. 36). Only the omnibus R² test's drawer works from predictor correlations (section 13.1, p. 33) | From correlations | — | **Has** (correlations) |
| E10–E14 | No matching test | Standardised paths | power4mome | **Has** (paths) |

Conversions between formats (for example d from t, or f from partial η²)
are planned as phase 5 effect-size helpers ([`coverage.md`](coverage.md))
and are judgement call B10.
