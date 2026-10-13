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
  - **[powerkit]** this repository (`engine/R/`, `docs/decisions.md`).
- G*Power's manual, and the pwrss, InteractionPoweR, power4mome and Spower
  documentation, were not available when this file was written (no network
  access to CRAN or the web), so their entries are **to check**.

## Basic tests

### One-sample, independent and paired t-tests

| Tool | Test | Effect size | Settings that change the answer |
| --- | --- | --- | --- |
| G*Power | Independent: to check (believed Student's, equal variances; maintainer's decision D7 in `docs/design-finder.md` relies on this). Paired: dependent-means t-test [SP-vig]. | Independent: d, to check. Paired: d_z, the mean difference divided by the SD of the difference scores [SP-vig]. | Tails (one or two); allocation ratio N2/N1: to check |
| Superpower | Not covered as a t-test (no t-test function [SP-src]). A two-level `ANOVA_design` gives the equivalent F-test; for two within conditions with r = .5, d equals d_z [SP-vig]. | | |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered (interactions only): to check | | |
| power4mome | Not covered: to check | | |
| Spower | to check (the build guide says Spower has simulation versions of the G*Power tests) | to check | to check |
| **powerkit** | Spec template `independent_t`, method `student_t` or `welch_t` [powerkit schema]; the finder pre-selects Student's (decision D7). Engine: in progress (phase 3, via Spower). | `d` (independent, one-sample); `dz` (paired) [powerkit schema] | `alternative`: two-sided by default, or `greater` / `less`; `allocation_ratio` |

### Correlation, two proportions, chi-square test of independence

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | to check (correlation: exact bivariate normal test or the z approximation; proportions: several z and exact tests) | to check (r; proportions or h; w) | to check |
| Superpower | Not covered [SP-src] | | |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered: to check | | |
| power4mome | Not covered: to check | | |
| Spower | to check | to check | to check |
| **powerkit** | Spec templates `correlation` (Pearson, against 0), `two_proportions` (z test), `chi_square_independence` (Pearson chi-square) [powerkit schema]. Engine: in progress (phase 3, via Spower). | `r`; `p1`, `p2`; a table of cell probabilities | |

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
| InteractionPoweR | to check (analytic `power_interaction_r2()` and simulation `power_interaction()`; argument names in `engine/tests/testthat/helper-direct-calls.R` not yet run against the package) | Correlations among X, W, XW and Y: to check | Reliabilities of X, W, Y: to check |
| power4mome | to check (moderation is in scope per the build guide) | to check | to check |
| Spower | to check | to check | to check |
| **powerkit** | Spec template `two_way`, method `ols_t` (t test of the product term) [powerkit schema]. Engine: in progress (phase 3, via InteractionPoweR). | Correlations `r_X_Y`, `r_W_Y`, `r_XW_Y`, `r_X_W`, following InteractionPoweR's parametrisation [powerkit] | Reliabilities per variable |

## Mediation (PROCESS 4, 6) and moderated mediation (PROCESS 7, 14)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | Not covered: to check | | |
| Superpower | Not covered [SP-src] | | |
| pwrss | to check (the build guide names `power.z.mediation`, a z test of the indirect effect) | to check | to check |
| InteractionPoweR | Not covered: to check | | |
| power4mome | to check (Monte Carlo or bootstrap confidence intervals for indirect effects and the index of moderated mediation; `power4test()`) | to check (population values as standardised coefficients; "s"/"m"/"l" labels) | to check (number of Monte Carlo draws `R`; replications `nrep`) |
| Spower | to check (the build guide says Spower covers mediation) | to check | to check |
| **powerkit** | Spec: indirect effect along a named path (mediation) or the index of moderated mediation; `monte_carlo_ci` or `percentile_bootstrap` [powerkit schema]. Engine: in progress (phase 3, via power4mome). | Standardised paths keyed `From->To` [powerkit] | `options > ci_draws` |

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
- **powerkit:** runs it under the run's seed (restoring the caller's RNG
  state), so exact results are identical for a given seed.
- **Size:** about 1e-15 in power, so this has no practical effect.
- **Test:** `engine/tests/testthat/test-run-spec.R`, "exact results are
  reproducible bit for bit and leave the RNG alone".

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
