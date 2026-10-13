# Conventions: what the established tools do, and what powerkit does

powerkit follows the established tools' conventions by default (CLAUDE.md).
This file records, design by design, what each tool does by default (the test,
how the effect size is defined, and settings that change the answer) and what
powerkit does. **Every departure from an established tool is listed in
"Departures" below**, with the size of the difference and the test that shows
it.

## How to read this file

- Each entry says where it was checked. Anything not verified from
  documentation or source code says **to check**. Fill these in from the
  tools' manuals or source, citing the page or file.
- "Not covered" means the tool has no function for that design. This was
  verified for Superpower from its exported functions (Superpower 0.2.4.1).
- Sources used so far:
  - **[SP-src]** Superpower 0.2.4.1, installed source: function defaults,
    `Superpower_options()`, exported functions.
  - **[SP-vig]** Superpower vignette "More ANOVA designs"
    (`vignettes/more_anova_designs.Rmd`), which reproduces several G*Power
    analyses. G*Power entries marked [SP-vig] are what this vignette reports
    about G*Power, not checked in G*Power itself.
  - **[SP-intro]** Superpower vignette "Introduction to Superpower"
    (`vignettes/intro_to_superpower.Rmd`).
  - **[SP-book]** The Superpower book, chapter "Mixed
    ANOVA", section 5.1, footnote, as reported by the maintainer. Not read
    directly here (no web access).
  - **[Spower-src]** Spower 0.6.4, installed source and help pages
    (`p_t.test()`, `gen_t.test()`, `p_r()`, `p_prop.test()`,
    `p_chisq.test()`, `Spower()`), checked in build phase 3.
  - **[IP-src]** InteractionPoweR 0.2.4, installed source and help pages
    (`power_interaction()`, `power_interaction_r2()`,
    `generate_interaction()`, `test_interaction()`), phase 3.
  - **[p4m-src]** power4mome 0.2.1 (with manymome and lavaan 0.7.3),
    installed source and help pages (`power4test()`,
    `test_indirect_effect()`, `test_index_of_mome()`, `rejection_rates()`,
    `q_power_mediation()`, `Rs_bz_supported()`), phase 3.
  - **[powerkit]** this repository (`engine/R/`, `docs/decisions.md`).
- G*Power's manual and the pwrss documentation were not available when this
  file was written (no network access to CRAN or the web), so their entries
  are **to check**.

## Basic tests

### One-sample, independent and paired t-tests

| Tool | Test | Effect size | Settings that change the answer |
| --- | --- | --- | --- |
| G*Power | Independent: to check (believed Student's, equal variances; maintainer's decision D7 in `docs/design-finder.md` relies on this). Paired: dependent-means t-test [SP-vig]. | Independent: d, to check. Paired: d_z, the mean difference divided by the SD of the difference scores [SP-vig]. | Tails (one or two); allocation ratio N2/N1: to check |
| Superpower | Not covered as a t-test (no t-test function [SP-src]). A two-level `ANOVA_design` gives the equivalent F-test; for two within conditions with r = .5, d equals d_z [SP-vig]. | | |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered (interactions only): to check | | |
| power4mome | Not covered: to check | | |
| Spower | `p_t.test()`: `t.test()` on simulated normal data; Student's by default (`var.equal = TRUE`), Welch's with `var.equal = FALSE`; two-sided by default [Spower-src] | `d` is the standardised mean of the **first** group (two-sample) or first time point (paired); the other is 0, both with SD 1. For paired data the two time points are drawn **independently**, so the differences have SD sqrt(2) and Spower's `d` is sqrt(2) * d_z [Spower-src] | `two.tailed = FALSE` halves the two-sided p-value regardless of direction (Departure 4); `n` is group 1's size (pairs, for paired data), `n2_n1` the allocation ratio [Spower-src] |
| **powerkit** | Spower's `p_t.test()` for two-sided tests; for one-sided tests, Spower's `gen_t.test()` data with `t.test(alternative = ...)` (Departure 4). Student's or Welch's as the spec says; the finder pre-selects Student's (decision D7) [powerkit] | `d` = (mean of group 2 - mean of group 1) / SD; `dz` = mean of (second condition - first) / SD of the differences, stated when a paired spec is printed. Passed to Spower as -d and -sqrt(2) * d_z [powerkit] | `alternative`: two-sided by default, or `greater` / `less` ("greater" = the effect is positive); `allocation_ratio`; `goal.n` is the total |

### Correlation, two proportions, chi-square test of independence

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | to check (correlation: exact bivariate normal test or the z approximation; proportions: several z and exact tests) | to check (r; proportions or h; w) | to check |
| Superpower | Not covered [SP-src] | | |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered: to check | | |
| power4mome | Not covered: to check | | |
| Spower | `p_r()`: `cor.test()` (Pearson, exact t test against 0); `p_prop.test()`: `prop.test()`; `p_chisq.test()`: `chisq.test()`, which for a matrix of cell probabilities is the test of independence (its null pattern `P0` is then not used) [Spower-src] | `r`; `prop` (one per group); `P` (cell probabilities) [Spower-src] | Yates' continuity correction on by default (`correct = TRUE`) in `p_prop.test()` and `p_chisq.test()`; `n` is per group for `p_prop.test()` and the total for `p_chisq.test()` [Spower-src] |
| **powerkit** | Spower's `p_r()`, `p_prop.test()` and `p_chisq.test()` (two-sided); one-sided correlation and proportions tests use Spower's generators with `cor.test()` / `prop.test()` and `alternative` (Departure 4) [powerkit] | `r`; `p1`, `p2` ("greater" = p2 > p1); a table of cell probabilities | **No continuity correction** (`correct = FALSE`), as in G*Power (maintainer's decision 6; Departure 5) |

## Factorial ANOVA

### 2 x 2 between-participants

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | to check (ANOVA: fixed effects, special, main effects and interactions) | Cohen's f: to check | to check |
| Superpower | `ANOVA_exact()`: one data set with exactly the specified means and SDs (`mvrnorm(empirical = TRUE)`), analysed once [SP-intro]. `ANOVA_power()`: simulation, `nsims = 1000` by default [SP-src]. `power_twoway_between()`: analytic [SP-src]. | Input is cell means, SD(s) and n per cell; output reports partial eta squared and Cohen's f [SP-src] | `alpha_level` .05, `correction` "none", `liberal_lambda` FALSE, `emm` FALSE (`Superpower_options()` [SP-src]). `ANOVA_exact()` needs n per cell greater than the number of cells (n ≥ 5 for 2x2); for smaller n the vignette points to `ANOVA_exact2()` [SP-intro]. |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered (regression interactions; see below) | | |
| power4mome | Not covered: to check | | |
| Spower | to check | to check | to check |
| **powerkit** | `ANOVA_exact()` by default; `ANOVA_power()` with `options > method = "simulation"` [powerkit] | Cell means and SD(s) in the user's units, or standardised; sensitivity reports the smallest detectable effect in the user's units and as Superpower's Cohen's f [powerkit] | Superpower's defaults above. `ANOVA_exact()` is run under the run's seed (see Departures). `goal.n` is the total number analysed and must be a multiple of 4. |

### 2 x 2 mixed (one factor between, one within)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | "ANOVA: Repeated measures, within-between interaction" [SP-vig] | Cohen's f; whether the correlation among repeated measures is a separate field or folded into f depends on the setting below | **Effect size specification (Options button).** With "As in SPSS" the "Corr among rep measures" field disappears and the correlation is folded into f; in the vignette's one-factor within-participants example, f = 0.25 becomes f = 0.7024394 [SP-vig]. **Which setting produced the 91.25% within-between example is to check (Joel to verify in G*Power)**; the sources disagree (see Departure 2). The name of the default option, and whether it is the default, is also to check. |
| Superpower | `ANOVA_exact()`, `ANOVA_exact2()`, `ANOVA_power()` as above. The vignette's own within-between example calls `ANOVA_exact2()` [SP-vig]. | As above, plus a correlation `r` between repeated measures [SP-src] | As above |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered | | |
| power4mome | Not covered: to check | | |
| Spower | to check | to check | to check |
| **powerkit** | `ANOVA_exact()` by default; `ANOVA_power()` on request [powerkit] | Cell means, SD(s) and `r` | Reproduces the 91.25% and 98.98% that [SP-vig] reports from G*Power's within-between interaction; the G*Power setting behind those values is to check (see Departure 2). `goal.n` is the total number analysed and must be even. Equal group sizes only (see "Superpower and unequal group sizes" below). |

### Superpower and unequal group sizes (2 x 2 between and mixed)

Checked by running Superpower 0.2.4.1 under R 4.3.3 [SP-src].

- **`ANOVA_design()`** accepts unequal `n` for `"2b*2w"` (e.g.
  `n = c(20, 30)`) and for `"2b*2b"` (e.g. `n = c(10, 20, 30, 40)`), with no
  error or warning. It stores the vector (`n = n_vec`) but then sets
  `n <- max(n)` and builds the design's data at that size: for
  `n = c(20, 30)` in `"2b*2w"`, 30 per cell. So, silently, the design
  object's data describe a balanced design at the largest group size.
- **The power functions** then behave as follows:

  | Design | Function | What happens |
  | --- | --- | --- |
  | `"2b*2w"`, `n = c(20, 30)` | `ANOVA_exact()` | Stops: "the condition has length > 1". This is an R error from comparing a vector `n`, not a message about unequal groups. |
  | `"2b*2w"`, `n = c(20, 30)` | `ANOVA_exact2()` | Warns "Unequal n designs can only be passed to ANOVA_power", then stops: "non-conformable arguments". |
  | `"2b*2w"`, `n = c(20, 30)` | `ANOVA_power()` | Stops: "Unequal group sizes are not possible when the design contains within factors". |
  | `"2b*2b"`, `n = c(10, 20, 30, 40)` | `ANOVA_exact()` | Stops: "the condition has length > 1". |
  | `"2b*2b"`, `n = c(10, 20, 30, 40)` | `ANOVA_power()` | Runs. With means 0, 0.5, 0, 0 and SD 1, interaction power was 18.4% (2,000 simulations), against 33.85% for 40 per cell. So it does not simply use the largest size, but whether it uses the unequal sizes correctly has not been validated. |

  So in this version, a mixed design with unequal groups is not supported by
  any of Superpower's power functions. The balanced-at-the-largest-size
  behaviour is in `ANOVA_design()`, and would reach a result only through
  code that used the design object's data or `n` directly.
- **powerkit today:** this cannot reach Superpower. The `factorial_anova`
  spec has no group sizes: `goal.n` is split into 4 equal cells
  (`2x2_between`) or 2 equal groups (`2x2_mixed`), an `n` that doesn't split
  evenly is rejected, and `options > allocation_ratio` is rejected for any
  design other than the two-group tests [powerkit, `engine/R/spec-checks.R`].
  The engine passes Superpower a single per-cell `n` [powerkit,
  `engine/R/backend-superpower.R`].
- **Requirement for any future unequal-n support:** it must include a test
  proving that the unequal sizes are actually used (for example, that the
  result differs from the balanced design at `max(n)` and matches the
  independent reference). It must also be validated against an independent
  reference before it is offered (decision N3 in `docs/design-finder.md`).

## Regression interaction (two-way)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | to check (e.g. linear multiple regression, R² increase) | to check (f²) | to check |
| Superpower | Not covered [SP-src] | | |
| pwrss | to check | to check | to check |
| InteractionPoweR | Simulation, `power_interaction()`: OLS `lm(y ~ x1 + x2 + x1x2)`, t test of the product of the **observed** x1 and x2; analytic, `power_interaction_r2()` [IP-src] | Correlations `r.x1.y`, `r.x2.y`, `r.x1x2.y`, `r.x1.x2` among the true scores (x2 is the moderator) [IP-src] | `rel.x1`, `rel.x2`, `rel.y` (default 1); `k.x1`, `k.x2`, `k.y` make variables binary or ordinal; no seed argument (uses R's generator on one core) [IP-src] |
| power4mome | to check (moderation is in scope per the build guide) | to check | to check |
| Spower | to check | to check | to check |
| **powerkit** | `power_interaction()` (simulation). The analytic `power_interaction_r2()` only brackets the required n; it becomes the default where it is exact once a test shows the two agree (maintainer's decision 1) [powerkit] | Correlations `r_X_Y`, `r_W_Y`, `r_XW_Y`, `r_X_W`, InteractionPoweR's parametrisation (X = x1, W = x2) [powerkit] | Reliabilities per variable. Binary X or W: not available yet |

## Mediation (PROCESS 4, 6) and moderated mediation (PROCESS 7, 14)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | Not covered: to check | | |
| Superpower | Not covered [SP-src] | | |
| pwrss | to check (the build guide names `power.z.mediation`, a z test of the indirect effect) | to check | to check |
| InteractionPoweR | Not covered: to check | | |
| power4mome | `power4test()` with `test_indirect_effect()` or `test_index_of_mome()`: Monte Carlo (default) or nonparametric bootstrap CI, significant if the CI excludes 0; the model is fitted with lavaan (ML) by default [p4m-src] | Standardised coefficients (`pop_es`, "lhs ~ rhs: value", or "s"/"m"/"l" labels). Observed variables have variance 1, and a product of two standardised variables has variance 1 + r^2. Between two endogenous variables, `~~` sets their **residual covariance** [p4m-src, checked by simulation] | `R` (draws per CI): no default in `power4test()` (no CI without it); 1,000 in `q_power_mediation()`; 100 in `gen_mc()` / `gen_boot()`. Boos and Zhang's method switches on automatically for R in 39, 79, ..., 359 (Departure 8). A residual covariance not written in the model is fixed at 0 (lavaan) [p4m-src] |
| Spower | to check (the build guide says Spower covers mediation) | to check | to check |
| **powerkit** | power4mome's `power4test()` with its test functions, CI level 1 - alpha, CI rule (`test_method = "ci"`); lavaan ML fit (Departure 6) [powerkit] | Standardised paths keyed `From->To`; residual **correlations** for parallel mediators (converted to power4mome's covariance) [powerkit] | `options > ci_draws`, default power4mome's 1,000 (`q_power_mediation()`); parallel mediators' residuals always free to correlate, as in PROCESS (Departure 7); Boos and Zhang off (Departure 8). Binary X or W and measurement error: not available yet |

## Departures

Each departure must also be shown on the results screen, stated in the
methods paragraph, and covered by a test showing the size of the difference
(CLAUDE.md).

### 1. Required N for 2 x 2 interactions: exact F test, not Sommet et al.'s z approximation

- **Established convention:** Sommet, Weissman, Cheutin & Elliot (2023)
  compute N = 4 (z_alpha + z_beta)² / d², rounded up, with z rounded to two
  decimals and d = (d_simple1 − d_simple2) / 2 (their Equation 5; Equation 8
  gives N = 1,024 for d = 0.175).
- **powerkit:** the smallest N at which the exact F test reaches the target
  power (`ANOVA_exact()`).
- **Size:** 260 vs 256 for the reversed interaction (d = 0.35); 1,028 vs
  1,024 for the fully attenuated interaction (d = 0.175); both at α = .05 and
  power .80. powerkit's N is 4 participants (one per cell) larger.
- **Test:** `engine/tests/testthat/test-validation-anova-2x2-between.R`,
  "2x2 crossover interaction" and "2x2 attenuated interaction". Each checks
  that Sommet et al.'s formula reproduces their published N from the spec's
  effect, and that powerkit's exact N is 260 / 1,028 and at least the
  published N.
- **Shown to users / in the methods paragraph:** to do (build phases 4–5).

### 2. Mixed designs: `ANOVA_exact()`, not `ANOVA_exact2()`

- **Established convention:** Superpower offers both. Its vignette uses
  `ANOVA_exact2()` for the within-between example and describes it as giving
  "a more accurate estimate of power" over a wider range of sample sizes
  [SP-intro, SP-vig].
- **powerkit:** uses `ANOVA_exact()`, which reproduces the values [SP-vig]
  reports from G*Power's "ANOVA: Repeated measures, within-between
  interaction" (table below), and matches simulation.
- **Which G*Power setting gave those values: to check (Joel to verify in
  G*Power).** The two Superpower sources disagree, and neither is claimed
  here until it is verified:
  - [SP-vig] does not name the setting for the within-between example; its
    settings are shown only in a screenshot (`screenshots/gpower_5.png`,
    not in the installed package). For the preceding one-factor
    within-participants example, it presents "As in SPSS" as an extra step
    taken after the settings it used ("We click the 'Options' button, and
    check the radio button next to 'As in SPSS'"), which suggests those
    settings were not "As in SPSS". An earlier version of this file
    extended that to the within-between example; that was an inference, not
    something the vignette states.
  - [SP-book] says G*Power was set to "As in SPSS" for the 91.25% example.
- **Size** (2b*2w, means −0.25, 0.25, 0.25, −0.25, SD 1, n = 23 per group,
  α = .05; run with Superpower 0.2.4.1):

  | r | `ANOVA_exact()` | `ANOVA_exact2()` | G*Power, as reported in [SP-vig] |
  | --- | --- | --- | --- |
  | 0.5 | 91.2498% | 90.4745% | 91.25% |
  | 0.7 | 98.9847% | 98.8079% | 98.98% |

  Why `ANOVA_exact2()` differs is **to check** (from Superpower's source or
  its authors).
- **Test:** the mixed published-value tests in
  `engine/tests/testthat/test-validation-anova-2x2-mixed.R` check
  `ANOVA_exact()` against 0.9125 (G*Power) and 0.9898467 (Superpower book
  Table 5.4). **There is no test yet that shows the `ANOVA_exact2()` values
  above**, which CLAUDE.md now requires; it belongs in `engine/tests/` (to
  do).
- **Shown to users / in the methods paragraph:** to do (build phases 4–5).

### 3. `ANOVA_exact()` is run under the run's seed

- **Established convention:** Superpower's `ANOVA_exact()` builds its data
  set with the random-number generator, so repeated calls differ at about the
  15th decimal place [powerkit, `docs/decisions.md`].
- **powerkit:** builds the design first (`ANOVA_design()` also draws random
  numbers), then runs `ANOVA_exact()` under the run's seed and restores the
  caller's RNG state. So exact results are identical for a given seed and
  equal a direct call (design, then `set.seed()`, then `ANOVA_exact()`).
  Before phase 3 the design was built lazily inside the seeded block, so
  results differed from a direct call at about the 15th decimal place on
  Windows.
- **Size:** about 1e-15 in power, so this has no practical effect.
- **Test:** `engine/tests/testthat/test-run-spec.R`, "exact results are
  reproducible bit for bit and leave the RNG alone".

### 4. One-sided basic tests: a directional test, not Spower's halved p-value

- **Established convention:** Spower's `two.tailed = FALSE` returns half
  the two-sided p-value whatever the direction of the observed effect
  (`p_t.test()`, `p_r()`, `p_prop.test()`) [Spower-src].
- **powerkit:** for one-sided tests, data from Spower's generator analysed
  with `t.test()`, `cor.test()` or `prop.test()` and `alternative`, so only
  effects in the tested direction count. Two-sided tests use Spower's own
  functions unchanged.
- **Size:** with no effect, Spower's one-sided t-test rejects about twice
  alpha: 0.1022 against powerkit's 0.0482 (5,000 seeded replications,
  alpha = .05), and 0.1009 against 0.0495 in
  `docs/upstream/spower-one-sided-tests.R` (10,000). With a real effect in
  the tested direction the two agree (0.7931 and 0.7931 for d = 0.5, n = 50
  per group).
- **Test:** `engine/tests/testthat/test-backend-spower.R`, "departure:
  one-sided tests check the direction, unlike Spower's two.tailed = FALSE".
- **Shown to users / in the methods paragraph:** to do (build phases 4-5).

### 5. Two proportions and chi-square: no continuity correction (Spower applies one by default)

- **Established convention:** Spower's `p_prop.test()` and `p_chisq.test()`
  apply Yates' continuity correction by default (`correct = TRUE`)
  [Spower-src]. G*Power's z test and Pearson chi-square do not
  (maintainer's decision 6; G*Power's documentation itself is still to check
  here).
- **powerkit:** no correction, and no option for one (maintainer's decision
  6), as in G*Power.
- **Size:** two proportions, p1 = .50, p2 = .65, 170 per group,
  alpha = .05, the same 5,000 seeded data sets: power 0.8178 without the
  correction and 0.7894 with it (.028 lower). For the chi-square test it
  only matters for 2 x 2 tables.
- **Test:** `test-backend-spower.R`, "departure: no continuity correction,
  unlike Spower's default (correct = TRUE)", which also checks that
  powerkit's run equals the uncorrected value.
- **Shown to users / in the methods paragraph:** to do (build phases 4-5).

### 6. Mediation fits: lavaan maximum likelihood, not PROCESS's OLS

- **Established convention:** PROCESS fits each equation by OLS.
- **powerkit:** fits the path model with lavaan (ML), power4mome's default,
  because power4mome's Monte Carlo confidence intervals need a lavaan fit
  (accepted by the maintainer, decision 12).
- **Size:** identical estimates. ML standard errors are the OLS ones times
  sqrt((n - k) / n), with k the number of coefficients in the equation
  including the intercept. At N = 50 they are 2.0% smaller for a (k = 2)
  and 3.0% smaller for b and c' (k = 3); at N = 200, 0.5% and 0.75%.
- **Test:** `test-backend-power4mome.R`, "departure: lavaan ML standard
  errors vs PROCESS's OLS, at N = 50" (checks the ratio to 1e-6).
- **Shown to users / in the methods paragraph:** to do (build phases 4-5).

### 7. Parallel mediators: residuals free to correlate (lavaan fixes them at 0)

- **Established convention:** PROCESS fits separate OLS regressions, which
  place no constraint on the mediators' residual covariance. lavaan, and so
  power4mome given a model without `M1 ~~ M2`, fixes it at 0 [p4m-src].
- **powerkit:** follows PROCESS (maintainer's decision 8): the fitted model
  always frees the residual covariance between parallel mediators, whatever
  its population value. This departs from lavaan's and power4mome's default
  model, not from PROCESS.
- **Size:** identical estimates. With a residual correlation of 0.4 and
  n = 200, fixing the covariance at 0 understates the standard errors of
  the M1->Y and M2->Y paths by about 10% (free / fixed = 1.111 for both,
  seeded data), so it would overstate power.
- **Test:** `test-backend-power4mome.R`, "departure: parallel mediators'
  residuals free to correlate, as in PROCESS".
- **Shown to users / in the methods paragraph:** to do (build phases 4-5).

### 8. Boos and Zhang's (2000) method: off (power4mome switches it on for some R)

- **Established convention:** power4mome switches Boos and Zhang's method
  on automatically when the number of draws R is one of 39, 79, ..., 359.
  Each replication's test then uses a p-value rule instead of the
  confidence interval, and power4mome's own searches (e.g.
  `x_from_power()`) extrapolate rejection rates [p4m-src].
- **powerkit:** off, for validation and, until the user-facing choice is
  made, for every run (maintainer's decision 10). powerkit asks for the CI
  rule explicitly (`test_method = "ci"`), because power4mome's documented
  switch (`options(power4mome.bz = FALSE)`) does not reach its test
  functions in version 0.2.1 (`docs/decisions.md`).
- **Size:** none in powerkit's runs. At R = 39 both rules gave identical
  rejection rates on 100 seeded replications (at these R the p-value rule
  and the CI agree), and `power4test()` does not extrapolate. At any other
  R, including the default 1,000, the method is never used.
- **Test:** `test-backend-power4mome.R`, "departure: Boos-Zhang off makes
  no difference to power4test()'s rejection rate".
- **Shown to users / in the methods paragraph:** to do (build phases 4-5).

## Not departures, but worth stating

- **Default method for 2 x 2 designs:** exact (`ANOVA_exact()`), with
  simulation on request. This matches G*Power and the published values
  [powerkit, `docs/decisions.md`].
- **Sample size convention:** `goal.n` is the total number of participants
  analysed (Superpower's `n` is per cell or group; powerkit converts)
  [powerkit].
- **ANCOVA:** Superpower has `ANCOVA_analytic()` and `power_oneway_ancova()`
  [SP-src]. These may serve the ANCOVA route for pre–post designs (decision
  D2 in `docs/design-finder.md`); whether they match G*Power is to check.
- **Unequal group sizes (2 x 2 between and mixed).** powerkit's 2 x 2
  templates require equal group sizes; unequal groups are "coming later"
  (decisions D5, N1 and N3 in `docs/design-finder.md`). See "Superpower and
  unequal group sizes" above.
- **Paired designs: d_z is the second condition minus the first**, in the
  order of X's levels (maintainer's decision 5). G*Power's d_z is the mean
  difference over the SD of the differences [SP-vig]; the direction only
  matters for one-sided tests. It is stated when a paired spec is printed,
  and must be on the app's confirmation and results screens.
- **Residual correlations, not covariances.** The spec gives parallel
  mediators' residual correlations; power4mome's `M1 ~~ M2` value is a
  residual covariance, so powerkit converts, multiplying by
  sqrt((1 - R^2 of M1)(1 - R^2 of M2)). Same population, different
  parametrisation; the check run recovers the correlation on every run.
- **Product terms.** powerkit's validator and power4mome agree: a product
  of two standardised variables with correlation r has variance 1 + r^2,
  and its path coefficient applies to the raw product [p4m-src, checked by
  simulation].
- **Sample size search for simulated designs:** powerkit's own
  `search_n()` (a probit fit to simulated power, with a 95% interval for
  n), not Spower's or power4mome's own searches, so every design reports n
  the same way [powerkit].
- **Default method for every design except the 2 x 2 ANOVAs:** simulation,
  with `options > nrep` replications (default 1,000) [powerkit].
