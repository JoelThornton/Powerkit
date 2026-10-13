# Decisions log

Short records of decisions that are not obvious from the code. Newest last.

## 2026-10-12 · Phases 0–1 (set-up, specification and tests)

**Repository.** The build guide now lives at `docs/build-guide.md` (the path
CLAUDE.md uses). The engine is an R package in `engine/`; `app/` and
`assistant/` are placeholders until phases 5 and 7.

**Backend adapter files must be flat.** R packages ignore subdirectories of
`R/`, so the guide's `engine/R/backends/spower.R` layout will not load. Use
`engine/R/backend-spower.R`, `backend-power4mome.R`, etc. in phases 2–3.

**renv.** renv is initialised at the repository root (where the guide puts
`renv.lock`). renv does not read `engine/DESCRIPTION`, so `_dependencies.R`
lists the packages explicitly; keep it in step with `engine/DESCRIPTION`.
The lockfile was created in an environment without CRAN access, so it pins
R 4.3.3 and older package versions, and does not yet contain Spower,
power4mome or InteractionPoweR. It needs re-snapshotting on a machine with
CRAN access (see the phase 1 summary). CI installs packages from
`engine/DESCRIPTION`, not from the lockfile, so CI tests against current CRAN
releases; the lockfile pins versions for local work and, later, deployment.

**Backends are Suggests for now.** Nothing in the engine calls them yet, so
listing them in Imports would give an R CMD check note. Move each to Imports
when its adapter is written.

**Spec format (version 0.1).**

- JSON Schema draft-07 (supported by every jsonvalidate engine), with
  `if`/`then` branches on `design` and `template` rather than `oneOf`, which
  gives far clearer error messages.
- `goal.n` is the **total number of participants analysed**. Attrition only
  turns this into a recruitment target.
- Basic tests use one template each: `one_sample_t`, `independent_t`,
  `paired_t`, `correlation`, `two_proportions`, `chi_square_independence`.
- 2x2 designs give cell means as a 2x2 array (rows = levels of A) and an SD
  (one number or a 2x2 array). In the mixed design A is between, B within.
  Cells must be equal (as Superpower requires), so n must divide evenly.
- Regression interactions use InteractionPoweR's parametrisation
  (correlations `r_X_Y`, `r_W_Y`, `r_XW_Y`, `r_X_W`), not standardised paths,
  so the spec maps directly onto the backend.
- Mediation and moderated mediation use standardised paths keyed `From->To`.
  Product terms are named by joining the variables (`XW->M`, `MW->Y`). Every
  path in the template must be given (0 for none), so the confirmation
  screen never shows an assumed value.
- PROCESS model 4 covers simple (`M`) and parallel (`M1`, `M2`, ...)
  mediation; model 6 covers serial mediation (`M1` ... `M4`).
- Mediation names the indirect path under test in `target_test.path`.
  Moderated mediation tests the index of moderated mediation only (MVP).
- `options.ci_draws` (Monte Carlo draws per CI) and
  `options.allocation_ratio` (two-group designs) were added to the options
  in the guide's example.
- `effect_justification.type` is one of the four kinds in guide section 7;
  `prior_study` requires an `adjustment`; `pilot_study` gives a warning.

**Validator.** `validate_spec()` checks the schema first, then (only if
the structure is sound) the population. Population checks treat exogenous
variables as standardised and jointly normal, so a product of two variables
with correlation r has variance 1 + r² and is uncorrelated with the rest.
This is an assumption to confirm against power4mome's own conventions in
phase 3. If power4mome exposes its own check, prefer it.

**Validation tests.**

- All validation tests are skipped unless `POWERKIT_FULL_VALIDATION=true`,
  so per-push CI runs only the unit tests; nightly CI runs everything.
- `TODO_PUBLISHED_VALUE` is a classed `NA`; a test that still contains one
  is skipped with a message pointing to its source comment.
- The engine contract the tests assume (`run_spec()`, `result$curve`,
  `result$n_required`) and all backend API calls live in `helper-*.R`
  files, so later phases can adjust them without touching the
  maintainer-owned `test-validation-*` files.

## 2026-10-12 · Published values for the 2x2 validation tests

The maintainer transcribed and checked the published values for the six
2x2 published-example tests (Superpower vignette "More ANOVA designs";
Lakens & Caldwell (2021), "Power for Interactions", Fig. 5 left panel;
Superpower book, ch. "Mixed ANOVA", section 5.1, Table 5.4; Sommet et al.
(2023), Table 2).

- Lakens & Caldwell (2021) has no 2x2 mixed example, so the second mixed
  test uses the Superpower book instead.
- **The Giner-Sorolla knock-out test was deleted.** The blog post gives only
  a sample-size multiplier, with no cell means or exact N, so there is
  nothing to test against. Knock-out (fully attenuated) interactions are
  covered by the Sommet et al. fully attenuated test.
- Sommet et al.'s required Ns come from a z-approximation and sit about 4
  below the exact F-test N (256 vs 260; 1024 vs 1028). If those tests fail
  narrowly, report it; do not change the values.
- Guide section 6 now cites Sommet et al. (2023) Table 2 for interaction
  shapes, and Donnelly, Jorgensen et al. (2023), Behavior Research Methods,
  55(7), 3892-3909 (doi:10.3758/s13428-022-01996-0) in place of the
  unidentified "simsem tutorial" for moderated mediation. The modmed
  validation tests' source comments still say "simsem tutorial"; they will
  be updated when those values are transcribed.

## 2026-10-12 · Phase 2: answers to open questions

1. **`goal.n` is the total number of participants analysed** (confirmed).
2. **Validation tolerance is a 99.9% Monte Carlo interval** (`level = 0.999`
   by default in the test helpers), so that a correct engine rarely fails a
   test by chance across the whole suite. To keep a real error of .03 in power
   failing, nightly validation runs **10,000 replications**. At power .5, the
   99.9% half-width is about .016 against a published or exact value (a .03
   error fails ~99.7% of the time) and about .023 between two simulations in
   the direct-call tests (~83%). 5,000 replications would give .033 there,
   wider than .03. Guide section 6 is updated.
3. **Result object.** `run_spec()` always returns one object with
   `goal_type`; `curve` (`n`, `power`, `mcse`; one row for a fixed-n goal);
   `n_required` (`n`, `lower`, `upper`; `NA` unless the goal is
   `sample_size`); `sensitivity` (`NA` unless the goal is `sensitivity`);
   `check_run`; `provenance`. Guide section 5 is updated.

## 2026-10-12 · Phase 2: 2x2 designs via Superpower

- **Files.** `R/route.R` (routing, parallel helpers), `R/backend-superpower.R`,
  `R/search_n.R`, `R/run.R` (`run_spec()`). Superpower moved to Imports.
- **Power comes from simulation**, with `Superpower::ANOVA_power()`. The
  result is a Monte Carlo estimate with an MCSE, as for every other backend.
- **`ANOVA_exact()` is used only for speed and checking**, never as the
  reported power: (a) to bracket the required n before simulating, and
  (b) for the check run. `ANOVA_exact()` needs more than 4 participants per
  cell, so bracketing starts there; the simulated grid can still go lower.
- **`ANOVA_exact2()` is not used.** For mixed designs it gives 90.47% power
  where G*Power, `ANOVA_exact()` and simulation give 91.25% (vignette "More
  ANOVA designs", within-between section); `ANOVA_exact()` agrees with
  simulation.
- **Parallel replications.** `nrep` is split into one seeded `ANOVA_power()`
  call per core (`options(powerkit.cores)` or `POWERKIT_CORES`; default 1;
  Unix only, via `parallel::mclapply`). Chunk seeds are `seed`, `seed + 1`,
  ...; with one core a run is exactly `ANOVA_power(nsims = nrep, seed = seed)`.
  Nightly CI uses 4 cores. Superpower takes about 20 s per 1,000
  replications on one core.
- **Sample-size search (`search_n()`).** Bracket n with `ANOVA_exact()`;
  simulate 7 valid sizes spaced about 5% apart around it (seed for the i-th
  size: `seed + 10007 * (i - 1)`); smooth with a probit regression of the
  rejection counts on sqrt(n) (power is close to `pnorm(a + b * sqrt(n))` for
  roughly normal test statistics), fitted to points within 20% of the
  estimate. `n` is the smallest valid n whose fitted power reaches the
  target; the **95%** interval runs from the smallest n whose upper limit
  reaches it to the smallest n whose lower limit does. The grid widens
  geometrically if the interval runs off either end. Superpower has no
  simulation-based sample-size search of its own, so this is powerkit code.
- **Check run.** Rather than simulating 100,000 cases (guide section 5),
  the check reads back the data set `ANOVA_exact()` builds with exactly the
  translated population (`empirical = TRUE`), matching cells by Superpower's
  factor labels. Recovered cell means, SDs and (mixed) repeated-measures
  correlations must equal the spec's to 1e-6, so any mistranslation (e.g.
  cells in the wrong order) shows up with no Monte Carlo noise. A failed
  check stops the run with a plain-English error.
- **Defaults.** `nrep` 1,000; a random seed is drawn and recorded if the
  spec has none.
- **Not yet done.** Sensitivity goals give a plain-English "not available
  yet" error (which parameter to scale is still undecided). Attrition is not
  yet turned into a recruitment target in the result. Results are not cached
  by spec hash yet.

## 2026-10-12 · Phase 2 follow-up: maintainer decisions

1. ~~z-approximation allowance~~ (replaced; see "Rounding and the Sommet
   tests" below).
2. **Sensitivity goals** keep the shape of the specified pattern and scale
   its size. For 2x2 designs each cell mean's deviation from the grand mean
   is multiplied by a factor found by root-finding on exact power (scale 1 =
   the pattern as specified; scale 0 = all means equal, power = alpha). The
   result gives the scaled cell means, the target effect in the user's units
   (a marginal mean difference for a main effect; the difference of simple
   effects for the interaction) and Superpower's Cohen's f for it.
   Sensitivity uses the exact method; asking for simulation gives a
   plain-English error. A spec whose target effect is zero is rejected for
   sensitivity goals, as for sample-size goals.
3. The stale Giner-Sorolla mention in the 2x2 between test file header is
   removed.
4. **Unbuilt designs skip, not fail.** `route_spec()` signals
   `powerkit_not_available` for designs with no backend yet, and the
   validation helper `validation_spec()` turns that into a skip with the
   reason. A red nightly run now means a real problem.
5. **Exact by default for 2x2 designs.** `ANOVA_exact()` is exact for the
   specified population (normal errors, equal cells), agrees with G*Power,
   and reproduced every published 2x2 value to its last decimal; simulation
   only adds Monte Carlo error around the same number, and is much slower
   (about 20 s per 1,000 replications). So power and n_required for 2x2
   designs are computed with `ANOVA_exact()` unless the spec asks for
   simulation with the new optional field `options > method`
   (`"exact"` or `"simulation"`; `"exact"` is refused for other designs).
   Exact results have MCSE 0, and an exact required n has
   `lower = upper = n`, found by bisection over valid n. The simulation path
   (`ANOVA_power()`, `search_n()`) is unchanged and is still checked by the
   direct-call validation tests, which now request it. `ANOVA_exact()`
   needs at least 5 participants per cell (between) or group (mixed); below
   that the user is told to use simulation. This supersedes "Power comes
   from simulation" in the phase 2 entry above.

**Rounding and the Sommet tests (maintainer's rule: no tolerance that isn't
fully explained by the source).**

- Published values are transcribed to every digit the source prints, and
  the only rounding allowance is half a unit in that last printed digit
  (`expect_power_near()` adds it to the Monte Carlo half-width, which is 0
  for exact results). So the Superpower vignette's 88.1553371% is
  0.881553371 (allowance 5e-10) and book Table 5.4's 98.98467% is 0.9898467
  (5e-8); Lakens & Caldwell's 60.62% and the vignette's G*Power 91.25% stay
  at 0.6062 and 0.9125 (5e-5). A value whose last printed digit is 0 is
  written as a string so the digit isn't lost. Exact results meet all four.
- The 3% allowance for Sommet et al. is dropped. **The difference between
  their published N and the exact N is entirely explained by their normal
  approximation:** their Table 2 Ns are N = 4 (z_alpha + z_beta)^2 / d^2,
  rounded up, with z rounded to two decimals (1.96, 0.84 at power .80) and
  d = |interaction contrast| / (2 SD), which is their definition of the
  interaction effect, d = (d_simple1 - d_simple2) / 2 (Sommet et al., 2023,
  Equation 5, section "Calculating the required sample size to detect an
  interaction effect of a typical size"; applied with d = 0.175 in their
  Equation 8, N = 1,024; confirmed by the maintainer). That reproduces 256
  and 1024 exactly
  (and 343 and 424 for the reversed interaction at power .90 and .95). Each
  Sommet test now checks, with no allowance: (a) their formula applied to
  the spec's effect gives exactly the published N, confirming the spec
  matches their design; (b) powerkit's exact n_required equals the exact
  F-test N (260 and 1028, maintainer-checked) and is at least the published
  N.

**What the 2x2 validation tests now check.** Each analytic test runs twice
(nightly only, like all validation tests): with the default exact method,
where powerkit must equal a seeded direct `ANOVA_exact()` call (checks the
translation), and with `method = "simulation"`, where simulated power must
contain the exact answer in its 99.9% Monte Carlo interval (checks
simulation accuracy; maintainer's decision). The direct-call tests check
simulation against a direct `ANOVA_power()` call; the Type I tests use the
default exact method (power = alpha).

**Exact results are reproducible bit for bit.** `ANOVA_exact()` builds its
data set with the random-number generator (`mvrnorm(empirical = TRUE)`), so
two calls on the same design differ around the 15th decimal place (about
1e-15). A validation run caught this: an analytic test comparing powerkit's
exact power with a direct `ANOVA_exact()` call failed because the zero-width
exact interval could not absorb it. Rather than add a tolerance the source
doesn't explain, powerkit runs `ANOVA_exact()` under the run's seed
(restoring the caller's RNG state afterwards), so an exact result is
identical every time for a given seed, and the analytic tests' direct calls
use the same seed, so the comparison is exact equality.

## 2026-10-13 · Phase 3: basic tests, regression interactions, mediation

Backends now run every MVP design. Files: `R/backend-spower.R`,
`R/backend-interactionpower.R`, `R/backend-power4mome.R` (flat, as decided
in phase 0). Spower, power4mome and InteractionPoweR moved to Imports.
Versions used: Spower 0.6.4, InteractionPoweR 0.2.4, power4mome 0.2.1
(with manymome and lavaan 0.7.3), R 4.5.3.

**Direct-call helpers (`helper-direct-calls.R`), run against the real
packages for the first time.** The Superpower and power4mome calls were
right. Changed:

1. *Every Spower call failed* ("object of type 'symbol' is not
   subsettable"). `Spower::Spower()` reads its experiment unevaluated, so
   an experiment passed in as a variable is seen as a bare name. The
   helpers now write the experiment out as a call with its values in place
   (`bquote()`). Vectors and matrices are bound to names in the evaluation
   environment, because Spower turns each length-one argument into a
   column of its design table and cannot take longer ones. Spower draws
   its seed from R's generator, so `set.seed(seed)` before the call makes
   it reproducible (`control = list(seed = ...)` is rejected).
2. *Paired t-test: Spower's `d` is not d_z.* `Spower::gen_t.test(type =
   "paired")` draws the two time points independently with SD 1 and puts
   `d` in the first, so the differences have SD sqrt(2) and Spower's d is
   sqrt(2) * d_z. The helper converts the d_z it is given.
3. *Two proportions and chi-square: Yates' continuity correction off.*
   Spower's `p_prop.test()` and `p_chisq.test()` default to
   `correct = TRUE`. The spec's methods are the z test and Pearson's
   chi-square, which have no correction, so the helper (and powerkit)
   pass `correct = FALSE`. Given a matrix of cell probabilities,
   `p_chisq.test()` runs `chisq.test()` on the generated table, which is
   the test of independence; its null pattern `P0` is ignored, so the
   helper no longer builds one.
4. *InteractionPoweR: `power_interaction()` has no `seed` argument.* It
   uses R's generator when run on one core, so the helper calls
   `set.seed(seed)` first.

**Methods.** All three backends simulate; none has an exact method for
these designs (the schema already allows `method = "exact"` for 2x2
ANOVAs only). InteractionPoweR's analytic `power_interaction_r2()` is used
only to bracket the required n before simulating, as `ANOVA_exact()` is
in simulation mode. Whether to offer it as a method is an open question.

**Spower: one-sided tests.** Spower's `two.tailed = FALSE` halves the
two-sided p-value without checking the direction of the effect, so
results in the wrong direction also count as significant. With d = 0,
`Spower(p_t.test(n = 50, d = 0, two.tailed = FALSE))` rejected 10.1% of
4,000 replications at alpha = .05. So:
* two-sided tests use Spower's own experiment functions (`p_t.test()`,
  `p_r()`, `p_prop.test()`, `p_chisq.test()`) exactly as a user would;
* one-sided tests use Spower's data generators (`gen_t.test()`, `gen_r()`,
  `gen_prop.test()`) inside `Spower()`, analysed with the stats test and
  its `alternative` (`spower_one_sided_p()`). With d = 0 this rejected
  5.2% of 4,000 replications.
* Orientation: the spec's d is group 2 minus group 1; d_z is taken as the
  second condition minus the first (the schema doesn't say; open
  question); p2 versus p1. "greater" means that effect is positive.
  Spower puts d in group 1 or the first time point, so powerkit passes -d
  (and -sqrt(2) * d_z). Two-sided power doesn't depend on the sign.
* Group sizes: Spower's `n` is group 1's size, with `n2_n1` (t-test) or
  `n.ratios` (proportions) for group 2. Valid total n are the multiples of
  the smallest n that splits into whole groups (3 for a ratio of 2).

**Seeds and parallel replications.** As for Superpower: `nrep` is split
into one chunk per core (`simulate_in_chunks()`, now shared; the
Superpower adapter uses it with identical results), chunk seeds are
`seed`, `seed + 1`, ..., and on one core a run equals one direct backend
call with the run's seed. power4mome's own `parallel = TRUE` is not used:
with the same `iseed` it gave different results on 1, 2 and 4 cores.
InteractionPoweR's `cl` and Spower's `parallel` aren't used either.
Parallel chunks still run on Unix only.

**Sample-size search without an exact method.** `search_n()` brackets n
with the backend's `bracket_power()` if it has one (Superpower exact,
InteractionPoweR analytic). Otherwise (Spower, power4mome) it uses short
simulations of 100 replications at each n tried, each with its own seed
derived from the run's seed, starting at n = 20 (very small samples can
fail to fit) and stopping bisection within 10% (noisy power makes finer
bisection pointless). The bracket only places the grid; the probit
smoothing, the 95% interval and the grid widening are unchanged from
phase 2. This is powerkit's search, not Spower's or power4mome's own, so
every design reports n and its interval the same way.

**Check runs for simulation backends.** One data set of n = 100,000 from
the backend's own generator with the translated inputs. Each recovered
value must be within 5 standard errors of the specified one: chance puts a
correct translation outside 5 SEs about once in 1.7 million checks, while
a swapped sign, group or path is far outside at this n. SEs are those of a
mean (standardised mean differences, proportions, variances), from `lm()`
(path coefficients), or 1 / sqrt(n - 3) on Fisher's z scale
(correlations). What is checked:
* Spower: d, d_z, r, p1 and p2, and every chi-square cell probability, in
  the spec's orientation; the group-size ratio exactly.
* InteractionPoweR: the four correlations with perfect reliability (checks
  the renaming X -> x1, W -> x2); with the specified reliabilities, the
  observed correlations against the attenuated values InteractionPoweR
  itself reports (`power_interaction_r2(detailed_results = TRUE)`).
* power4mome: every path (each equation refitted by OLS), each observed
  variable's variance (1), X<->W, and parallel mediators' residual
  correlations.
Unit tests confirm each check catches a deliberate mistranslation.

**power4mome details.**
* *Fitting.* Models are fitted with lavaan (power4mome's default), because
  power4mome's Monte Carlo CIs need a lavaan fit: with
  `fit_function = "lm"` the MC test returns NA ("The fit is not a lavaan
  object"), although `lm` is about 10 times faster. ML point estimates
  equal OLS for these recursive models.
* *Product terms.* power4mome generates X, W, M and Y with variance 1, and
  a product of two standardised variables with variance 1 + r^2 (1.236
  recovered for r = 0.5 at n = 100,000), the coefficient applying to the
  raw product. This is the convention powerkit's validator assumed in
  phase 1, now confirmed; the check run tests it on every run.
* *Residual correlations.* Between two endogenous variables, power4mome's
  `M1 ~~ M2: v` is their residual covariance (all observed variables
  standardised), not their residual correlation: with v = 0.3, a1 = 0.4
  and a2 = 0.3, the recovered residual correlation was 0.344
  = 0.3 / sqrt(0.84 * 0.91). The spec gives correlations (schema and
  validator), so powerkit passes rho * sqrt((1 - R2_M1)(1 - R2_M2)), with
  R-squared from the validator's implied model.
* *Analysis model.* Parallel mediators' residual covariance is always free
  in the fitted model, whatever its population value, as in PROCESS
  (separate OLS regressions); lavaan would otherwise fix it at 0.
* *Test.* `test_indirect_effect()` for the spec's path (mediators in path
  order) or `test_index_of_mome()`; Monte Carlo (`ci_type = "mc"`) or
  percentile bootstrap (`"boot"`) CI at level 1 - alpha; R =
  `options > ci_draws`, default 1,000 (open question).
* *Boos-Zhang.* power4mome automatically extrapolates rejection rates
  (Boos & Zhang, 2000) when R is one of its supported small values
  (<= 359). powerkit turns this off (`options(power4mome.bz = FALSE)`), so
  the reported power is always the plain rejection rate (open question).
* *Failed replications.* power4mome drops data sets whose model fails to
  fit. Power is rejections over valid replications, and the MCSE uses the
  number of valid replications. (power4mome's column for this is `pvalid`,
  printed as "p.v".)
* power4mome re-evaluates parts of its own call, so powerkit calls it with
  `do.call()` and values, not expressions.

**Not available yet (plain-English `powerkit_not_available` errors).**
Each needs a methodological decision (open questions):
* sensitivity goals for every design except the 2x2 ANOVAs;
* binary X or W in regression interactions and mediation designs (the
  schema allows them; the example `process_7.json` has a binary X, so it
  can't run yet);
* reliability below 1 in mediation and moderated mediation (regression
  interactions do support it, through InteractionPoweR).
The phase 2 unit test "designs without a backend yet give a plain-English
error" used `process_7.json`. Every design now has a backend, so it now
checks a sensitivity goal (correlation) and the binary-X example.

**Fix: exact 2x2 results now equal a direct call bit for bit on every
platform.** The phase 2 unit test "exact results are reproducible bit for
bit and leave the RNG alone" failed on this Windows machine, on unchanged
`main` too (0.3490087878869276 vs 0.3490087878869249). Cause:
`superpower_exact()` received the design as a lazily evaluated argument,
so `ANOVA_design()`, which itself draws random numbers, ran after
`set.seed()` inside `with_seed()`, and `ANOVA_exact()` started from a
different random-number state than a direct call (design, then
`set.seed()`, then `ANOVA_exact()`). The design is now built first, under
its own `with_seed()` so the caller's random-number state is still left
alone, and `ANOVA_exact()` is then run under the seed. Exact results change
only around the 15th decimal place; this also makes the nightly 2x2
analytic tests' exact-equality comparison hold on every platform.

**Speed.** Spower: about 0.5 ms per replication; InteractionPoweR: about
4 ms at n = 400; power4mome: about 0.35 s per replication (simple
mediation, R = 1,000) and 0.7 s (moderated mediation). The nightly
mediation and moderated-mediation validation tests need about 170,000
power4mome replications at 10,000 each, roughly 22 CPU-hours: more than
the nightly job's 6 hours on 4 cores (open question).

**Validation run for this phase (10,000 replications, Windows, R 4.5.3).**
* Basic tests (Spower): all 20 analytic, direct-call and Type I error
  tests pass, including the one-sided t-test; Type I error rates .048 to
  .052. The 4 G*Power published tests skip (TODO values).
* 2x2 ANOVA (after the Superpower RNG fix): the 8 tests that finished all
  pass (both vignette, both paper and both Sommet et al. published tests,
  and two Type I tests).
* Not run to completion: regression interactions, the 2x2 analytic and
  direct-call tests that hadn't finished, and every mediation and
  moderated-mediation direct-call and Type I test. The local run was
  stopped from outside after about two hours, while the mediation tests
  were still running; at the maintainer's request the rerun covered the
  basic tests only. These tests have run at small replication counts (the
  unit tests, including a power4mome run equal to a direct `power4test()`
  call), but not at 10,000.
* Their published-value tests skip (TODO values), as expected.

### Open questions for the maintainer (methodological, not decided here; answered in "Phase 3: maintainer decisions" below)

1. **Regression interactions: analytic method?** InteractionPoweR's
   `power_interaction_r2()` gives analytic power (noncentral F, with
   reliability by attenuation). It is used only to bracket n. Should it be
   offered as a method (`options > method = "exact"` or a new
   `"analytic"`), and should it be the default, as `ANOVA_exact()` is for
   2x2 designs? It is an approximation for random predictors, so it isn't
   exact in the same sense.
2. **Binary X or W.** The schema allows them in regression interactions
   and mediation designs, but they aren't run yet. Interactions:
   InteractionPoweR's `k.x1 = 2` / `k.x2 = 2` with
   `adjust.correlations = TRUE` (the observed binary data then have the
   specified correlations)? Mediation: power4mome's `x_fun` with
   `rbinary_rs()`; with what group split (equal, or an allocation ratio),
   and does a "standardised path" from a binary X mean per SD of the 0/1
   variable? This blocks the example `process_7.json`.
3. **Measurement error in mediation designs.** power4mome models
   unreliability with `number_of_indicators` and `reliability`: analysed
   as latent variables or as scale scores (as PROCESS users would), and
   with how many indicators?
4. **Sensitivity for the new designs.** Which value is scaled: d, d_z or r
   (obvious); p2 with p1 fixed (or both moved apart)?; the chi-square
   table's departure from independence?; r_XW_Y?; for mediation a, b,
   both, or the indirect effect itself? Spower can solve for a missing
   effect size; power4mome's `x_from_power()` can for a path.
5. **Paired t-test direction.** The spec defines d_z as "mean of the
   within-person differences / SD of the differences" without saying which
   difference. powerkit uses second condition minus first, matching
   independent groups (group 2 minus group 1). Only one-sided tests
   depend on it. Confirm, and say so in the schema description?
6. **Continuity correction.** The z test for two proportions and the
   Pearson chi-square run without Yates' correction, as their names imply
   (and as G*Power and `pwr` assume). Offer Yates as an option?
7. **Spower's one-sided p-values.** powerkit works around them (above).
   Report to Phil Chalmers?
8. **Parallel mediators' residual covariance** is always free in the
   fitted model (as in PROCESS). Confirm. Related: the direct-call test
   "parallel mediation with correlated residuals" gives power4mome
   `m1 ~~ m2: 0.4`, which power4mome reads as a residual covariance, while
   the spec's 0.4 is a residual correlation, so powerkit passes
   0.4 * sqrt(0.91 * 0.96) = 0.3739. The two populations differ slightly.
   I haven't edited the test (maintainer-owned); change its pop_es to
   `m1 ~~ m2: 0.3739` (and the model is already free)?
9. **Monte Carlo draws per CI:** default 1,000 when `options > ci_draws` is
   absent. Right default?
10. **Boos and Zhang (2000) extrapolation** in power4mome is turned off.
    It could cut run time a lot for small R. Allow it, and if so when?
11. **Nightly runtime.** At 10,000 replications and R = 1,000, the
    mediation and moderated-mediation validation tests need about 22
    CPU-hours, well over the nightly job's 6 hours on 4 cores. Options: a
    job per test file (matrix) on more runners, a larger runner, fewer
    replications for the slow designs (with the power-detection argument
    redone), or running those weekly.
12. **lavaan ML instead of OLS** for mediation fits (needed for power4mome's
    Monte Carlo CIs). Point estimates equal OLS; standard errors use n
    rather than n - p. Acceptable?

## 2026-10-13 · Phase 3: maintainer decisions

Answers to the phase 3 open questions above (numbered as there), and what
was done. Departures from other tools are recorded in
`docs/conventions.md` ("Departures"), each with a test showing its size.

**Licence.** The engine is licensed under the GPL (>= 3)
(`engine/DESCRIPTION`, `engine/LICENSE`; PR #3). This log had no earlier
licence line; the phase 0 entry's set-up predates the choice.

1. **Regression interactions: analytic method.** Use InteractionPoweR's
   analytic `power_interaction_r2()` as the default where it is exact,
   simulation otherwise, but only after a test shows the two agree within
   Monte Carlo error. Until then simulation stays the default (no code
   change). The test is the existing validation test "interaction,
   perfectly measured: power matches power_interaction_r2 (analytic)" (and
   its unreliable-measures twin), which compares powerkit's simulation with
   the analytic value at the 99.9% Monte Carlo interval; it has not yet run
   at 10,000 replications. Where the analytic method counts as exact is to
   be set out when it is switched on.
2, 3, 4. **Binary X or W, measurement error in mediation designs, and
   sensitivity goals for the new designs** stay "not available yet", with
   their plain-English errors, until the maintainer decides after review.
5. **Paired designs: d_z is the second condition minus the first** (in
   the order of X's levels), stated on screen. Done: the schema's
   description of `dz` says so, and printing a paired spec shows "Effect:
   d_z = mean of (After minus Before) / SD of those differences" with the
   user's level labels (test: `test-read-spec.R`, "a paired spec states
   the direction of d_z"). The app (phase 5) must show the same line on
   the confirmation and results screens.
6. **No Yates' continuity correction** for the two-proportions z test and
   the Pearson chi-square (matches G*Power); no option to add it. This
   departs from Spower's default (`correct = TRUE`): conventions.md,
   Departure 5.
7. **Spower's one-sided tests.** A minimal reproducible example is in
   `docs/upstream/spower-one-sided-tests.R`, for the maintainer to send to
   Phil Chalmers (nobody has been contacted). Seeded, 10,000 replications:
   Type I error 0.1009 with `two.tailed = FALSE` against 0.0495 with a
   directional test; with d = 0.5 both give 0.7931.
8. **Parallel mediators: residuals free to correlate, as in PROCESS.** The
   direct-call test "parallel mediation with correlated residuals" now
   gives power4mome `m1 ~~ m2: 0.3739`, with the derivation from the spec's
   correlation in a comment (0.4 * sqrt(0.91 * 0.96) = 0.37387). Size of
   the departure from lavaan's default (residual covariance fixed at 0):
   conventions.md, Departure 7.
9. **Monte Carlo draws per CI: power4mome's own default.** power4mome has
   no single default. `power4test()` has none: with `R = NULL` it makes no
   draws, so no confidence-interval test can run. The low-level generators
   `gen_mc()` and `gen_boot()` (and manymome's `indirect_effect()`) default
   to 100. power4mome's own functions for a mediation power analysis,
   `q_power_mediation()` and `q_power_mediation_simple()`, default to
   `R = 1000`. powerkit uses that, read from `q_power_mediation()` at run
   time (`default_ci_draws()`, test: "Monte Carlo draws default to
   power4mome's own default for mediation power"), so it follows
   power4mome if the default changes. In power4mome 0.2.1 it is 1,000, the
   value powerkit already used.
10. **Boos and Zhang's method: off for validation**, recorded as a
    departure from power4mome's default (conventions.md, Departure 8); the
    user-facing choice is for later, so for now it is off for every run.
    While writing the size test, two things were found:
    * *power4mome's documented switch does not reach its test functions.*
      `test_indirect_effect()` and `test_index_of_mome()` check
      `!isFALSE(options("power4mome.bz"))`; `options()` returns a list, so
      this is always TRUE and `options(power4mome.bz = FALSE)` has no
      effect there (its summary functions use `getOption()`, which works).
      So the option phase 3 set did not turn the method off. powerkit now
      asks for the confidence-interval rule explicitly
      (`test_method = "ci"`, a documented argument of both test functions)
      and still sets the option for the summaries. This could be a second
      upstream report (to Shu Fai Cheung); not prepared.
    * *Size: none in powerkit's runs.* At the supported numbers of draws
      (39, 79, ..., 359), Boos and Zhang's p-value rule gives the same
      decision as the confidence interval in each replication, and
      `power4test()` does not extrapolate the rejection rate
      (`bz_extrapolated = FALSE`; the extrapolation is used in power4mome's
      own searches such as `x_from_power()`). On 100 seeded replications
      at R = 39, both rules gave identical rejection rates (test:
      "departure: Boos-Zhang off makes no difference to power4test()'s
      rejection rate"). At other numbers of draws (including the default
      1,000) the method is never used.
11. **Validation strategy.**
    * *Nightly CI runs a fast subset:* the unit tests plus the basic-test
      and regression-interaction validation files, which take minutes
      (`.github/workflows/nightly-validation.yaml`; `devtools::test()` with
      `filter = "validation-(anova|mediation|modmed)", invert = TRUE`. The
      filter is matched against each file's path, so it can't be
      anchored with `^`). The 2x2 ANOVA validation tests leave the nightly
      job too: their simulation reruns take a few CPU-hours.
    * *Full validation runs on demand,* before merges and releases, on the
      maintainer's machine, with `scripts/run-validation.R`. Each test runs
      in its own R process (processx, already installed with testthat), 2
      at a time by default (`--cores` for more), with
      `POWERKIT_CORES=1` inside each, so a crash loses at most the tests in
      progress. Each result is saved to `validation-results/` (git-ignored)
      as soon as it finishes, written to a temporary file and renamed so it
      is never half-written; a rerun skips saved tests, and tests that
      were running when it stopped run again. `--only` runs chunks by
      design (basic, anova, interactions, process_4, process_6, process_7,
      process_14), `--list` shows progress, `--retry-failed` reruns FAIL
      and ERROR, `--fresh` starts again. Stopping the script stops its
      tests (processx kills them when the script ends; checked by stopping
      a run part-way: no R processes were left). It prints progress with
      an estimate of the time left (rough minutes per test, corrected by
      how fast tests actually run), and ends with a summary to paste back
      (also `validation-results/summary.txt`): commit (flagged if there
      are uncommitted changes), R and package versions, totals, and every
      test's numbers. Tested on the basic chunk: 24 tests in 4 minutes on
      2 cores, identical results to the earlier run; resuming after a
      stop ran only the 4 tests that had not finished.
    * The validation helpers' messages are now worded to read correctly
      whether a test passes or fails ("Reference power 0.8015; must lie in
      [...]"), since the summary shows them for passing tests too. Only
      the wording changed, not what is checked.
12. **lavaan ML for the mediation fits: accepted**, recorded as a departure
    from PROCESS's OLS (conventions.md, Departure 6). Test at N = 50
    ("departure: lavaan ML standard errors vs PROCESS's OLS, at N = 50"):
    the estimates are identical and the ML standard errors are exactly
    the OLS ones times sqrt((n - k) / n), with k the number of
    coefficients including the intercept: 2.0% smaller for the a path
    (k = 2) and 3.0% smaller for b and c' (k = 3).

**README.** The status table now says basic tests are working (validated
at 10,000 replications, G*Power published examples to come), and the
interaction and mediation designs are "built, not yet validated" until
the full validation passes.

**Unit-test run time.** Routine `devtools::test()` and `devtools::check()`
should finish in about 5 minutes on a laptop; slow simulation checks belong
in the validation suite or use small settings. The slowest unit tests were
cut (a power4mome run equal to a direct call now uses 10 replications at
the adapter level; simulation and sample-size tests use 100 replications
where that still pins down n). `devtools::test()` now takes about 2 minutes
and `devtools::check()` about 3 on the maintainer's machine. The Spower
sample-size test keeps 400 replications: with 100 the search's interval
runs off its grid and powerkit stops with its plain-English "could not pin
down the required n" message, which is the intended behaviour for too few
replications.

## 2026-10-13 · Regression interactions: analytic method, before any switch

The interactions validation chunk passed (maintainer's run, commit
97cc736): both analytic tests agree with simulation (0.6343 vs 0.6363
perfectly measured; 0.5483 vs 0.5544 with unreliable measures). The
maintainer judged two populations not enough to change the default
(decision 1 above). So:

1. **A grid comparison, on demand only.** `scripts/run-validation.R --only
   interaction_grid` compares InteractionPoweR's analytic
   `power_interaction_r2()` with powerkit's simulation (10,000 replications
   per cell) over N = 50, 100, 200, 500; interaction r_XW_Y = 0.05, 0.10,
   0.20 (small to moderate); reliability 1.0, 0.8, 0.7; and r_X_W = 0 and
   0.3: 72 cells. Main effects are fixed at r_X_Y = r_W_Y = 0.2, and the
   same reliability is given to X, W and Y. Each cell reports both values,
   the difference (simulation minus analytic) and whether the analytic
   value lies inside the 99.9% Monte Carlo interval of the simulation (the
   validation tolerance rule). The summary adds whether the differences
   lean one way: the share of cells where simulation is higher (with a
   sign test), the mean signed difference with its Monte Carlo SE, and the
   mean difference by N, reliability, interaction size and r_X_W. The grid
   is not part of "everything" and is never run by `devtools::test()` or
   nightly CI. Each cell runs in its own R process and is saved as it
   finishes, like the tests, with seed 60000 + the cell's number.
2. **Which method InteractionPoweR presents as primary: neither.** Checked
   in InteractionPoweR 0.2.4's DESCRIPTION and help pages and on its
   website (home page; articles "The InteractionPoweR Package" and
   "Questions & Errors"; no vignettes are installed with the package):
   * DESCRIPTION names both as "the primary functions": "The primary
     functions are power_interaction_r2() and power_interaction() for
     two-way interactions", and says power analyses "can be done either
     analytically or via simulation".
   * The main article introduces the analytic method first ("A simple
     power analysis"), then simulation, and notes analytic power is fast
     to compute; it doesn't recommend either.
   * The home page offers both web apps. It recommends the analytic app
     "particularly for beginners and users who are new to power analyses",
     and describes the simulation app as implementing "the major
     functions for simulation-based power analyses".
   * The analytic method's scope, from its help page: "Valid for
     interactions with continuous, normally distributed, variables."
   * "Questions & Errors" says nothing on which to use.
   Since simulation isn't presented as InteractionPoweR's primary method,
   making the analytic method the default would not be a departure under
   the conventions rule. It would change powerkit's own default, so it is
   recorded in `docs/conventions.md` under "Not departures, but worth
   stating", with the grid as the test of its size.
3. **The default stays simulation** until the maintainer has seen the grid.
   The plan then: analytic is the default only for continuous X and W
   within the tested ranges (N 50-500, r_XW_Y 0.05-0.20, reliability
   0.7-1, r_X_W 0-0.3), simulation everywhere else. It would be labelled
   "analytic (checked against simulation)" on the results screen and in
   the methods paragraph, never "exact".
4. The three published InteractionPoweR tutorial tests stay skipped
   (TODO values).

## 2026-10-13 · Regression interactions: grid results; simulation stays the default

The maintainer ran the `interaction_grid` chunk (commit 3b136fe, 2 cores,
28 minutes; R 4.5.3, InteractionPoweR 0.2.4). It compares InteractionPoweR's
analytic `power_interaction_r2()` with powerkit's simulation
(`power_interaction()`, 10,000 replications per cell) over 72 cells (see the
previous entry for the grid).

**Results**

- **3 of 72 cells fall outside the 99.9% Monte Carlo interval.** If the two
  methods agreed, about 0.07 would be expected. Simulation vs analytic:
  - N = 50, r_XW_Y = 0.10, reliability 0.7, r_X_W = 0: 0.0604 vs 0.0686
    (-0.0082);
  - N = 50, r_XW_Y = 0.20, reliability 0.8, r_X_W = 0: 0.1547 vs 0.1668
    (-0.0121);
  - N = 200, r_XW_Y = 0.20, reliability 1.0, r_X_W = 0.3: 0.8084 vs 0.8222
    (-0.0138).
- **The differences lean one way.** Simulation is lower than analytic in 51
  of 72 cells (sign test p = 0.0005). The mean signed difference
  (simulation minus analytic) is -0.0023 (Monte Carlo SE 0.0004, z = -5.49).
- **Mean difference by interaction size:** +0.0001 (r_XW_Y = 0.05), -0.0023
  (0.10), -0.0048 (0.20). **By reliability:** -0.0022 (0.7), -0.0014 (0.8),
  -0.0033 (1.0), so the gap is not from how unreliability is handled.
  **By N:** -0.0035 (50), -0.0023 (100), -0.0022 (200), -0.0013 (500).
  **By r_X_W:** -0.0019 (0), -0.0027 (0.3).
- **Size in participants.** In the cell with the largest gap (N = 200,
  r_XW_Y = 0.20, reliability 1.0, r_X_W = 0.3), the analytic method first
  reaches 80% power at N = 190. Simulation reaches it at about N = 196
  (0.8084 at N = 200, with the power curve rising by about 0.0019 per
  participant there). The analytic N is about 3% smaller.

**Likely causes (likely, not confirmed).** `power_interaction_r2()`
computes power from a noncentral F with 1 and N - 3 df and noncentrality
f^2 x (N - 3) (InteractionPoweR 0.2.4 source).

1. **Fixed vs random predictors.** The noncentral F treats the predictors
   as fixed. In real samples X and W are random and their product is
   heavy-tailed, so the information about the interaction varies from
   sample to sample, which on average lowers power, more so for larger
   effects. This fits the pattern but has not been tested separately.
2. **Possibly the df convention.** The model Y ~ X + W + XW leaves N - 4
   residual df; using N - 3 would give slightly higher power. Whether this
   is intended has not been checked.

Neither is described as a bug in InteractionPoweR: fixed-model power is a
standard approximation.

**Decision (maintainer)**

1. **Simulation stays the default** for regression interactions, and no
   analytic option is offered for now. The analytic method keeps its one
   current use, bracketing N in the sample-size search; the reported power
   and N always come from simulation. This replaces the plan in item 3 of
   the previous entry.
2. **Recorded as a known difference** in `docs/conventions.md` ("Known
   differences", 1): fixed-model regression power, such as G*Power's and
   `power_interaction_r2()`, is slightly optimistic for interactions, so
   powerkit may need a few more participants than G*Power. The entry also
   holds the sentence for interaction designs' methods paragraph, to be
   added when the methods paragraph (`writeup.R`) is built in phases 4-5.
3. **G*Power was not run.** The grid measured `power_interaction_r2()`.
   G*Power's linear multiple regression power is believed to work the same
   way (a noncentral F with fixed predictors); its noncentrality and df are
   to check in G*Power's manual.
4. **The `interaction_grid` chunk stays** in `scripts/run-validation.R`, on
   demand only, so it can be rerun later (for example after an
   InteractionPoweR update).

## 2026-10-13 · Bug in scripts/run-validation.R: loop-generated tests (fixed)

Found by the maintainer: the anova chunk reported 10 PASS, but the results
were wrong.

**The bug.** Two faults together:

1. `test_descriptions()` listed only top-level `test_that()` calls with a
   literal name. The two 2 x 2 ANOVA files generate most of their tests in
   `for` loops (each file: 8 checks against `ANOVA_exact()`, exact and
   simulated, and 2 direct `ANOVA_power()` calls), so 20 of the 30 ANOVA
   tests were never selected.
2. `run_one_test()` used `testthat::test_file(desc = ...)`, which runs the
   file's other top-level code before the selected test, including those
   loops, so every loop-generated test ran too (9 tests for the second test
   in the between file). It then recorded `results[[1]]`, the first test
   that ran, not the selected one. So every anova result showed the first
   analytic check's message (0.8074 in the between file, 0.2473 in the
   mixed file).

**Which results are affected.** Only the anova chunk: the two ANOVA files
are the only validation files with loops (checked: the others' top-level
code only defines functions and constants). In a file without loops,
`test_file(desc = ...)` ran exactly the selected test (checked for a basic
test and an interaction test), so the basic and interactions results
already reported are sound. The anova results reported so far are invalid
and must be rerun.

**The fix** (no expected values in the test files changed):

- The list of tests comes from evaluating each file's top-level code with
  `test_that()` replaced by a recorder, so loop-generated tests are listed,
  in the order testthat runs them: 16 tests in the between file and 14 in
  the mixed file (30, up from 10).
- A test runs in its own process with `test_that()` replaced by a stand-in
  that runs only the selected block (by its position in the file, loops
  included) and skips the others without evaluating them. The result
  recorded is the one testthat reports under the test's description; if
  testthat reports anything other than exactly that one test, the result
  is an ERROR naming what it did report.
- Before anything runs (and with `--list`), the script checks, for each
  selected file, that its list of tests matches the list testthat reports
  (count, names and order; testthat's list comes from running the files
  with the validation tests switched off, about 15 seconds for all files),
  and stops if they differ.
- A saved result is used only if it records the same test name and
  position; anything else (including the old anova results, which were
  numbered differently) is ignored and the test runs again. No need to
  delete old results by hand.
- Checked: each of 6 ANOVA tests run individually recorded its own value
  (0.8074, 0.5948 and 0.4158 for the first three analytic checks, 0.8816
  for the vignette example, the Sommet et al. crossover N, and 0.1727 for
  the mixed design with a negative correlation); dropping one test from the
  script's list stops the run with "the script finds 15 tests, testthat
  reports 16"; and a run in which testthat reports 24 tests is recorded as
  an ERROR.

## 2026-10-13 · Housekeeping: published ranges, rerunning skipped tests, sources

No expected values changed and no `TODO_PUBLISHED_VALUE` was filled in or
removed.

**1. Published required-N ranges: an overlap rule (a powerkit judgment).**
Some sources report the required N as a range, not a point:

- the InteractionPoweR tutorial (Baranger et al., 2023) searched N in steps
  of 250 and reports "approximately 3,750", so the true value lies in
  3,501 to 3,750;
- power4mome's `n_region_from_power()` reports a region (e.g. 300 to 347).

`expect_n_near()` (`tests/testthat/helper-validation.R`) now takes either a
single published N (unchanged: it must lie in powerkit's interval for the
required N) or a range `c(lower, upper)`. A range passes if it overlaps
powerkit's interval `[lower, upper]`; the message states both intervals
and their overlap (or "none").

- *Not an established convention.* No source or tool sets a rule for
  comparing a simulated required-N interval with a published range; this
  is powerkit's own judgment, recorded here so it can be revisited.
- *Lenient.* Overlap is the weakest sensible check: two wide intervals
  overlap easily, and a 250-wide published range can be met by an
  interval that only touches its edge. A pass says powerkit's answer is
  compatible with the source, not that the two agree closely.
- *Narrow passes are reported.* A pass where powerkit's point estimate lies
  outside the published range (so the intervals overlap only at one end)
  gives a warning starting "Narrow pass", naming the estimate, both
  intervals and the overlap. It shows in `devtools::test()` output and in
  `scripts/run-validation.R`'s summary (the test is still a PASS). Such a
  pass should be reported and looked at, not taken as agreement.
- The required-N published tests in the interaction and PROCESS model 7
  files now have two placeholders, `published_n` and `published_n_range`,
  both `TODO_PUBLISHED_VALUE`: give exactly one and set the other to NULL
  (`published_n_value()` stops otherwise).
- Unit tests: `tests/testthat/test-expect-n-near.R` (point, overlapping
  range, narrow overlap, non-overlapping range, malformed input).

**2. `scripts/run-validation.R --retry-skipped`.** A test skipped for a
`TODO_PUBLISHED_VALUE` is saved as SKIP and counts as done, and
`--retry-failed` reruns only FAIL and ERROR, so after values were filled in
those tests only reran with `--fresh`, which also discards the long
results. `--retry-skipped` (`run_validation(retry_skipped = TRUE)`) reruns
the tests saved as SKIP and keeps every other result; it can be combined
with `--retry-failed`. It follows the PR #7 design: a saved result belongs
to a test only if it records that test's name and position, so only those
results are deleted and rerun (a result saved under another name or
position is already ignored, and that test runs anyway). `--list` now
shows each chunk's saved results by status and says which flag reruns
what. One behaviour change: the retry flags now act only when tests are
about to run. Before, `--retry-failed` combined with `--list` or
`--summary` deleted the FAIL / ERROR results without rerunning them.

Renamed tests (their saved results, all SKIP, are ignored by the name
check and the tests rerun, which takes seconds):
"simple mediation: matches the power4mome Quick Template (published)",
"parallel mediation: matches a published parallel example (published)",
"PROCESS model 7: matches Donnelly, Jorgensen & Rudolph (2023)
(published)" and "PROCESS model 14: matches Donnelly, Jorgensen &
Rudolph (2023) (published)".

**3. Sources of the published tests (comments only).**

- *Simple mediation, PROCESS model 7 and model 14:* power4mome's Quick
  Templates ("Quick Template: Simple Mediation with Observed Variables";
  "Quick Template: Simple Moderated Mediation with Observed Variables:
  a-Path Moderated" for model 7 and "...: b-Path Moderated" for model 14).
  Each test has lines for the power4mome version that built the website
  and the date the maintainer read it, since the articles' output is
  regenerated each time the site is rebuilt.
- *Parallel and serial mediation:* no published two-mediator example has
  been found. power4mome's templates use three mediators (the parallel one
  tests whether all the specific indirect effects are significant), and
  Schoemann, Boulton & Short (2017) has no parallel or serial example.
- *Donnelly, Jorgensen & Rudolph (2023)* (Behavior Research Methods,
  55(7), 3892-3909; earlier called the "simsem tutorial") can't be used
  yet: its X and W are binary; it reports no power for the index of
  moderated mediation, only for a conditional indirect effect at a level
  of W it doesn't state; and it has no model 14 example. Both tests stay
  TODO; the model 7 one becomes usable when binary X and W are supported
  (and then for a conditional indirect effect, not the index).
- *InteractionPoweR measurement-error test:* Baranger et al. (2023) report
  60% power with all reliabilities 0.8 but don't say whether it came from
  `power_interaction_r2()` (analytic) or `power_interaction()`
  (simulation, and with how many iterations), so `reference_nrep` can't
  be set. It stays TODO.

**4. Schoemann, Boulton & Short (2017): a recorded sanity check, not a
test.** The paper's only worked example is simple mediation given as
correlations: r_XM = .35, r_MY = .25, r_XY = .10, with 5,000 replications,
20,000 Monte Carlo draws and a 95% confidence interval. It reports
"approximately 150" participants for 80% power, found with a varying-N
method, and gives no precision for that figure. With no precision there is
nothing to test against, so it is kept as a sanity check: an independent
tool reports about 150, and powerkit's answer will be recorded next to it.

- *Schoemann et al.:* about 150 (80% power, 95% Monte Carlo CI).
- *powerkit:* not run yet. For powerkit's spec, the correlations give the
  standardised paths a = r_XM = .35, b = (r_MY - r_XM r_XY) / (1 - r_XM^2)
  = .215 / .8775 = 0.2450, and c' = (r_XY - r_XM r_MY) / (1 - r_XM^2) =
  .0125 / .8775 = 0.0142 (to be checked by the maintainer before the run).

**5. Open question to Shu Fai Cheung: which test did the templates use?**
power4mome's templates leave `test_method` unset. powerkit always asks for
the confidence-interval test (`test_method = "ci"`, decision 10 of "Phase
3: maintainer decisions"; conventions.md, Departure 8), but with
`test_method` unset power4mome switches to Boos and Zhang's asymmetric
p-value when the number of draws R is one of 39, 79, ..., 359. So a
template run with such an R may have used the p-value rule. If a
template's R is outside that set the question doesn't arise for it. Phase
3 found the two rules gave the same decision in each replication at R = 39
(100 seeded replications), so any difference is expected to be small, but
that is not confirmed for the templates. Each template-based test says
this in a comment. Not yet asked.

**6. Binary X or W: messages.** The "not available yet" messages for a
binary X or W (`R/backend-interactionpower.R`, `R/backend-power4mome.R`)
no longer suggest treating the variable as continuous, which can give an
inaccurate power estimate (InteractionPoweR's manual says
`power_interaction_r2()` is valid only for continuous, normally
distributed variables). The interaction message suggests a 2x2 ANOVA only
when both X and W are binary, the only case it fits. A proposed phase for
binary X and W is in `docs/build-guide.md`, section 8.

**7. Binary X or W in power4mome: the backend convention (maintainer).**
power4mome supports a binary X or W through `power4test()`'s `x_fun`
argument with `rbinary_rs()`: a 0/1 variable rescaled to mean 0 and SD 1,
so effects are fully standardised. This is recorded in the proposed phase
(`docs/build-guide.md`, section 8) as the backend convention that powerkit
follows, not as a question for Shu Fai Cheung. The questions left for him
are whether a binary X can be correlated with W and whether the Monte Carlo
CI test has been checked with a binary X.
