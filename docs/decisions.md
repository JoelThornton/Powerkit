# Decisions log

Short records of decisions that are not obvious from the code. Newest last.
Full validation runs are recorded in `docs/validation-log.md`.

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
   `docs/upstream/spower-one-sided-tests.R`. Seeded, 10,000 replications:
   Type I error 0.1009 with `two.tailed = FALSE` against 0.0495 with a
   directional test; with d = 0.5 both give 0.7931. Reported to Phil
   Chalmers on 13 October 2026 ([philchalmers/Spower#3](https://github.com/philchalmers/Spower/issues/3)); confirmed,
   fixed on GitHub (Spower 0.7, commits of 14 October 2026: the `p_*`
   functions pass `alternative` to the underlying test, and a new
   `alternative` argument overrides `two.tailed`) and the issue closed.
   CRAN is still 0.6.4, with the bug (checked 15 October 2026), so
   powerkit keeps its directional workaround. When a CRAN release has the
   fix, the departure is retired after a test confirms the direction
   mapping; the existing departure test is then expected to fail, which is
   the signal to retire it (conventions.md, Departure 4; "Upstream watch"
   below).
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
      and still sets the option for the summaries. Reported to Shu Fai
      Cheung on 13 October 2026
      ([sfcheung/power4mome#276](https://github.com/sfcheung/power4mome/issues/276));
      confirmed and fixed on GitHub (power4mome 0.2.1.33, 14 October
      2026: all five test functions use `getOption()`; he also checked
      the package's other `options()` / `getOption()` uses). CRAN is still
      0.2.1, with the bug (checked 15 October 2026). powerkit keeps
      `test_method = "ci"` regardless, since Boos and Zhang off is this
      decision, not only a workaround (conventions.md, Departure 8;
      "Upstream watch" below).
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
   `power_interaction_r2()`, gives slightly higher power for interactions, so
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
Rudolph (2023) (published)". Renamed on 15 October 2026, when their
sources changed: "independent t-test: matches the Faul et al. (2007)
G*Power example (published)", "correlation: matches the Faul et al.
(2007) exact bivariate-normal example (published)" and "two proportions:
matches a published example (published)" (no source yet). The paired
t-test keeps its name, since it still uses the G*Power 3.1 manual.

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

**5. The power4mome templates used the confidence-interval test
(settled by the maintainer).** The templates leave `test_method` unset,
and with it unset power4mome switches to Boos and Zhang's asymmetric
p-value only when the number of draws R is one of 39, 79, ..., 359
(conventions.md, Departure 8). The templates use R = 1000, so they used
the confidence-interval test, the same test powerkit always asks for
(`test_method = "ci"`, decision 10 of "Phase 3: maintainer decisions").
Not a question for Shu Fai Cheung. Each template-based test says this in a
comment.

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

## 2026-10-15 · Upstream reports fixed; upstream watch; validation log

**Upstream reports** (checked against the upstream repositories and CRAN on
15 October 2026). Both issues reported on 13 October were confirmed and fixed
on GitHub on 14 October, with thanks to Phil Chalmers and Shu Fai Cheung for
their quick responses; neither fix is on CRAN yet:

- Spower ([philchalmers/Spower#3](https://github.com/philchalmers/Spower/issues/3),
  closed): fixed in 0.7 on GitHub; CRAN 0.6.4 predates the fix. See item 7 of
  "Phase 3: maintainer decisions" and conventions.md, Departure 4.
- power4mome ([sfcheung/power4mome#276](https://github.com/sfcheung/power4mome/issues/276)):
  fixed in 0.2.1.33 on GitHub; CRAN 0.2.1 predates the fix. See item 10 of
  "Phase 3: maintainer decisions" and conventions.md, Departure 8.

### Upstream watch

powerkit stays on CRAN releases, never GitHub development versions, so the
versions it records stay installable. When either package publishes a new
CRAN release (Spower above 0.6.4, power4mome above 0.2.1):

1. On a branch, update `renv.lock` to the new release.
2. Run the full test suite (`devtools::test()`, `devtools::check()`) and
   the affected validation chunks with `scripts/run-validation.R` (Spower:
   `basic`; power4mome: `process_4`, `process_6`, `process_7`,
   `process_14`), and record the run in `docs/validation-log.md`.
3. Then act on the departure:
   * **Spower:** retire Departure 4 and use Spower's own functions with
     `alternative`, after a test confirms the direction mapping (powerkit's
     "greater" means the effect is positive; powerkit currently passes -d).
     The departure test "one-sided tests check the direction, unlike
     Spower's two.tailed = FALSE" is expected to fail after the upgrade:
     that is the signal to retire the departure, not a bug.
   * **power4mome:** record "fixed upstream in version X" in Departure 8.
     Keep `test_method = "ci"`: Boos and Zhang off is the maintainer's
     decision, not only a workaround.

### Validation log

`docs/validation-log.md` (new) collects every full validation run from now
on: date, commit, platform, versions and results per chunk. It starts with
the full anova chunk of 14 October 2026 (30 PASS of 30, the first run with
every test recorded under its own name, after PR #7) and the earlier basic
and interactions results recorded above, which PR #7 confirmed were
unaffected by the loop bug. `scripts/run-validation.R` now says to paste
the summary there after a full run.

The anova chunk's four Type I error tests use the exact method
(`ANOVA_exact()`), so they give exactly 0.0500 by construction. They
confirm that powerkit translates "no effect" correctly, but they are not
an empirical check of the simulation's Type I error rate. Simulation
versions of these tests are listed as an open item in
`docs/build-guide.md`, section 6.

## 2026-10-15 · Running power4mome simulations in batches

**Problem.** Two full validation runs on the maintainer's laptop (7.7 GB of
memory) ran for about 12 hours without finishing the PROCESS model 7 and
14 direct-call tests, then the laptop froze and Windows logged an
unexpected shutdown. Each of those tests runs two simulations of 10,000
replications with 1,000 Monte Carlo draws (powerkit, then a direct
power4mome call), and each simulation was a single `power4test()` call:
`simulate_in_chunks()` made one chunk per core, and the validation script
gives each test one core. `power4test()` keeps every replication's data,
fitted model, draws and test results until it returns, so its memory
grows with `nrep`.

**Measured** (one `power4test()` call, the model 7 direct-call design:
n = 250, R = 1,000 Monte Carlo draws, index of moderated mediation; R
4.5.3, power4mome 0.2.1, Windows; peak working set of the R process, which
used about 107 MB before the call):

| nrep  | peak memory | R heap, max used | result object | time |
|-------|-------------|------------------|---------------|------|
| 100   | 391 MB      | 269 MB           | 299 MB        | 154 s (1.5 s per replication) |
| 500   | 940 MB      | 755 MB           | 1,493 MB      | 530 s (1.1 s per replication) |
| 1,000 | 1,635 MB    | 1,261 MB         | 2,986 MB      | 1,324 s (1.3 s per replication) |

"Result object" is `object.size()` of the returned object, which counts
shared parts more than once, so it overstates; peak memory is the measure
to go by. A first nrep = 500 run gave the same memory but took 10,742 s of
wall time, probably because the laptop slept; the rerun above (527 s of
CPU time) is the one shown.

Memory grows about linearly with `nrep`: roughly 1.1 MB of R heap and
1.4 MB of process memory per replication, on top of a fixed part. Time
grows linearly too (1.1 to 1.5 s per replication on one core), so the
slowness of the crashed runs came from the memory, not from the method.
Extrapolated, one 10,000-replication call needs about 11 GB of R heap and
about 14 GB of process memory, more than the laptop has: memory
exhaustion is the likely cause of the freezes (not confirmed). Two more
calls at nrep = 100 show what drives the growth: with n = 1,000 instead
of 250, peak memory was the same (382 MB); with 2,000 draws instead of
1,000, it rose to 484 MB. The draws matter; n much less.

**Decision.** Large power4mome simulations run in batches.

- `simulate_in_chunks()` splits the replications into the fewest batches
  of at most the backend's batch size, as equal as possible. The number
  of batches depends only on nrep and the batch size, never on the cores:
  the cores only run batches side by side (on small runs some cores are
  idle). Each batch is an ordinary `power4test()` call; only its
  rejection count and number of valid replications are kept before the
  next one. Rejections and valid replications are summed. This changes
  memory use, not the method. (Backends without a batch size still get
  one chunk per core.)
- Batch size (`power4mome_batch_size()`): 200 replications at up to 1,000
  draws per confidence interval, and proportionally fewer above that
  (100 at 2,000 draws, 40 at 5,000; at least 10). From the measurements,
  a batch of 200 at 1,000 draws needs about 0.5 GB of process memory
  (between the nrep = 100 and 500 rows), well under 1 GB; with 2 tests at
  once (the script's default) a laptop needs about 1 to 2 GB in all.
  Batching adds one `power4test()` call (model set-up) per 200
  replications, expected to be small against 200 replications of about
  1.4 s each; this overhead was not measured separately.
- Seeds: batch i (from 1) has seed `seed + i - 1`, as the per-core chunks
  had. With nrep at most the batch size, a run is still a single call
  that equals one direct `power4test()` call with the run's seed, on any
  number of cores.
- The direct-call validation helper `direct_power4mome()` uses the same
  batches and seeds (and spreads them over POWERKIT_CORES cores, as the
  engine does), so both sides of a direct-call test use the same approach.
  The direct-call validation tests therefore use identical simulated data
  for powerkit and power4mome: they check that powerkit passes the
  arguments correctly, not independent Monte Carlo agreement, which comes
  from the published-value tests.
- Provenance records `batch_size` (`NA` for backends that are not run in
  batches) and, as before, `cores`. The same seed, replications and batch
  size give the same result on any machine: results no longer depend on
  the cores. (A first version made one chunk per core when there were
  fewer batches than cores, so a small run could differ between 1 and 4
  cores: 10 replications in batches of 4 gave 7 rejections on 1 core, 8
  on 4. The maintainer chose to remove that dependence; idle cores on
  small runs are acceptable.) A unit test checks that 1 and 4 cores give
  identical results at 10 and 20 replications (batch size 4), forking on
  Linux (CI). The batch size itself depends only on the draws per
  confidence interval, not on the cores. The validation summary records
  the cores and cores per test ("Cores: 4 (4 per test)") and the package
  versions, including power4mome and manymome.

**Not bit-identical to earlier runs.** A batched run with a given seed
simulates different data sets from an unbatched run with the same seed
(batch 2 starts from seed + 1, not from where batch 1's random numbers
ended), so results differ from earlier runs within Monte Carlo error.
Runs with nrep up to the batch size (200 at 1,000 draws) on one core are
unchanged. (On several cores, such a run used to be split into one chunk per
core; it is now a single call, so its result changes too.) No recorded mediation validation result is affected: none had
been recorded (`docs/validation-log.md`).

**Validation on GitHub.** `.github/workflows/full-validation.yaml` runs one
chunk on demand on GitHub's standard runner (4 cores, about 16 GB), with
the package versions in `renv.lock`, and uploads `validation-results/`.
The mediation chunks run with `--cores-per-test 4` (new in
`scripts/run-validation.R`): one test at a time, its batches spread over
the 4 cores. With one core per test, a model 7 direct-call test (20,000
replications at about 1.4 s each) would take about 8 hours, longer than
GitHub's 6-hour limit. Estimated times on 4 cores, from one-core timings
on the laptop: process_4 about 2.5 hours (simple and parallel mediation
take about 0.4 s per replication), process_6 about 1 hour, process_7 and
process_14 about 3 hours each (model 14 not timed separately; assumed
like model 7). A runner core may be slower than the laptop's, so
process_7 and process_14 are the chunks most at risk of the limit. The existing workflows install packages from
`engine/DESCRIPTION`; this one uses `renv.lock`, so its versions match the
maintainer's machine. How to run it: `docs/validation-log.md`, "Running
the full validation on GitHub".

## 2026-10-15 · full-validation workflow: first run failed in setup (fixed)

The first run of `.github/workflows/full-validation.yaml` (chunk basic, on
main) failed while restoring packages: renv's check that igraph loads
failed with `libglpk.so.40: cannot open shared object file`. igraph's
Linux binary links to the GLPK library, which GitHub's Ubuntu runner
doesn't have. igraph is in `renv.lock` because manymome imports it, and
power4mome imports manymome. The other workflows install packages with
`r-lib/actions/setup-r-dependencies`, which uses pak and installs each
package's system requirements (here `libglpk-dev`) itself; renv's restore
doesn't. The workflow now installs `libglpk-dev` first. Every other
package in `renv.lock` with Linux system requirements (among them curl,
openssl, stringi, V8, fs) had already installed and loaded in that run,
so glpk was the only one missing.

A second error followed: the "Write the summary" step (which ran because
of `if: always()`) crashed with "missing value where TRUE/FALSE needed",
because the step that set `PER_TEST` had been skipped after the failure,
so `--cores-per-test ""` reached the script. Fixed in three ways:
`PER_TEST` is now set for the whole job (4 for the process_* chunks, 1
otherwise); the summary and upload steps run only if the chunk itself
started; and `scripts/run-validation.R` stops with a clear message if
`--cores` or `--cores-per-test` is missing a value or isn't a positive
whole number. The chunk itself had not run (steps without an `if` are
skipped after a failure); the workflow now also checks that the packages
load before starting it. The run step's own limit is now 5 h 30 m (was
5 h 40 m), leaving more of the 6 hours for setup and the upload.

## 2026-10-15 · Maintainer decisions: binary X and W phase

Decided by the maintainer. Recorded in the proposed phase in the build
guide, section 8. No code yet.

- **Effect sizes.** v1 uses fully standardised paths, following both
  backends: InteractionPoweR standardises binary variables after the
  split, and power4mome's `rbinary_rs()` rescales a 0/1 variable to mean 0
  and SD 1. A path from a binary X therefore means "per SD of X". Entering
  a condition effect as Cohen's d (Y standardised, X left as 0/1) comes
  later. It will be a departure, so it goes in `docs/conventions.md` with a
  test showing the size of any difference.
- **Group split.** 50/50 by default. Unequal groups only where the backend
  supports them (power4mome, through `rbinary_rs()`'s `p1`). Interactions
  are always 50/50, because InteractionPoweR splits at the median with no
  option for unequal groups, and the app should say so.
- **Binary X or W correlated with the other predictors.** power4mome
  requires a variable generated with `x_fun` (such as a binary X or W) to
  be uncorrelated with the other exogenous variables. That fits a
  randomised condition. A binary W correlated with X isn't supported, and
  the user should be told so plainly.
- **Timing.** This phase comes next: after phase 3 closes and before
  phase 4, because phase 4's methods paragraphs and scripts need to cover
  binary variables.

## 2026-10-15 · Published values: InteractionPoweR notes (comments only)

Checked by the maintainer. No expected values were changed.

- **Measurement-error example (Baranger et al., 2023, Fig. 6).** The method
  and package version behind the figure are not stated, and unlike Figs 2
  to 4 the supplement gives no app settings for it. InteractionPoweR
  0.2.4's `power_interaction_r2()` gives 0.591 at N = 940 (paper: 60%) and
  0.896 at N = 2,023 (paper: reaches 90%). The figures may be estimates from
  `power_estimate()` (a polynomial fit to a power curve) or from an earlier
  version of the function. Not precise enough to serve as a benchmark, so
  the test stays TODO (`test-validation-regression-interaction.R`,
  "interaction with measurement error").
- **Required-N example.** The published range of 3,501 to 3,750 is
  consistent with `power_interaction_r2()`, which gives 0.885 at N = 3,500
  and 0.905 at N = 3,750. The range itself is still for the maintainer to
  transcribe.
- **power4mome template tests.** The power4mome website was built with
  power4mome 0.2.1.31 (a development version); powerkit uses 0.2.1 from
  CRAN. This is noted next to the version line in each template test
  (simple mediation, PROCESS 7, PROCESS 14).

## 2026-10-15 · The prototype app (PR #4) stays a draft

The prototype Shiny app for the 2x2 designs (PR #4) stays an open draft. It
is kept as a starting point for phase 5 and is not merged now. Its bug
report (`validate_spec()` failed with "non-character argument" when
`population > sd` was `null`) was fixed in the engine: a null value in a
field that allows more than one type now gives a plain-English problem
(`engine/NEWS.md`; test in `test-validate-spec.R`). powerkit rejects a null
SD rather than reading it as "not given". In the 2x2 designs the SD is
required, so null is reported as a wrong type. In designs without an SD,
the field is reported as one that doesn't belong. Once this is merged, the
app's workaround (leaving blank numbers out of the spec) still works.

## 2026-10-15 · Project goal and coverage matrix

The maintainer's goal is now stated in the build guide's overview: one
place for psychologists to run the power analyses offered by Superpower,
Spower, power4mome, InteractionPoweR and G*Power, built on those tools and
crediting them, validated against them, with the full-model builder and R
script export for rare cases no form covers. `docs/coverage.md` inventories
those tools' user-facing capabilities against powerkit's status. Its tiers
are proposals for the maintainer to confirm. The G*Power rows could not
be checked against the manual in this session (the manual's host was not
reachable), so they are marked for checking.

## 2026-10-16 · Phase 4, part 1: script and citation exports

**What the exported script reproduces.** `export_script()` writes a script
that calls the backend package directly and repeats exactly what powerkit
did, so that with the same package versions it gives the same numbers, not
merely numbers within Monte Carlo error:

- the same seeds and the same split of replications into batches (one per
  core for Spower, Superpower and InteractionPoweR, whose results therefore
  depend on the number of cores; batches of at most `batch_size` for
  power4mome, which don't);
- for a sample-size goal, every sample size powerkit simulated, with its
  seed, and powerkit's probit fit to the ones it used. To make this
  possible, results now record each simulated n's seed, counts and whether
  it was in the final fit (`provenance$simulations`). powerkit's quicker
  first pass, which only chose the sizes, is not repeated;
- for exact 2x2 results, `ANOVA_exact()` under the run's seed
  (Departure 3); an exact required n is shown as the first of powerkit's
  curve sizes that reaches the target, the one before it not reaching it;
- for sensitivity, the same scaling of the pattern of means and the same
  `uniroot()` search.

The tests run each script with `Rscript --vanilla` (no powerkit, nothing
from the test session) and require agreement within the validation
tolerance and to 1e-10; on this machine every end point matched exactly.
They start a separate R session each, so they are skipped on CRAN.

**Writing the script surfaced a reproducibility bug (fixed).** For a model
with a product term (PROCESS models 7 and 14), `power4test()` standardises
the population by Monte Carlo (`psi_std_monte_carlo()`, 100,000 draws)
before `iseed` takes effect, from whatever state R's generator is in. In
powerkit that state was left by the previous call (the check run, the
previous batch or sample size), so a result depended on the order of calls
and, on Linux and macOS, on the number of cores (forked batches all start
from the parent's state). The script, run in a fresh session, couldn't
match (0.52 or 0.53 against powerkit's 0.51 in one test). powerkit now
runs every `power4test()` call under `set.seed(seed)` as well as
`iseed = seed`, and the exported script does the same. The simulated data
sets are unchanged (`iseed` still sets them); only the standardisation's
draws are now fixed. Results for models 7 and 14 therefore differ slightly
from earlier runs with the same seed, including the full validation runs
of 16 October 2026; models without a product term are standardised
analytically and are unchanged. The direct-call helper used by the
validation tests seeds the same way.


## 2026-10-16 · Maintainer follow-up on PR #20: seeding, validation status, citation rule

**(a) The seeding fix, and a guarantee that didn't hold until now.** PR #10
(running power4mome simulations in batches, above) recorded that "the same
seed, replications and batch size give the same result on any machine". For
PROCESS models 7 and 14 (E13, E14) that didn't hold until the seeding fix
above: `power4test()` standardises a model with a product term by Monte
Carlo before `iseed` takes effect, from whatever state R's generator is in,
so results depended on earlier calls in the session and, on Linux and
macOS, on how batches were shared out over cores. It holds now: every
`power4test()` call runs under `set.seed(seed)` as well as `iseed = seed`.
For models without a product term (E10–E12) it always held: their
standardisation is analytic. Because the fix changed E13's and E14's
numbers slightly, the 16 October validation runs no longer validate the
current code; both are back to "Runs, validation in progress" until
process_7 and process_14 are rerun on GitHub after merge
(`docs/validation-log.md`). E10–E12 stay validated (identical results).

**(b) Citation rule (maintainer's decision).** Citations come only from
`inst/citations/refs.bib` or a package's own `citation()`; no reference is
written from memory. CLAUDE.md and the build guide now say so. In practice:

- the citations export gives the backend's `citation()`, its method paper
  from refs.bib, powerkit's citation, and a "software used" section with
  the supporting packages that do real work underneath, each from its own
  `citation()`: SimDesign (Spower's simulations); afex (`aov_car()`, which
  fits Superpower's ANOVAs) and MASS (`mvrnorm()`, which generates its
  data); lavaan (model fits) and manymome (indirect effects and their
  confidence intervals) for power4mome; none for InteractionPoweR, which
  uses base R; and R itself (`citation()`). These were found in the
  backends' sources (`Spower()` calls `SimDesign::runSimulation()`;
  Superpower's `ANOVA_exact()` and `ANOVA_power()` call `aov_car()` and
  `mvrnorm()`; power4mome imports lavaan and manymome). Superpower also
  calls emmeans for its pairwise comparisons, which powerkit doesn't
  report, so emmeans isn't listed;
- refs.bib entries are copied from the installed package's `citation()`
  (`toBibtex()`), with the package and version noted. Superpower 0.2.4.1
  and InteractionPoweR 0.2.4 give method papers (Lakens and Caldwell, 2021;
  Baranger et al., 2023, the first of InteractionPoweR's two entries).
  Spower 0.6.4 and power4mome 0.2.1 give only their manuals, so their
  method-paper keys stay placeholders; powerkit's own citation is a
  placeholder until the maintainer decides how powerkit is cited. A test
  checks every refs.bib entry's DOI against its package's `citation()`.

## 2026-10-16 · Why power4mome for mediation and moderated mediation

**Why it is used.** powerkit runs simple, parallel and serial mediation
and first- and second-stage moderated mediation (PROCESS models 4, 6, 7
and 14) through power4mome:

- **It is built on established packages.** Its own DESCRIPTION says it
  fits models with lavaan (Rosseel, 2012) or multiple regression and uses
  manymome (Cheung and Cheung, 2024) to specify and test the indirect and
  conditional indirect paths. Both papers are what `citation("lavaan")`
  and `citation("manymome")` give; they are listed in the citations
  export's "software used".
- **It is actively maintained.** The `power4mome.bz` bug powerkit
  reported on 13 October 2026 was confirmed and fixed on GitHub the next
  day (`docs/conventions.md`, Departure 8). Its CRAN release, 0.2.1, was
  published on 24 March 2026 (its DESCRIPTION).
- **It fits the designs.** It covers mediation and moderated mediation
  with observed variables, Monte Carlo and bootstrap confidence intervals,
  and the index of moderated mediation (`test_index_of_mome()`). It also
  has binary exogenous variables through `x_fun`, which phase 3b needs.

**Established alternatives** (listed neutrally; none is ruled out):

- **simsem** (Pornprasertmanit, Miller, Schoemann and Jorgensen; CRAN
  0.5-17, published 2 April 2025): "an easy framework for Monte Carlo
  simulation in structural equation modeling", including power analysis
  (its DESCRIPTION). General-purpose: the user writes the generating and
  analysis models.
- **pwrss** (Bulus and Jentschke; CRAN 1.3.3, published 14 October
  2026): power for many common tests, including the indirect effect in
  simple mediation (`power.z.mediation()`: Sobel-type z tests, the joint
  test and a Monte Carlo interval test) from normal-theory formulas,
  without simulating data.
- **Mplus**: commercial SEM software with a Monte Carlo simulation
  facility often used for mediation power analysis. **Unsourced**: not
  checked against Mplus's documentation here.

Some statisticians would prefer longer-established tools, such as Mplus
or simsem, to power4mome. That is a reasonable position, and powerkit
doesn't argue it away with power4mome's reputation or its authors'.
**The evidence relied on is the cross-check:**
power4mome's results for simple mediation are compared with pwrss and
simsem in the `mediation_crosscheck` validation chunk
(`docs/validation-log.md`, "Independent cross-check for mediation").
Until that chunk has passed, power4mome is validated only against
itself (direct calls) and Type I error. The cross-check covers simple
mediation only; parallel, serial and moderated mediation have no
independent check yet.

## 2026-10-16 · Routing prototype: maintainer decisions from PRs #21 and #22

Three items those PRs left for the maintainer, decided on 16 October 2026.
App and docs only; the engine is unchanged.

- **E15 (moderated regression with a yes/no X or W) doesn't ask the
  reliability question (Q-rel).** This is an exception to "reliability for
  regression interactions" in `decision-tree.md` ("Closing questions by
  card"). **Reason:** misclassification in a 0/1 variable is a different
  problem from unreliable scores, so a reliability coefficient isn't the
  right input for it. Q-rel stays on E9 (both X and W scores). The engine's
  spec still accepts `variables.*.reliability` for regression interactions
  of any type; whether it should refuse it for a binary X or W is for the
  engine, not this change. The worked example's H2 row (moderated
  regression with a yes/no condition) no longer lists reliabilities.
- **Flag F11 (test–retest reliability):** the routing audit now says that
  a test–retest study entered as a relationship reaches E41 after S3's
  "Twice", and E4 only after "Once". Routing unchanged.
- **Flag F7 (IRT):** the routing audit now says IRT reaches E37 through
  Q1's "a questionnaire structure" answer. E37 gains one line: "This card
  is about confirmatory factor analysis (CFA) and structural equation
  models (SEM). Item response theory (IRT) designs aren't covered."
  Routing unchanged.

## 2026-10-17 · Routing prototype: the two contradictions from PR #24

Decided by the maintainer on 17 October 2026. App and docs only.

- **E7 and E8: "Exact dataset (no repeated simulation)"** replaces
  "Exact (analytic)" as the default method and in the Q-test note.
  **Reason:** Superpower's help says `ANOVA_exact()` "Simulates an exact
  dataset (mu, sd, and r represent empirical, not population, mean and
  covariance matrix)", and Superpower keeps "analytic" for other
  functions. The new wording follows the package.
- **E45: "A recently released package addresses the known-breakpoint
  case; powerkit hasn't checked it."** replaces "No ready-made tool".
  **Reason:** PITS 0.1.0 (CRAN, 30 June 2026) estimates power for
  interrupted time series with a known breakpoint. The card doesn't name
  it until open question 18 (naming other tools) is decided; PITS is
  recorded in `card-sources.md` and `judgement-calls.md`.
- **Two papers supplied by the maintainer** were read: Zhang, Wagner and
  Ross-Degnan (2011) and Albers and Lakens (2018). The second supports the
  reason given for the pilot-study warning. The first qualifies E45's
  autocorrelation point: power falls as positive autocorrelation rises,
  but negative autocorrelation raises it. That point was first left
  unchanged and marked "contradicted" in part, for the maintainer.
- **E45's autocorrelation point (maintainer, 17 October 2026, later the
  same day):** now reads "Autocorrelation makes standard power
  calculations wrong: too optimistic when it's positive, too pessimistic
  when it's negative." Sourced to Zhang, Wagner and Ross-Degnan (2011),
  Table 1 (effect size 0.5, N = 24: power 0.25 with no autocorrelation,
  0.18 at +0.5, 0.43 at -0.5). The contradiction is resolved; no
  contradictions remain open in `card-sources.md`.

## 2026-10-17 · Validation reruns, and refs.bib entries verified at their DOI

**E13 and E14 validated again.** The process_7 and process_14 chunks were
rerun on GitHub on the merged seeding fix (commit 4b63d5f). Both passed,
and their only skips are published-value tests with
`TODO_PUBLISHED_VALUE` (`docs/validation-log.md`, 17 October 2026). The
reruns supersede the 16 October runs, so E13 and E14 are `runs_validated`
again.

**First run of the mediation cross-check.** All 4 tests ran and passed.
The numbers are in `docs/validation-log.md` ("Results of the first run").

**Cross-check allowance (the maintainer's decision).** 0.02, for
comparisons with pwrss only, at n >= 100. pwrss treats the standard errors
as known, so its power comes out slightly higher than simulated power: all
six simulation-vs-pwrss differences in the first run were negative (0.005
to 0.017). simsem shows the same gap against pwrss as power4mome does, so
the gap comes from the formula side, not from power4mome. With no
allowance, the comparison would often fail by chance on reruns (at n = 100
the gap already exceeds the Monte Carlo-only tolerance); with 0.02 there
is about 4 standard errors of headroom. Comparisons between two
simulations (power4mome vs simsem) have no allowance. Below n = 100 the gap
is likely larger and nothing is decided: `crosscheck_allowance(n)` stops
there.

**refs.bib: a second route for entries (the maintainer's rule).** The
rule is "refs.bib or the package's own `citation()`", but the test
accepted only entries copied from a package's `citation()`. It now also
accepts an entry whose DOI a session actually opened, if the entry has a
`note` field saying where and when it was verified. The note starts with
"Verified" and has an ISO date (not in the future) and the URL opened, for
example `note = {Verified 2026-10-17 at https://doi.org/10.1234/abcd}`.
The maintainer approved this format on 17 October 2026.
An entry with neither a matching `citation()` DOI nor such a note fails
the test. Neither the text nor the BibTeX citations export prints the verification
note: it is provenance, not part of the reference (maintainer's decision,
17 October 2026). No entries were added.

## 2026-10-17 · CI installs packages from renv.lock

**What happened.** Spower 0.7 reached CRAN on 16 October 2026 with the
one-sided fix powerkit reported. R-CMD-check, nightly-validation and the
routing prototype's app-tests installed the latest CRAN versions (from
`engine/DESCRIPTION`), so CI picked up Spower 0.7 straight away. The
engine's departure test for one-sided tests (Departure 4), written against
Spower 0.6.4's behaviour, then failed, and CI was red on every PR.

**Decision (maintainer, 17 October 2026).** Every workflow installs the
package versions in `renv.lock`, as full-validation already did
(`r-lib/actions/setup-r` with `r-version: renv`, then
`r-lib/actions/setup-renv`). A new release of a backend can then change CI
results only through a PR that updates `renv.lock`, where the change can
be checked. This follows the project rule that CRAN versions are pinned,
with powerkit's workarounds, until a fix reaches CRAN and is adopted in
its own PR.

- Spower stays at **0.6.4** for now, so behaviour doesn't change. Moving
  to 0.7 (and removing the one-sided workaround and Departure 4) is a
  separate PR that waits for the maintainer's approval.
- **pwrss 1.3.3** and **simsem 0.5-17**, the versions the mediation
  cross-check used, are pinned in `renv.lock` (already recorded there).
- `rcmdcheck`, which only runs R CMD check, isn't in `renv.lock`; the
  R-CMD-check job installs it on top.
- The nightly job now runs the tests with `testthat::test_local()` instead
  of `devtools::test()`, so it doesn't need devtools (not in `renv.lock`).
- app-tests now restores the whole of `renv.lock`, engine packages
  included, so it takes longer on the first run (later runs use a cache).

## 2026-10-17 · Who merges PRs

**Arrangement (maintainer, 17 October 2026).** For this stretch the
Claude session that owns the routing prototype also owns `engine/`,
`renv.lock` and the workflows, and may merge PRs itself under these rules:

- merge only when every CI check is green;
- squash and merge, one PR at a time; before merging the next one, update
  its branch from main and resolve any conflicts;
- check that each PR's changed files match what its description says it
  changes;
- **exception:** a PR that changes statistical behaviour (results, the
  tests used, defaults, departures) waits for the maintainer's explicit
  yes. Its evidence is posted on the PR first. At the time of writing this
  covers only the Spower 0.7 / Departure 4 PR.

## 2026-10-17 · Spower 0.7: Departure 4 retired

**Waits for the maintainer's yes** (it changes which test code runs, so it
falls under the exception in "Who merges PRs" above).

**What changed upstream.** Spower 0.7 reached CRAN on 16 October 2026.
It ships no NEWS file (checked: none in the CRAN package, the CRAN page or
r-universe), so the changes were read by comparing the 0.6.4 and 0.7 source
packages from CRAN file by file. Changed R files: `p_t.test.R`, `p_r.R`,
`p_2r.R`, `p_prop.test.R`, `p_ks.test.R`, `p_var.test.R`,
`p_wilcox.test.R`, `p_scale.R`, `p_anova.test.R`, `p_mcnemar.test.R`,
`p_mediation.R`. Nothing else in `R/` changed (`Spower()`, the generators
and SimDesign calls are as in 0.6.4).

- One-sided tests: each of the first eight gains `alternative`, passed to
  the underlying test; `two.tailed = FALSE` now means
  `alternative = "greater"` (`"less"` in `p_scale()`); the halving line
  `p <- ifelse(two.tailed, p, p/2)` is removed.
- `two.tailed` is removed from `p_anova.test()`, `p_mcnemar.test()` and
  `p_mediation()` (it now falls into `...`). powerkit doesn't use these.
- `p_var.test()` now stops for a one-sided Fligner test or more than two
  groups. powerkit doesn't use it.
- Spower's own test file changes some expected values in tests run with
  `parallel = TRUE, ncores = 2`. powerkit always calls Spower with
  `parallel = FALSE` (it batches replications itself), so these don't
  apply.

**Decision.** Following the rule that CRAN versions are pinned with
powerkit's workarounds until the fix reaches CRAN: `renv.lock` moves to
Spower 0.7, `engine/DESCRIPTION` requires `Spower (>= 0.7)`, and
powerkit's own one-sided test (`spower_one_sided_p()`) is removed. One-sided
basic tests call Spower's `p_t.test()`, `p_r()` or `p_prop.test()` with
`alternative`, mapped to Spower's orientation by `spower_alternative()`.
Spower compares group 1 with group 2, and powerkit passes the effect with
its sign reversed, so powerkit's `"greater"` is Spower's `"less"` for
two-sample, paired and two-proportion tests. Passing `two.tailed = FALSE`
would therefore have tested the wrong direction for those three templates;
the mapping test guards this.

**Evidence.**
- Same seeds, old code with Spower 0.6.4 vs new code with Spower 0.7: identical power in all 10 one-sided cases
  (five templates x "greater"/"less", 2,000 replications) and all 6
  two-sided cases, including the wrong-direction ones.
- The new test "one-sided tests: powerkit and Spower's own one-sided test
  agree":
  - with no effect, powerkit 0.047 equals Spower's `alternative = "less"`
    call (0.047; Spower 0.6.4's halved p-value gave about twice alpha);
  - with d = 0.5 in the tested direction, 0.798 and 0.798;
  - with the effect in the wrong direction, 0 for powerkit and 0 for
    Spower's `two.tailed = FALSE`.
- **Validation to rerun after merging:** the `basic` chunk (the only chunk
  that uses Spower). Results go in `docs/validation-log.md`.

## 2026-10-17 · Basic tests (E1–E6): pwr's exact formula by default

**Decision (maintainer, 17 October 2026).** For E1–E6 the default
calculation is the analytic formula in the pwr package, not Spower
simulation. Spower simulation stays available for E1–E6 when the user says
their data won't meet the test's assumptions (`options > method =
"simulation"`; on the input screen, "How power is worked out"), and is used
for a test the formula doesn't cover: Welch's t-test. E7–E14 are unchanged.

**Reason.** Exact where an exact answer exists; no Monte Carlo noise for
simple designs. A formula gives the same answer every time and needs no
seed, interval or replication count.

**This is a departure** from using Spower as the default for E1–E6
(recorded as Departure 9 in `docs/conventions.md`, shown on the result
screen, and covered by a test showing the size of the difference).

**What changed.**
- Engine: a new backend, `pwr` (`engine/R/backend-pwr.R`), with one pwr
  call per template: `pwr.t.test()` (one-sample, paired with d_z, and
  two equal groups), `pwr.t2n.test()` (unequal groups), `pwr.r.test()`,
  `pwr.2p2n.test()` with Cohen's h, and `pwr.chisq.test()` with Cohen's w
  and df = (rows - 1)(columns - 1). The required N is the smallest valid
  total N whose power reaches the target. pwr moves from Suggests to
  Imports; it was already in `renv.lock` (1.3-0) for the validation tests.
- Two of these formulas are approximations rather than exact: the
  correlation (Fisher's z) and two proportions (the arcsine
  transformation, Cohen's h). The t-tests and the chi-square test use the
  noncentral t and chi-square distributions. The decision's "exact where an
  exact answer exists" applies to the t-tests and chi-square; for r and two
  proportions pwr's formula is deterministic but approximate (pwr's help
  pages for `pwr.r.test()` and `pwr.2p2n.test()`).
- Exports: the R script calls pwr directly; the citations export credits
  pwr from its own `citation()`.
- Validation: the analytic path must match pwr directly, and the G*Power
  published values once transcribed, to 3 decimal places (no Monte Carlo
  tolerance; `expect_power_exact()`). The direct-call and Type I error
  tests now ask for simulation, so they still check the Spower path.
- Cards, card sources, `decision-tree.md` table 2.3 and the walkthroughs
  name pwr as the default for E1–E6.

**Open question for the maintainer.** Spower's simulation draws normal
data, so as wired it checks the same assumptions as the formula; it gives
the same answer up to Monte Carlo noise. Simulating data that don't meet
the assumptions (for example skewed scores or unequal variances) would
need the user to describe how, which the spec can't hold yet. Recorded in
`judgement-calls.md` (B16).

## 2026-10-17 · The maintainer's decisions on G4–G6 and the Spower flag

**G5: actual power at the rounded N (yes).** When powerkit reports a
required N, the result screen also shows the power that N actually
gives, in a plain sentence: "With 64 per group, power is 80.1%." It
appears for exact results (pwr and Superpower's exact dataset), where the
engine's `curve` holds the exact power at the reported N. A simulated N
comes from a fitted curve with no simulation at exactly that N, so
nothing is shown for it (powerkit's default; judgement-calls.md G5).

**G6, E4: keep pwr's Fisher's z method.** Recorded as Departure 10 in
`conventions.md`: G\*Power uses the exact distribution of r. For
r = .3 to .5 and N = 20 to 100 (two-sided, alpha .05) the power differs
by at most 0.004, and the required N by at most 1 (85 rather than 84 at
r = .3). Shown on E4's card and on the result screen; a test checks the
size.

**G6, E5: match the test most psychologists run.** The default should be
the z test (or chi-square) for two proportions, not the arcsine
transformation. powerkit is to check base R's `power.prop.test()` against
G\*Power's "Two independent groups: inequality, z-test" before changing
anything; that change waits for the maintainer's yes.

**G4 (what the methods paragraph reports):** left for the maintainer's
judgement session.

**Spower: one-sided tests against a non-zero null correlation.** In
Spower 0.7, `p_r()` replaces the p-value when `rho != 0` with
`pnorm(abs(t), lower.tail=FALSE)*2` (`R/p_r.R`, line 75), which is
two-sided whatever `two.tailed` or `alternative` says. With `rho = 0`
the p-value comes from `cor.test()` and follows `alternative`. powerkit
doesn't use a non-zero null correlation, so nothing is affected. The question
is listed in `upstream-questions.md` (not yet raised).


## 2026-10-17 · E5: G\*Power's z test by `power.prop.test()` (waits for the maintainer's yes)

**What the maintainer asked.** Make base R's `power.prop.test()` the E5
default if it agrees with G\*Power's z test, keep pwr's arcsine (Cohen's
h) as an option, record the reasoning here, and wait for a yes before
merging (decision G6, above).

**The check.** The maintainer's G\*Power 3.1.9.7 screenshots (z tests,
"Proportions: Difference between two independent proportions", default
options: no continuity correction, no arcsine transformation) agree with
`power.prop.test(strict = TRUE)` to the seven decimals G\*Power shows:
0.2344921 at 20 per group (p1 = .10, p2 = .25, two-sided, alpha .05);
164 per group for 95% power, actual power 0.9502464. With
`power.prop.test()`'s default, `strict = FALSE`, the first is 0.2339595,
so G\*Power counts both tails and powerkit passes `strict = TRUE`.
Details: `gpower-parity.md`, E5; `conventions.md`, Departure 11.

**Reasoning.** Most psychologists analyse two proportions with the z test
or the uncorrected chi-square, which are the same test two-sided; the
arcsine formula answers a slightly different test (judgement call G6:
up to 0.018 in power and 3 per group). `power.prop.test()` is base R,
whose help and source say what it computes, and it reproduces G\*Power
exactly for equal groups, so no new maths is written.

**What the build does (draft PR).** Equal groups: `power.prop.test(strict
= TRUE)`, the backend recorded as stats. Unequal groups:
`power.prop.test()` takes one n for both groups, so pwr's Cohen's h is
used, as before, and Departure 11 states the size (N2/N1 = 2, 95% power:
360 rather than G\*Power's 370). The user can choose Cohen's h on the
input screen (`options > proportions_formula = "arcsine"`). A one-sided
test against the specified difference uses the two-sided power at 2 ×
alpha minus the one-sided power, because `power.prop.test()` uses
|p1 − p2|.

**Open for the maintainer:** the yes to merge, and what unequal groups
should use (Cohen's h as built; Spower's simulation of the same z test;
or pwrss's `power.z.twoprops()`, which reproduces G\*Power's power at 123
and 247 but isn't one of the foundation tools).

**Decided (maintainer, 17 October 2026):** yes to merge. The validation
test that compared E5 with Cohen's h now takes G\*Power's z-test output
as its reference (0.2344921 at 20 per group, p1 = .10, p2 = .25, both
tails), recorded as a G\*Power value with its inputs, not a published
value; a separate test covers the Cohen's h option. Unequal groups: see
"E5: unequal groups by pwrss".

## 2026-10-17 · E5: unequal groups by pwrss (waits for the maintainer's yes)

**Decided (maintainer, 17 October 2026):** unequal groups use pwrss's
`power.z.twoprops()` (option C). Reason, in the maintainer's words: Cohen's
h under-estimates N at unequal splits (360 against G\*Power's 370 at
1 : 2), which would leave studies underpowered, the wrong direction for a
default; Spower would bring back simulation noise where an exact answer
exists. pwrss is already pinned in `renv.lock` (1.3.3) for the mediation
cross-check. It moves from Suggests to Imports and is credited as a
foundation tool wherever the others are (README, citations export from
its own `citation()`, card text, `card-sources.md`), and the exported R
script calls it for this case.

**Built (draft PR):** `power.z.twoprops(std.error = "pooled", verbose =
FALSE)` with `n2` and `n.ratio = n1 / n2` from the spec's groups. It
reproduces G\*Power's 0.9498668 at 123 and 247. Group sizes keep the
exact ratio, so powerkit's required N for 95% power at 1 : 2 is 372 (124 +
248), where G\*Power gives 370 (123 + 247, power 0.9498668, just under
the target): recorded in Departure 11. pwrss's values at 1 : 1, 1 : 2
and 1 : 3 in both directions are tested, and the maintainer's G\*Power
screenshots for those inputs (and one tail, and a priori at 1 : 3) match
them to 7 decimals (`docs/gpower-parity.md`, E5).

## 2026-10-17 · Phase 5, part 2: E10–E14

**Decided (maintainer, 17 October 2026):** for mediation power at a fixed
N (E10–E12), a quick preview of about 100 replications shown as a range,
then the full run at the app's defaults in a separate process with a
progress indicator and Cancel, as for E9, with the expected wait stated
before it starts (options B then A). For a mediation required N and for
moderated mediation (E13, E14, any goal), the same preview, then "Download
R script to run the full analysis on your computer" with the expected run
time and what to install (B, then D); no full in-browser run for these
yet. Background jobs (C) are not built: deferred until hosting and cost
are decided. Fewer replications (E) is not a default. The preview and the
full run use recorded seeds; tests check that the full run equals
`run_spec()` with the same spec and seed and that the downloaded script
reproduces it.

**Reasons:** a preview lets users see within a minute or two whether
their effect is in a sensible range before a long run, but at 100
replications it is too imprecise to report, so it is shown as a range
with a warning and can't be exported. A wait of about 10 minutes in the
browser is acceptable for mediation power; hours (a mediation required N)
or about 25 minutes (moderated mediation) are not, so those run on the
user's computer. Background jobs need hosting and someone to pay for
computing time, which aren't decided.

**Built:** details, times and tests in
[`phase5-simulations.md`](phase5-simulations.md), "Decided". Two engine
functions were added: `export_run_script()` (the script for a spec, with
its seed, that calls `run_spec()`) and `power_interval()` (the exact
binomial range for simulated power, from base R's `binom.test()`).

**One change from the plan (approved by the maintainer, 18 October
2026):** a required N has no preview and goes straight to the R script.
**Reason:** the 100-simulation search couldn't settle on an N. With 100
replications per sample size the search took over 15 minutes for simple
mediation and stopped with "could not pin down the required n"
(`phase5-simulations.md`, "A required N has no preview").

## 2026-10-17 · Attrition: the number to recruit

**Decided (maintainer, 17 October 2026):** apply `options > attrition`.
N to recruit = N analysed / (1 − attrition), rounded up per group (each
group's, or each cell's, analysed size is divided and rounded up, then
added up). The result screen shows both numbers, "Analysed" and "To
recruit", with a one-line caveat that this is a common but crude heuristic
that ignores how missing data are handled (Mikael Rubin, 2025,
*International Journal of Psychology*, doi:10.1002/ijop.70017; in
`refs.bib`). The exported R script works it out too, and checks it against
powerkit's number.

**Why dividing, not multiplying:** dividing by 1 − attrition leaves the
analysed N once the expected share is lost (100 analysed at 20% attrition:
125 recruited, 25 lost). Mikael Rubin (2025, p. 14 of 15) gives the
multiplying version (100 × 1.2 = 120) as an example of the heuristic; it
leaves 96 after 20% attrition.

**Built:** `run_spec()` returns `recruitment` (attrition, n analysed and to
recruit, and each group's), `NA` without attrition. For a sample-size goal
it starts from the required N; for power and sensitivity, from the N
entered (which is the number analysed: `goal > n`).

## 2026-10-17 · Sources the maintainer checked in full text

**Decided (maintainer, 17 October 2026):** the verification-note rule for
`refs.bib` also accepts "Verified YYYY-MM-DD from full-text PDF held by
the maintainer", for a source the maintainer has checked in full text
(the PDFs aren't committed). The test in `test-export-citations.R`
accepts it. Added on that basis, with fields copied from the PDFs:
- Rubin (2021, *Synthese*): the individual, disjunction and conjunction
  framework and the .80 × .80 = .64 conjunction example (p. 7). The
  maintainer's copy is the author preprint, so volume and pages are as
  printed in Rubin (2024)'s reference list;
- Rubin (2024, *Methods in Psychology*): section 7 covers sensitivity
  analysis, justified alpha and one-sided tests;
- Mikael Rubin (2025, *International Journal of Psychology*): Table 1
  names MLMPower, Longpower, PowerLMM, MixedPower and SimR, and it cites
  Dziak et al. (2020);
- Frane (2019): as printed in Rubin (2024)'s reference list. Frane's own
  text was not read.

Still candidates, not in `refs.bib`: Dziak et al. (until its published
version is checked), Lakens et al. (2018), Hoenig and Heisey (2001) and
the G\*Power manual.

**`stats_method` and `pwrss_method`:** the maintainer asked for them to
be filled from the packages' own `citation()`, under the rule that a
method paper `citation()` doesn't give stays a placeholder. Checked on
17 October 2026: `citation("pwrss")` (1.3.3) gives only the package
manual (Bulus and Jentschke, 2026), and `citation("stats")` gives R
itself (R Core Team). Neither names a method paper, so both stay
placeholders; the citations export already lists each package's own
`citation()`.

## 2026-10-18 · Wave 2: smallest N for exact tests of counts

**Known difference, not a departure.** For one proportion and McNemar,
powerkit reports the smallest N that reaches the target power (90 and
129 in the examples). The maintainer's G\*Power screenshots report the
same N; only pwrss's own sample-size answer differs (92 and 130). The
maintainer decided (18 October 2026) to record it as Known difference 2
in `conventions.md`, not as a departure, and approved PR #51 (wave 2
engine groundwork).


## 2026-10-18 · The new design

**Decided (maintainer, 18 October 2026):** powerkit's flow becomes four
screens. The design document (18 October 2026) is held by the
maintainer; this entry records what was agreed. It settles judgement
calls B4, G7, G8 and G9 and parts of A1, B2, B5, B6, B10, B11, B13 and
D2 (`judgement-calls.md`; the settled ones are in
[`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md)).

**The four screens.**
- **A. Start:** three short questions on one screen: the situation (I
  can choose N, or N is fixed), the aim and the claim.
- **B. Find your design:** the design finder. How screen A becomes the
  start of a design profile is the first item of
  [`judgement-session.md`](judgement-session.md)
  ([`routing-design-options.md`](routing-design-options.md), "Screen A as
  the start of the profile").
- **C. Inputs, with the effect size at the centre:** the design's inputs,
  target power, and the effect-size source with a short rationale.
- **D. Result, explore, write-up:** N, or on the fixed-N route the
  smallest detectable effect; a plain reading; an explore panel; a short
  and a full write-up.

**Decisions 1 to 9 (yes as recommended, with the maintainer's changes):**
1. **The four-screen design is the direction.** Screen A's claim
   question has four options, each with a one-line psychology example:
   - one test;
   - several claims, each standing on its own (Rubin's individual
     testing; the most common case): each test is powered separately,
     with no correction;
   - any of several (disjunction): the screen says plainly that this
     claim is about the set, not about each test;
   - all of several (conjunction).
2. **A rationale is required only to save or export,** not to explore.
   No minimum length, any language, one per design, optional notes per
   parameter.
3. **Target power has no silent default.** Screen C shows .80 and .95
   side by side with the N each needs and asks which and why. Alpha stays
   .05 two-sided by default, with a reason asked only if it is changed.
4. **"Any of several": Bonferroni in v1** (alpha divided by the number of
   tests, with the reason shown). Holm later if wanted.
5. **"All of several": guidance only,** no computed joint power. The
   chance that all succeed is lower than any one test's power (for
   example, .90 × .90 = .81 for two independent tests). Tests on the same
   people are usually positively correlated, so the product is roughly a
   floor, not exact.
6. **The explore panel is kept apart from the plan.** If the plan's
   effect size is changed, its source is flagged "does this still
   apply?", not wiped. Formula designs only in v1.
7. **The aim question is asked directly.** "Estimating how big something
   is" is an equal option; in v1 it points to MBESS and Spower's precision
   criterion (`coverage.md`). A third option, "showing there's no
   meaningful effect" (equivalence, TOST), points to established tools
   (`coverage.md`) until powerkit supports it.
8. **A test bans verdict words** ("justified", "approved", "adequate",
   "sufficiently powered") in the output templates, not in every card.
9. **An opt-in, local calculation history,** off by default.

Further changes from the maintainer:
- **Plain reading:** "would get a significant result", not "would find
  it": "If the true effect is d = 0.5, about 8 in 10 studies like this
  would get a significant result."
- **"I can't justify an effect size"** when N isn't fixed doesn't force
  the fixed-N route. It shows the smallest detectable effect across a
  range of N (a sensitivity curve), at .80 and .95 power.
- **Direction:** the two-sided default stays for now. Asking "Do you
  predict a direction?" instead is an open call (`judgement-calls.md`, B18).
- **Sources for the app:** no statistic from Vankelecom et
  al. (2025), Schäfer and Schwarz (2019), Bakker et al. (2016) or Devezer
  et al. (2021) appears in the app until it is checked in the
  full text with page numbers. Until then each stays a candidate. (A
  full-text check of 18 October 2026 corrected several figures. Schäfer
  and Schwarz and Devezer et al. now have page numbers from the
  maintainer's PDFs; Vankelecom et al. and Bakker et al. still need them.)

**Decision 10** (interactions' fixed-N route by the fast fixed-model
approximation, labelled): **decided 19 October 2026**, the fast
fixed-model formula (`power_interaction_r2()`), labelled on the result
screen, in the methods sentence and in the R script (maintainer's choice
on the thread's decision card; built in PR #76). Simulation stays the
method for sample size and power.
**Decision 11** (a clickable mock for presentations): dropped.

**Build order (one PR each; each user-visible PR needs the maintainer's
yes):**
1. Engine: the smallest detectable effect for E1–E6 (PR #56).
2. Docs: this entry and the judgement calls it settles.
3. Honesty fixes on the result screen: Departures 6, 7 and 8 and Known
   difference 1 (`conventions.md`).
4. App: screen A and the fixed-N route for E1–E8, with the sensitivity
   curve.
5. App: effect-size source and rationale, and a minimal verbatim
   write-up (needs a minimal G4 decision).
6. App: the plain reading, the .80/.95 cost line and the verdict-word
   test.
7. App: the explore panel.

## 2026-10-18 · What the methods paragraph reports (judgement call G4)

**Decision (maintainer, 18 October 2026, agreeing with Claude's
recommendation).** The write-up states the test and its sides; alpha; the
target power and the user's reason for it (a new optional field); the
effect size with the user's reasoning, word for word (and any adjustment);
N in total and per group, with the power reached at that N; the number to
recruit when attrition is given; how a claim over several tests was
handled; the backend, its version and function, powerkit's version and R;
the seed and the number of simulations where power is simulated; and the
departures. It leaves out the noncentrality parameter and critical value:
the inputs are enough to repeat the calculation, most backends don't return
them, computing them would be new maths, and the R script reproduces the
result exactly.

**Two versions.** A short one for the paper and a full one for a supplement
or preregistration. The short version says that departures are described
in the supplement; the full version states each one, plus the spec hash,
the seed and the check run. Regression interactions carry the methods
sentence for Known difference 1 (`conventions.md`) in both. Both are
editable text on the result screen and, like saving, need the reasoning.

## 2026-10-18 · Hosting for testing: Posit Connect Cloud

**Decision (maintainer, 18 October 2026, on Claude's recommendation).**
The app goes online for the first round of user testing, so testers open
a link instead of installing R. It needs an R server because Spower
doesn't install in webR (`hosting-options.md`). The maintainer first chose
shinyapps.io, then moved to Posit Connect Cloud because shinyapps.io is
closing to new apps at the end of 2026 and moving its users there (the
maintainer's note; the date is from a search result, unchecked). Same
deploy route from R (rsconnect 1.6.0 or later). The maintainer deploys
with `scripts/deploy-online.R`. Prices and limits are to check on the
account page; mediation runs may be slow on a small instance.

## 2026-10-19 · Chi-square goodness of fit gets its own card (judgement call 3.7)

**Decision (maintainer, 19 October 2026, on Claude's recommendation).**
The chi-square goodness-of-fit test (one categorical variable against
expected proportions) is its own card, E48, not part of E6 (the test of
independence). They answer different questions, and a separate card keeps
each screen simple. It runs on pwrss's `power.chisq.gof()`, with equal
proportions under the null unless the user gives others.

## 2026-10-19 · Test direction and "all of several" claims (waits for the maintainer's yes)

Three changes to the input screen. They replace parts of decisions 3 and
5 of "The new design" (18 October 2026). The individual, disjunction and
conjunction framework of the claim question is unchanged (Rubin, 2021,
`Rubin2021_alpha`).

1. **Direction is asked, not pre-filled.** For tests that can be
   one-sided, the first question is "Does your hypothesis predict a
   direction?", with no default; the packages' two-sided default is named
   under it. Reason: a two-sided p-value does not support a directional
   claim, so the test should follow from the hypothesis (Rubin, 2022,
   *Significance*; `Rubin2022_twosided`; see also Rubin, 2024, *Methods in
   Psychology*, `Rubin2024_inconsistent`, section 7). Not a departure: the
   test run is whichever the user picks, by the packages' own options.
2. **"All of several": plan for the joint chance.** A conjunction claim
   needs no alpha correction (intersection-union testing), but its power
   is lower than each test's (Rubin, 2021). powerkit asks for the number
   of tests k and plans each at power target^(1/k). That is exact for
   independent tests; for positively related tests the joint chance is
   usually higher, so it errs on the safe side. Only for the sample size
   and the smallest detectable effect; power at a fixed N keeps the
   product as guidance. The alternative, raising each test's alpha
   ("reverse Bonferroni"; Francis & Thunell, 2021,
   `FrancisThunell2021_reversing`; Rubin, 2026, arXiv:2602.21792, p. 5),
   is named, not offered. Recommendation: accept; it needs no change to
   alpha.
3. **Philosophy caveat.** Whether separate claims need a correction
   depends on one's philosophy of significance testing (Rubin, 2024,
   *Journal of Trial and Error*, `Rubin2024_typeI`; Rubin, 2026). powerkit
   keeps the no-correction rule for separate claims and adds one plain
   sentence: under the error-statistical view, a correction may be
   expected when the tests form a related group, especially if some could
   go unreported (Mayo, 2018, pp. 275–276, `Mayo2018_severe`). The
   disjunction and conjunction advice isn't caveated: it rests on the
   standard union-intersection and intersection-union results (Rubin,
   2026, pp. 4–5, citing Roy, 1953, and Berger, 1982). That both views
   agree there is inferred, not checked.

## 2026-10-22 · Plain-words banner and "Coming soon" labels (judgement call B14, update)

The banner listed what calculates by end-point code ("E1–E9, E18,
E23–E26 and E48–E50"), which means nothing to people using the app. It
now names the analyses: "Prototype, still being checked: t-tests,
correlations, ANOVA, ANCOVA, regression, proportions and chi-square tests
calculate here; mediation gives a quick preview, then a full run or an R
script; other designs give guidance only for now." In "Plan my whole
study", the combined sample size and the consistency check are labelled
"Coming soon" rather than "once the engine is connected"; the combined N
says to use the largest N from the analyses' cards meanwhile, which is
the rule the feature will apply.

## 2026-10-22 · Settings that record what is already built

Eleven settings in `app/routing/tree.yaml` were still marked undecided
although the app already works one way, decided earlier or built since.
They now record that, so the maintainer's view lists only real open
questions. No behaviour changes.

- `alpha_power_defaults`: `as_built`, a new option (alpha pre-filled at
  .05 with a reason asked if changed; target power shown at .80 and .95
  side by side). Decided 18 October 2026 (B4).
- `one_sided_tests`: `as_built`, a new option (the direction is asked
  first; a one-sided test needs a reason, which goes into the write-up).
  Decided 19 October 2026 (B18).
- `fisher_exact`: `exact`. Two proportions (E5) offers Fisher's exact test
  (pwrss's `power.exact.fisher()`); the chi-square test of independence
  (E6) doesn't yet.
- `guided_route`: `yes`. "Plan my whole study" stays.
- `several_hypotheses`: `ask`; `effect_size_inputs`: `empty_required`;
  `power_curve`: `plot` (formula designs); `closing_order`: `first`.
  Decided 18 October 2026 ("The new design").
- `result_wording`: `draft`. The draft sentences stay; a source for the
  "observed power" line is still open (B11).
- `n_rounding`: `both`. The result gives the total and the size per group.
- `not_in_spec_wording`: `proposed`. Cards that point to another tool use
  the proposed wording, and powerkit never routes to a simpler stand-in
  test (A4).

Entries B3, B12, C11, D4 and A4 moved to
`archive/judgement-calls-decided.md`.

## 2026-10-22 · Observed power, rank-based tests, named tools and parallel mediators

The maintainer accepted the recommendations on four open questions.

- **Observed power: warn and allow** (judgement call 3.1, B1). The
  effect-size source gains "The result of my finished study (observed
  power)", stored as a new `effect_justification.type`,
  `own_study_result` (schema change). Choosing it shows a warning at once,
  and the engine's checker adds the same advice to the result: "post hoc
  power analyses are useless at best, misleading at worst" (Rubin, 2025,
  p. 14, citing Dziak et al., 2020; refs.bib `RubinMikael2025_power`).
  Reviewers sometimes ask for it (same page). The write-up, the reasoning
  line and the plan checker name it. Reason: blocking would leave users
  whom reviewers ask for it with no way to answer; a warning explains why
  it is misleading.
- **Rank-based tests: label the parametric figure** (judgement call 3.8,
  C10). The cards for the one-sample, independent and paired t-tests,
  the correlation and one-way ANOVA name the rank-based alternative and
  say the figure only approximates it. Reason: honest and cheap now;
  simulating the rank tests with Spower can follow.
- **Name other tools on "not covered" cards** (open question 18, A1).
  E43, E44, E46 and E47 name Hmisc, apimpower, MBESS and Spower, each
  sourced in `card-sources.md`, under "Established tools for this design
  (powerkit hasn't checked them)". Reason: a name lets users act; the
  wording says powerkit hasn't checked them.
- **Parallel mediators: two only** (open question 10, B9). Parallel
  mediation offers two mediators until three or more are validated;
  serial mediation still offers up to four. A project file asking for
  more opens with two.

## 2026-10-22 · The input screen: less effort on the mechanics, more on the effect size

The input screen for a two-group comparison had 22 fields over about five
screens of scrolling, with the goal halfway down and the effect size's
source three boxes away from the effect size. The maintainer approved
these changes, all about where effort goes, not what is asked:

- **The goal first.** "What do you want to find out?" opens the screen,
  and target power and the number of participants appear only for the
  goals that need them.
- **The effect size with its source**, in one highlighted section: the
  justification is powerkit's main question, so it gets the space.
- **Settings that start at a tool's default** (fields with a default, or
  optional, other than the number of mediators) fold into one line that
  shows every value, so nothing is hidden; it opens by itself when a
  value has been changed.
- **One convention:** everything is needed unless marked optional.

Not done, on purpose: no pre-filled effect sizes or small/medium/large
buttons (anchoring; decided 18 October 2026), no warnings behind info
buttons, no live-updating sample size on the main inputs (it invites
tuning the effect size until the N is affordable; the explore panel is
for "what if"), and no one-field-per-screen wizard (the overview of the
whole plan is part of checking it). The spec, project files and write-up
don't depend on the screen's order.

## 2026-10-22 · Progress steps and shorter cards

Approved with the input-screen changes. Four named steps (Your study,
Find your design, Your numbers, Result) sit above the screen, drawn
separately so that a result never redraws the form. Named steps, not a
percentage or "question 3 of 7": the design finder's length depends on
the answers, and a wrong progress figure costs more trust than none.
Cards keep the status, the effect-size guidance and the notes that bear
on the choice (rank-based tests, other analyses) in view, and fold what
you'd enter, the backend and the next questions into "More about this
analysis"; the two-group card goes from about two screens to one.

## 2026-10-22 · Shorter labels, help on request, problems in place

Approved with the input-screen changes. Long labels become short ones with
the detail as help text linked to the field. Definitions ("What these
terms mean") and the reason the direction is asked first open on request;
warnings (pilot study, observed power, departures) never do, because
optional text is rarely opened. The reasoning field reads "Why this effect
size? (needed to save or export the plan)" rather than being marked
optional, as it is the justification powerkit is built around. Problems
show under their field as well as in the list, and folded settings open
when a problem is inside them.

## 2026-10-22 · Labs: a list of tools, and planning from the notes without losing work

Labs opened straight onto the pre-replication notes; the maintainer asked
for a list to choose from, as more tools will follow. Labs now opens on
that list, the notes open when chosen, and the open tool is kept for the
browser tab like the notes.

"Plan the replication's sample size" kept the notes but reset the main
route without asking, so a plan in progress there was lost, and nothing
from the notes reached the plan. Now it asks before replacing a plan in
progress; it copies the notes' finding, original study and smallest
effect that would matter into "Why this effect size?" (the user's own
words, never a number into an effect-size box); and the replication's card
and input screen show that the notes are kept, with a link back.

## 2026-10-22 · Help for people unsure of their effect size

powerkit asks for a justified effect size, which is hardest for people
new to power analysis; a pre-filled value would be easier and would
undercut the point (decided 18 October 2026: no defaults, no
small/medium/large). The maintainer chose to help them reach a number they
can defend instead:

- **"Don't know what effect to expect?"**, in view in the effect-size
  section, with a button. For the basic tests it sets the goal to the
  smallest detectable effect and the source to "I can't justify an effect
  size"; for the 2 x 2 designs and regression interactions it sets the goal
  only, as the engine scales the entered pattern. It fills in no number.
- **"Not sure what number to put here?"**: the smallest effect that would
  matter, starting in the measure's own units (with how to turn a
  difference into d or d_z, the definitions the glossary already uses); a
  meta-analysis; one previous study, reduced for bias; and not knowing.

Next, not yet built: entering the difference and SD in raw units for the
t-tests (a spec option, as the 2 x 2 designs have), and worked examples
that open separately so their numbers can't be carried into a plan.

## 2026-10-25 · Two dependent correlations: engine

**What.** Two dependent correlations in one group, in the engine only
(not in the app): G\*Power's "Correlations: Two dependent Pearson r's",
common index and no common index (coverage-roadmap rows A4, A5). Like the
other tests by formula (18 October 2026), each is one pwrss call:
`power.z.twocors.steiger()`, Steiger's (1980) z test.

- Template `overlapping_correlations`: X with Y against X with Z (the two
  correlations share X); population `r_X_Y`, `r_X_Z`, `r_Y_Z`.
- Template `nonoverlapping_correlations`: X1 with Y1 against X2 with Y2,
  for example the same two measures at two ages; population `r_X1_Y1`,
  `r_X2_Y2` and the four other correlations.
- Effect `correlation_difference`, method `steiger_z`; "greater" means the
  second compared correlation is larger, and a one-sided test must point
  that way (pwrss's one-sided test runs in the direction of the specified
  difference, as for two independent correlations).
- Goals: power at a fixed N and the required N. No simulation option and
  no smallest detectable effect yet. Correlations that can't hold together
  (a correlation matrix no population could have) are refused in plain
  English, and so is a two-sided power goal with equal compared
  correlations, which pwrss can't compute (a one-sided test gives the
  Type I error check: power .05 at alpha .05).

**Pooled or unpooled: unpooled, as G\*Power (the maintainer's decision,
25 October 2026).** pwrss's default, `pooled = TRUE`,
uses the average of the two compared correlations for their covariance
under the null; `pooled = FALSE` uses the specified values. With
`pooled = FALSE`, pwrss gives G\*Power's required N for both of the
manual's examples as Spower's `gpower_examples` vignette reports them
(144 and 886; pooled: 139 and 875). Decided: unpooled, as G\*Power
(Departure 12), because G\*Power is the tool psychologists check
against, following the precedent of Departure 5 (G\*Power's choice over a
backend's default). The difference is 1 to 4% in N.

**Confirmed against the manual** (supplied by the maintainer on
25 October 2026; section 28, pp. 66-69). The decision now rests on the
formula, not only on the two N's matching:

- The manual's implementation notes (28.5.3, p. 69) say that under H0
  G\*Power sets the H1 correlation equal to the H0 one, ρ_ac = ρ_ab (or
  ρ_cd = ρ_ab), when it computes their covariance. pwrss's
  `pooled = FALSE` branch makes exactly that substitution (its
  `# rho12 = rho13` comment); `pooled = TRUE` averages the two instead.
- Its examples 28.3.1 and 28.3.2 (p. 67) are the source of 886 and 144,
  so the unit test for Departure 12 now cites the manual rather than
  Spower's vignette at second hand.
- powerkit's power at those N matches the manual's "actual power" to six
  decimal places for the common-index example (0.801161) and to about
  6e-5 for the other (0.800156 against 0.800093). The second gap is well
  inside the validation check's tolerance; it is noted in the test.
- G\*Power names the inputs "H0 Corr rho_ab" and "H1 corr rho_ac" (or
  "rho_cd"), which confirms the direction powerkit uses: the one-sided
  test runs from the first compared correlation to the second.

**Validation.** Two published tests in `test-validation-basic-tests.R`
(section 5), for the G\*Power manual's examples 28.3.2 (common index) and
28.3.1 (no common index), with `TODO_PUBLISHED_VALUE` placeholders for the
maintainer to transcribe from the manual itself; they run in the `basic`
chunk. The unit tests check powerkit against pwrss called directly, the
required N against the power at N - 1, the refusals, the exported R
script, and the size of Departure 12.

**Next.** A card (the app's E49 card says dependent correlations aren't
calculated yet) and the result screen's departure line, in a separate
PR.
## 2026-10-25 · Logistic regression: engine

**What.** Logistic regression in the engine only (not in the app):
G\*Power's "z tests: Logistic regression" (coverage-roadmap row A14,
decision-tree end point E27). Like the other tests by formula (18 October
2026), it is one pwrss call: `power.z.logistic()`, the Wald z test of one
coefficient, with pwrss's default method, Demidenko (2007) with variance
correction. Design `logistic_regression`, template `single_predictor`.

- Variables: a yes/no outcome Y and a predictor X that is a score or a
  yes/no group.
- Population: `odds_ratio`, `base_prob`, and optionally `x_prob` (yes/no X)
  and `r2_other_predictors` (X's R-squared with the other predictors; their
  own effects aren't needed, as in G\*Power and pwrss).
- Effect `odds_ratio`, method `wald_z`; one-sided tests must point the way
  of the odds ratio ("greater" means above 1), as pwrss's one-sided test
  runs in the direction of the effect.
- Goals: power at a fixed N and the required N. No simulation option and
  no smallest detectable effect yet. An odds ratio of 1 at a fixed N gives
  power .05 at alpha .05 (Type I check).

**Judgement call: what the odds ratio of a score X is per.** pwrss takes
the odds ratio for a one-unit increase in X and the base probability at
X = 0, with X normal (mean 0, SD 1 by default). **Recommendation: take a
score X as standardised**, so the odds ratio is per SD of X and the base
probability is at X's mean, because then no mean or SD has to be asked
and the base probability is at a value of X that occurs. Studies that
report an odds ratio per raw unit would need converting (OR per SD = OR
per unit ^ SD), which the input screen can help with later. Not a
departure: it is pwrss's own default distribution.

**Checked against the manual** (the maintainer supplied the G\*Power 3.1
manual, edition of 1 June 2023, on 25 October 2026; section 29,
pp. 70-74). Both questions above are settled, and one new one is open.

- *"Pr(Y=1|X=1) H0" is powerkit's base probability.* The manual defines it
  as p1, the probability of an event under H0, where beta1 = 0 and so Y
  doesn't depend on X (29.1, p. 70). That is pwrss's `base.prob`.
- *The procedure powerkit uses is the one the manual recommends.* G\*Power
  offers an enumeration procedure (Lyles et al., 2007) and two
  large-sample approximations; the manual recommends Demidenko (2007) "as
  standard procedure" and its Monte Carlo study found Demidenko with
  variance correction the most accurate (29.2, p. 70; Table 1, p. 74).
  That is pwrss's default, so powerkit needs no option. Its variance
  correction factors (0.75 lognormal, 0.85 binomial, 1 otherwise;
  29.6.2, p. 72) are pwrss's exactly.
- *"R² other X" is `r2_other_predictors`*, the Hsieh et al. (1998)
  correction N' = N / (1 - R²) (29.1, p. 70).
- *The manual's printed examples select Hsieh et al., not Demidenko*, so
  their N is not powerkit's. The validation placeholders say to set
  Options > Procedure to Demidenko with variance correction before
  transcribing.

**Checks run against the manual's examples** (pwrss 1.3.3 called with
powerkit's arguments; no published value was transcribed into a test):

| Example (29.4) | Manual | powerkit |
| --- | --- | --- |
| Normal X, OR 1.5, p1 .5, two-sided, alpha .05, power .95: Demidenko with variance correction | 337 | 337 |
| the same, without variance correction | 355 | 355 |
| the same, Hsieh et al. | 317 | 317 |
| Binary X (pi .5), p1 .05, p2 .10, power .95: Demidenko with variance correction | 1437 | 1437 |
| Normal X as above with "R² other X" 0.1, said to be Demidenko with variance correction | 395 | **375** |

**Open question for the maintainer: "R² other X" above 0.** Everything
agrees at R² = 0. At R² = 0.1 the manual reports 395 where powerkit gives
375 = 337 / 0.9; 395 is exactly 355 / 0.9, powerkit's answer with the
variance correction switched off. The manual's own formulas (14) and (15)
(29.6.2, p. 72) put R² in the mean of the H1 distribution only, which is
what powerkit does and implies 375, and its validation notes record a
deviation from PASS for this case too (29.7, p. 73). So the manual's 395
may come from a run with the correction off, or G\*Power may drop it once
R² is above 0. Nothing was changed in the engine on this evidence: the
maintainer has G\*Power and can settle it. Recorded as "Known
differences", 3 in conventions.md; the validation placeholders prefer an
example with "R² other X" = 0 meanwhile.

**Validation.** `test-validation-logistic-regression.R`, a new chunk
(`logistic`) in `scripts/run-validation.R` and the full-validation
workflow: two published tests for the G\*Power manual's examples (normal
X, yes/no X), with `TODO_PUBLISHED_VALUE` placeholders. The unit tests
check powerkit against pwrss called directly (score and yes/no X, with and
without other predictors, one- and two-sided), the required N against
N - 1, the refusals, and the exported R script.

**Next.** Poisson regression (pwrss's `power.z.poisson()`) in its own PR;
then a card for E27.


## 2026-10-25 · Poisson regression: engine

**What.** Poisson regression in the engine only (not in the app):
G\*Power's "z tests: Poisson regression" (coverage-roadmap row A15,
decision-tree end point E28). As with logistic regression, it is one pwrss
call: `power.z.poisson()`, the Wald z test of one coefficient, with
pwrss's default method, Demidenko (2007) with variance correction. Design
`poisson_regression`, template `single_predictor_count`.

- Variables: a count outcome Y and a predictor X that is a score or a
  yes/no group.
- Population: `rate_ratio`, `base_rate`, and optionally `mean_exposure`
  (1 if omitted), `x_prob` (yes/no X) and `r2_other_predictors`.
- Effect `rate_ratio`, method `wald_z`; one-sided tests must point the way
  of the rate ratio ("greater" means above 1), as for logistic regression.
- Goals: power at a fixed N and the required N. No simulation option and
  no smallest detectable effect yet. A rate ratio of 1 at a fixed N gives
  power .05 at alpha .05 (Type I check).
- A score X is taken as standardised, so the rate ratio is per SD and the
  base rate is at X's mean: the same judgement as for logistic regression
  (above), for the same reasons.

**Three small decisions, not worth holding the PR for.**

- *A `count` variable type.* A Poisson outcome is neither a score nor a
  yes/no, so `variable.type` gains `count`. Additive: every other design
  pins Y by `$ref` to the continuous or binary variable, so none of them
  accepts it.
- *The template is `single_predictor_count`, not `single_predictor`.* The
  backend, the check run and the script export all switch on the template
  alone, so a template name has to be unique across designs. If those
  switches are ever keyed on design and template together, the two
  designs could share the name `single_predictor`.
- *`mean_exposure` defaults to 1*, as in pwrss and G\*Power, so the base
  rate is the expected count per person unless an exposure is given.

**Checked against the manual** (G\*Power 3.1 manual, edition of 1 June
2023, section 30, pp. 75-80).

- *The procedure powerkit uses is the one the manual recommends.* It
  recommends Demidenko (2007) "as the standard procedure" and says
  Signorini's (1991) "is problematic and should not be used; it is only
  included to allow checks of published results referring to this
  widespread procedure" (30.2, p. 76). pwrss's default is Demidenko with
  variance correction, so powerkit needs no option.
- *The variance correction factor is 0.75 for a lognormal X and 1
  otherwise* (30.5.2, p. 77), which is what pwrss uses for this test; the
  0.85 it applies to a binary X in logistic regression is commented out in
  its Poisson function. So a yes/no X is corrected differently in the two
  designs, in both tools, deliberately.
- *"Mean exposure" is `mean_exposure`*, the exposure time t in the
  manual's equations (16) to (18) (30.5.2, p. 77), and pwrss's
  `mean.exposure`.
- *The manual's printed example selects Signorini*, so its output block is
  not powerkit's answer; the sample sizes for the other procedures are in
  the text that follows it. The validation placeholders say so.

**Checks run against the manual's examples** (pwrss 1.3.3 called with
powerkit's arguments; no published value was transcribed into a test).
Rows marked with another procedure are pwrss's other methods, not
powerkit's, and are there to show the whole example reproduces.

| Example (section 30) | Manual | powerkit |
| --- | --- | --- |
| Swimmers (30.3, pp. 76-77; Signorini, 1991, p. 449), one-sided, Exp(beta1) 1.3, base rate .85, exposure 1, X binomial pi .5, alpha .05, power .95: Demidenko with variance correction | 649 | 649 |
| the same, without variance correction | 655 | 655 (pwrss's `"demidenko"`) |
| the same, Signorini's procedure | 697 | 697 (pwrss's `"signorini"`) |
| the same with "R² other X" 0.1, Signorini's procedure | 774 | 774 (pwrss's `"signorini"`) |
| Table 2 (30.4, p. 78), X normal, beta1 -0.10, -0.15, -0.20; two-sided, N 200, beta0 .5, alpha .05: "Demi(c)" column | .445, .782, .956 | .444591, .782076, .956209 |
| Table 2, X binomial pi .2, beta1 -0.20, -0.40: "Demi(c)" column | .254, .716 | .254388, .716318 |

The binomial rows matter: an X that is not symmetric about its mean is
where the variance correction changes the answer, and the manual's "Demi"
and "Demi(c)" columns differ there (.268 and .254 for beta1 -0.20). The
engine lands on the corrected value, which is also the closer of the two
to the manual's own simulation.

**This bears on the open logistic question.** The R-squared correction
sits in the same place in both tests' formulas, and for Poisson the
manual's figure for R² above 0 does match: 774 is Signorini's own R² = 0
answer (697) with the correction applied inside that procedure's formula,
which is what powerkit does. So G\*Power appears to apply R² within
whichever procedure produced the R² = 0 answer, and the logistic manual's
395 (said to be Demidenko with variance correction, but exactly 355 / 0.9,
the uncorrected answer) looks more like a run with the correction off than
a different rule. Still the maintainer's to settle with G\*Power
("Known differences", 3 in conventions.md); nothing was changed in the
engine on this evidence, and the Poisson validation placeholders note that
an example with "R² other X" above 0 is usable for this test.

**Validation.** `test-validation-poisson-regression.R`, a new chunk
(`poisson`) in `scripts/run-validation.R` and the full-validation
workflow: three published tests with `TODO_PUBLISHED_VALUE` placeholders
(the swimmers example's required N, and one Table 2 row each for a score
and a yes/no X). The unit tests check powerkit against pwrss called
directly (score and yes/no X, a non-default exposure, with and without
other predictors, one- and two-sided), the required N against N - 1, the
refusals, and the exported R script.

**Next.** A pass over the entries still marked "to check" in
conventions.md, now that the manual is to hand; cards for E27 and E28
later.

## 2026-10-25 · Conventions: the G\*Power entries filled in from the manual

**What.** The maintainer supplied the G\*Power 3.1 manual (edition of
1 June 2023), so the entries in conventions.md still marked "to check" for
G\*Power were worked through: sections 3 to 6 (the exact correlation and
proportion tests), 10 and 11 (fixed-effects ANOVA), 13 and 14 (multiple
regression) and 19 to 21 (the t-tests). Sections 29 and 30 were covered by
the logistic and Poisson regression PRs. Docs only; no code, no test and
no expected value changed.

**Settled.**

- *The independent t-test is Student's, with equal variances assumed.*
  The manual states it outright ("The t-test assumes the variances in both
  populations to be equal", 21.1, p. 52), which confirms the premise of
  maintainer's decision D7 in design-finder.md. Its noncentrality is
  d sqrt(n1 n2 / (n1 + n2)) on t(N - 2); the one-sample and matched-pairs
  tests use d sqrt(N) on t(N - 1) (19.5, 20.5, 21.5). All three "have no
  options".
- *"Total sample size" for the matched-pairs t-test is the number of
  pairs*, not of people: the manual's worked example enters 50 for 50
  IQ-matched pairs, that is 100 pupils (19.3, p. 48). For the repeated
  measures powerkit's `paired_t` covers, pairs and participants are the
  same number, so nothing changes.
- *Factorial ANOVA* (11, pp. 26-30): lambda = f^2 N on F(df1, N - k),
  where k is the total number of cells in the design, and f = sigma_m /
  sigma with sigma_m a root mean square over all of the tested effect's
  residuals rather than over its df. No options. Its worked example
  reproduces SPSS's observed power exactly. One-way ANOVA (10, p. 25) is
  the same, with df1 = k - 1.
- *Multiple regression, R² increase* (14, pp. 36-38): the fixed model is
  explicit (Y = X beta + e with "fixed and known predictor variables"),
  lambda = f^2 N on F(q, N - m - 1) with q tested of m predictors. This
  confirms what "Known differences", 1 had assumed about G\*Power
  treating the predictors as fixed.
- *Effect sizes and settings* for the exact correlation (3) and
  proportion tests (4 one proportion, 5 McNemar, 6 Fisher), including the
  alpha-balancing options for the two discrete tests ("Assign alpha/2 to
  both sides" by default) and that McNemar's N is also a number of pairs.
  G\*Power parametrises McNemar by the odds ratio pi12 / pi21 plus the
  proportion of discordant pairs; powerkit's two discordant proportions
  determine both, so the parametrisations are equivalent.

**What the manual cannot settle.** It says of itself that it "is not yet
complete", and it has no section on repeated-measures ANOVA, the
two-independent-proportions z test, the chi-square test of independence,
ANCOVA or mediation. Two open items therefore stay open, and both are now
recorded in conventions.md as needing G\*Power itself rather than the
manual:

- which "Effect size specification" setting produced the within-between
  values the Superpower vignette attributes to G\*Power (Departure 2);
- whether G\*Power's two-proportions z test applies a continuity
  correction (maintainer's decision 6, Departure 5). The manual's only
  documented pooled z test for two proportions is the large-sample
  approximation to Fisher's exact test, and that one *is* continuity
  corrected (6.6.2, p. 17). It is a different test, so this is a caution,
  not evidence against the decision.

**The correlation test: nothing new, and a correction.** An earlier draft
of this entry presented G\*Power's exact correlation test as a new
judgement call for the maintainer. That was wrong, and the claim is
withdrawn. It was settled on 17 October 2026 and is already written up as
Known difference 10 in conventions.md, which cites the same manual section
(3, pp. 9-10) and its "Use exact distribution if N <" option, records that
pwrss's `power.exact.onecor()` reproduces both of the manual's examples
(N = 1928, and power 0.4829271 against the printed 0.482927), gives the
size of the difference for r = .3 to .5 and N = 20 to 100 (at most 0.0038
two-sided, 0.0047 one-sided, and at most one participant in the required
N), names the test that holds it there
(`test-backend-pwr.R`, "departure: correlation by Fisher's z, not
G\*Power's exact method"), and is shown to users on E4's card and the
result screen. Section 3 therefore confirmed what was already recorded and
added nothing. One detail is worth keeping in mind for anyone revisiting
it: the manual's largest gap (0.482927 against 0.422599) is at rho0 = .8,
a null correlation other than zero, which powerkit's template cannot
express, so it is outside what powerkit computes.

**One smaller open point.** For Fisher's exact test the manual says the
test "has no options" (6.3) but then describes three asymptotically
equivalent two-sided statistics without saying which is used (6.6.1).
powerkit calls `pwrss::power.exact.fisher(method = "exact")`. Recorded in
the table; nothing to do unless a published value disagrees.

**Next.** The pwrss column, which is still mostly "to check" and can be
filled from the installed sources: in particular whether pwrss's two-sided
exact tests balance alpha the way G\*Power does by default.
## 2026-10-25 · Planned comparisons (contrasts): engine

**What.** A planned comparison between the levels of one
between-participants factor, in the engine only (coverage-roadmap row B32,
decision-tree end point E19). Design `factorial_anova`, template
`oneway_contrast`: the means, the within-group SD and one weight per level.
Like the other tests by formula it is one pwrss call,
`power.t.contrasts()`, which is a t test of the weighted combination of
means (t squared is G\*Power's F with numerator df 1, so it is the same
test). Trend tests are contrasts with the matching weights.

- The weights live in `target_test > weights`, not in `population`,
  because they say which effect is being tested rather than what the
  population is like: the same place as `target_test > path` for
  mediation.
- Refused in plain English: the wrong number of weights, weights that
  don't add up to 0, weights that are all 0, weights on a template that
  isn't a contrast, unequal groups, and a one-sided test.
- The weights' scale doesn't matter: (-3, -1, 1, 3) and
  (-1.5, -0.5, 0.5, 1.5) are the same contrast, which a unit test checks.

**Judgement call: which tool computes it.** The roadmap named Superpower's
`emmeans_power()` for this row, and the decision tree also named pwranova's
`pwrcontrast()`. **Recommendation, taken: pwrss.** Three reasons, and the
risk turned out to be low:

- pwrss takes an arbitrary weight vector. Superpower's `contrast_type` is
  an emmeans family (`"poly"`, `"pairwise"`), which covers trends but not
  a comparison like "the first two levels against the last two" that the
  manual's own example uses.
- It is a formula, so it needs no data generation and no seed, which is
  the pattern for every other test by formula.
- Superpower's emmeans route computes the same contrast on one exact data
  set and **agrees** with it, so the choice doesn't trade accuracy for
  convenience. That agreement is now a unit test, which also confirms the
  weights mean to powerkit what they would mean to the ANOVA backend.

pwranova is not a powerkit dependency and was not checked.

**Judgement call: adjusting alpha for several contrasts.** pwrss's
`adjust.alpha` offers Tukey, Bonferroni, Holm, Hochberg, Hommel, BH, BY
and fdr for a matrix of several contrasts. **Recommendation: one contrast
at a time, with no adjustment** (pwrss's own default), because powerkit
already treats corrections for multiple tests as an inference question of
its own (`docs/inference-question-design.md`), and applying one inside the
power calculation as well would count it twice. A user planning several
contrasts can run each one. The maintainer can overrule this; offering a
contrast *family* with its adjustment is the natural follow-up, and
Superpower's emmeans route would be the better tool for it.

**A trap worth recording.** pwrss's `k.covariates` defaults to **1**,
which spends a denominator degree of freedom a plain one-way design does
not have. powerkit passes 0 explicitly. With the default, the manual's
example comes out at 0.426971 and 0.487157 instead of 0.451898 and
0.514737 — wrong by about .03, with no warning. The check run reports the
value pwrss used.

**Checks run against the manual's example** (G\*Power 3.1 manual, 11.3.3,
p. 29: four levels, means 1.5, 2, 3, 4, five per group, SD 2; pwrss and
Superpower called with powerkit's arguments; no published value was
transcribed into a test):

| Contrast (weights) | Manual | powerkit (pwrss) | Superpower (emmeans) |
| --- | --- | --- | --- |
| 1,2 vs 3,4 (-0.5, -0.5, 0.5, 0.5) | 0.451898 | 0.451898 | — (not an emmeans family) |
| linear trend (-3, -1, 1, 3) | 0.514736 | 0.514737 | 0.514737 |
| quadratic trend (1, -1, -1, 1) | 0.057970 | 0.057970 | 0.0579695 |

The quadratic row is the useful one for the arithmetic: its power is close
to alpha, so a sign or weighting mistake shows up plainly.

**Not a departure.** Every pwrss argument is its own default except
`k.covariates`, which is 0 because the design has no covariates. Recorded
in conventions.md under "Planned comparisons (contrasts)" rather than
under "Departures".

**Two-sided only.** pwrss's contrast function has no one-sided option, and
the schema refuses a direction for this template. G\*Power's contrast is
an F test, which is two-sided in the same way.

**Validation.** `test-validation-anova-contrast.R`, a new chunk
(`contrast`) in `scripts/run-validation.R` and the full-validation
workflow: three published tests, one per contrast in the manual's table,
with `TODO_PUBLISHED_VALUE` placeholders. The source comment explains that
G\*Power has no contrast screen (a contrast is entered as an f with
numerator df 1), so what is transcribed is the power, and that the
manual's printed block says "A priori" while supplying a sample size and
reporting power, which is a post hoc analysis.

**Next.** The exact one-sample correlation test (closing the open question
from 25 October 2026), then the two rows the manual can still settle (A6
two independent correlations, A47 the generic t test), then wiring the six
validated-but-unwired designs into the app.
## 2026-10-25 · Three candidate packages recorded for rows that had none

**What.** Three of the five roadmap rows with "no ready-made tool" now name
a candidate in coverage.md and coverage-roadmap.md:

- **B14, mediation with a yes/no or count outcome:** powerMediation, said
  to implement Vittinghoff, Sen and McCulloch's (2009) method for logistic
  and Poisson outcomes.
- **B17, longitudinal (cross-lagged) mediation:** semPower, which already
  appears for B43 with dedicated `semPower.powerCLPM()` and
  `semPower.powerRICLPM()` entry points. The open question is whether it
  can test a *product* of paths, which an indirect effect needs; its
  purpose-built cross-lagged functions are the place to start, not a
  general path test with a product constraint.
- **B27, Cochran's Q:** DescTools' `CochranQTest()`, which is the test and
  not its power. It would make a custom simulation possible; a published
  power method would still be needed, because powerkit doesn't write the
  maths itself.

**Marked as unchecked, deliberately.** coverage.md's standard for that
section is that a candidate has been read in the package's own
`DESCRIPTION`, `NAMESPACE` and help files. None of these three has: CRAN
and the CRAN mirror were both unreachable from the build environment on
25 October 2026 (HTTP 403 through the proxy), so the function names and
arguments come from a secondary description and may be wrong. Every row
says so and says to check the package's own files first. Nothing was built
on them.

**Why record them at all.** Those rows read "none found", which is
stronger than the evidence: it means nobody had found one, not that none
exists. A named candidate with an explicit "not checked" is more useful to
the next person than silence, and it costs nothing to verify later.

**Not changed.** B43 already named powRICLPM and semPower, so nothing was
added there. The five rows stay "no ready-made tool" and their cards stay
honest until a candidate is verified and a published method exists.
## 2026-10-25 · Two of the eight unchecked rows checked against the manual

**What.** Of the eight rows marked "wired, not yet checked against
G\*Power", the manual can settle two. Both were checked, and both
reproduce it. Docs and validation placeholders only; no engine change.

| Row | Example | Manual | powerkit |
| --- | --- | --- | --- |
| A6, two independent correlations (E49) | 27.3, p. 65: r1 .75 against r2 .88, two-sided, alpha .05, n1 51 and n2 260 | 0.726352 | 0.7263517 |
| A6, the same example's a priori half | 27.3: the same correlations at that power with equal groups | 84 per group | 168 total |
| A47, generic t test (E50) | 25.3, p. 63: the one-sample t test as a generic t, delta -1.25, df 24, two-sided | 0.224525 | 0.2245240 |

The generic t agrees to five decimal places and differs in the sixth
(about 1e-6), which `expect_power_exact()` allows (0.0005) but which is
outside the manual's last printed digit. The validation placeholder says
so, so nobody spends time on it.

**The other six can't be checked from the manual.** It has no section on
ANCOVA (A22), the chi-square goodness-of-fit test (A42), or the generic F,
chi-square and z tests (A46, A48, A49), and its Fisher's exact test
section (A38) has an empty Examples subsection. Each row now says it needs
G\*Power itself rather than the manual, as the maintainer's earlier
screenshots did for the basic tests.

**Two things worth keeping from the reading.**

- *pwrss's `n.ratio` is n1 / n2*, the inverse of powerkit's
  `allocation_ratio` (n2 / n1). The adapter already inverts it, and a
  direct call written the other way round gives 0.99999 where the right
  answer is 0.726352, so the inversion is doing real work. The unit test
  for the published example goes through powerkit for that reason.
- *The manual's printed Output block for 27.3 is garbled by its own
  two-column layout*: its lines are interleaved with section 26's, so
  "Critical z: 60.391478" is the chi-square test's critical value and the
  line labelled "Upper critical chi-square" holds this test's critical z.
  The power on the last line is this test's. The placeholder warns about
  it.

**Validation.** Two new files, `test-validation-two-correlations.R` (two
published tests: the post hoc power and the a priori N) and
`test-validation-generic-tests.R` (one test per generic statistic, the t
one citing the manual and the other three saying they need the program),
with new `two_correlations` and `generic` chunks in
`scripts/run-validation.R` and the full-validation workflow. Every value
is a `TODO_PUBLISHED_VALUE`.

**A wrinkle in the shared validation helper.** `validation_spec()` always
adds a replication count and a sample-size goal, and
`skip_if_no_backend()` probes `route_spec()`. A generic test has no sample
size, refuses `nrep`, and isn't routed through the backend router at all
(`run_spec()` computes it from the noncentrality), so the generic file
builds its specs itself and reads the single row of the curve. The comment
in it explains why, so the next person doesn't "fix" it back.

**Next.** Wiring the six validated-but-unwired designs into the app, one
design per PR.
## 2026-10-25 · The roadmap said six designs weren't wired; they were

**What happened.** Looking for the next piece of work, coverage-roadmap.md
said B1, B8, B9, B10, B18 and B19 (end points E9 to E14) were "Validated,
not wired", and its definition paragraph said "E9-E14 run in the engine
but the app shows guidance only". Both were written on 17 October 2026 and
overtaken soon after. All six run in the app today:

- **E9** is in `forms.yaml`'s `calculates` list, with a background run for
  power, a required N and a smallest detectable effect, and an optional
  group on its input screen for the reliabilities of X, W and Y.
- **E10 to E14** are under `forms.yaml`'s `simulations > endpoints`: a
  rough preview for power, then the full run in the app for E10 to E12,
  and an R script for E13, E14 and every required N. `setup.R` builds the
  app's own list of what calculates as `calculates` plus those, with the
  comment "As in app.R", and `test-results.R` has a test named
  "E1-E9, E18, E23-E26 and E48-E50 calculate; E10-E14 preview first, then
  a full run or an R script".

Nothing needed building. The statuses are now corrected, with the
per-end-point detail, because "not wired" was sending a reader to work
that was already done.

**Five more rows were stale the same way.** A10, A11 (E24), A23 (E18),
A35 (E25) and A37 (E26) still read "Planned (wave 2: engine groundwork,
draft PR; not wired)". Those four end points are in `calculates` and are
described as calculating in status.md. They now read "Wired", with the
qualifier that each matches G\*Power in the engine's tests
(`test-backend-wave2.R`) but is not in the full validation run, where its
published value is still a placeholder. C5 (measurement unreliability) and
C11 (power curves and sensitivity) were stale too: E9's screen does ask
for the three reliabilities, and the result screen does draw power against
N (`explore_curve()`), with a sensitivity goal on E1 to E9.

**A test now holds the page to the app** (`test-docs-match.R`, beside the
tests that hold tree.yaml to decision-tree.md): for every roadmap row
whose end-point cell names one the app calculates, the status may not say
"not wired". Run against the page as it was, it names all twelve stale
rows. It only reaches rows whose end-point cell starts with an end-point
id, so C11, whose cell starts with prose, is outside it.

**The summary table was drifting too.** Three statuses the rows use
("Wired", "No ready-made tool", "Partly working") were missing from it, so
its lines covered 125 of the 130 rows, and four of the others were out by
a few. Every line is now counted from the rows, and the vocabulary at the
top lists what the rows use. Recounting by hand is the sort of thing that
rots again; a test for it would be a reasonable follow-up.

**Worth saying plainly:** this page is the one I kept consulting to decide
what to build, and it was wrong twice in a day (here, and on the
correlation question that turned out to have been settled on 17 October).
status.md and forms.yaml were both right. The lesson for the next session
is to check `forms.yaml` and status.md before trusting a roadmap status,
which the new test now enforces for the "wired" claim at least.

## 2026-10-25 · Four consistency tests for the parts no test was watching

**What.** `app/routing/tests/testthat/test-repo-consistency.R`, four tests
for places where a document, a script and a workflow have to agree and
nothing was checking that they did. Each was confirmed to fail when the
thing it guards is broken, not only to pass as things stand.

| Test | What breaks without it |
| --- | --- |
| Every `test-validation-*.R` file is in a chunk of `run-validation.R`, and every chunk names a file that exists | A new validation file never runs in the full validation, and nobody notices because the run still reports success |
| Every chunk has an entry in `validation_minutes()` | The progress report has no estimate to divide |
| Every chunk can be chosen in the full-validation workflow | A chunk exists but can't be run from GitHub |
| Every test named in conventions.md exists, with the name it is given | A departure's evidence is a dangling reference, which CLAUDE.md requires to be real |
| coverage-roadmap.md's summary counts match its rows | The counts drift, as they had (the table covered 125 of 130 rows) |

**Where they live, and why.** In the app's suite, not the engine's. The
engine's tests run against a built copy of `engine/` and can't see `docs/`
or `scripts/`; the app's suite runs from the repository and already holds
tree.yaml to decision-tree.md, so the pattern was there to follow. The
file says so at the top, so nobody moves them and wonders why they break.

**Two things found while writing them.**

- `yaml::read_yaml()` reads a workflow's `on:` key as the boolean true, so
  it arrives named `"TRUE"`. The test handles all three spellings rather
  than assuming one.
- Sourcing `scripts/run-validation.R` from inside a test is safe because
  its command-line block is guarded by `sys.nframe() == 0`, which is
  non-zero under `sys.source()` in a function. The test notes this, since
  the obvious worry is that sourcing it starts a validation run.

**Not done:** the app's six tests that compare the app's result with the
engine's (including every wired end point) skip with "On CRAN" unless
`NOT_CRAN` is set, and CI doesn't set it, although the job does install
the engine. Letting them run in CI is a one-line change to the workflow
and would have caught the stale "not wired" statuses a week earlier. It
lengthens the job, so it is the maintainer's call rather than something to
slip into a test PR.

**Correction (26 October 2026):** the six tests were already running in
CI. `r-lib/actions/setup-r` sets `NOT_CRAN=true` for every later step
unless it is already set, and the app job's test summary reports no
skipped tests (`SKIP 0`). Both test workflows now set `NOT_CRAN`
themselves, so the tests keep running if a job stops using setup-r.

## 2026-10-26 · Every design is reachable from the design finder

**What.** The rule written into
[`adding-a-test.md`](adding-a-test.md) when the process page was first
drafted — common designs in the design finder, rare ones listed only
under "I know my analysis" — is wrong and has been replaced. Every design
powerkit can run is reachable from the finder. The only exception is a
design that cannot be identified from a description of a study, but only
by name: the generic tests (E50), where the researcher must already know
they have a noncentrality parameter.

**Why (the maintainer, 26 October 2026).** Letting users find only the
obvious designs through the finder is poor scientific practice. The
researcher who needs a multilevel model and doesn't know it cannot look it
up by name, so a finder that leads only to familiar designs would send
exactly that person to a t-test — the failure powerkit exists to prevent.
Rarity is not the test; identifiability is.

**It also matched the app badly.** The four screening questions already
lead to clustered data (E34), counts (E28), ordered categories (E29),
survival (E43), pairs (E44), many stimuli per person (E33), equivalence
(E36) and planning for precision (E46). The rule as first written would
have contradicted the tree that is already built.

**What keeps a simple design simple** is where the questions sit, not
which designs exist: four screening questions for everyone, and anything a
rare design needs asked only of people whose earlier answers imply it.
Someone comparing two groups on a score is never asked about nesting or
exposure time.

## 2026-10-26 · The toolbox doesn't decide the method

**What (the maintainer, 26 October 2026).** Two things are now written into
the process ([`adding-a-test.md`](adding-a-test.md) section 2, `CLAUDE.md`,
and the framing of [`conventions.md`](conventions.md) and
[`gpower-parity.md`](gpower-parity.md)):

1. **The method is chosen first and the package second.** What powerkit
   can do, and how it does it, is not decided by which packages happen to
   be installed. If nothing available computes a design properly, the
   outcomes are a better package or the design staying uncovered with the
   reason recorded — not a worse approximation offered as the answer.
2. **Familiar is not correct.** G\*Power tells powerkit what researchers
   expect to type and read; it is not the standard of correctness, and is
   criticised in the methods literature. Where it does something badly,
   powerkit should not copy it so that the numbers match what people are
   used to. The packages powerkit calls get the same treatment: this
   project has already found and reported three faults in Spower's
   `p_var.test()` and one in its `p_r()`
   ([`upstream-questions.md`](upstream-questions.md)), so a package default
   is a claim to check rather than an instruction.

**How this sits with "follow the established tools' conventions by
default".** That rule stays, but it is a rule against *silent* divergence,
not deference. The departures machinery — recorded in `conventions.md`,
shown on the result screen, stated in the methods paragraph, and covered
by a test showing the size of the difference — is what lets powerkit use
the better method and still leave a user able to see exactly why its
number differs from the tool they know. powerkit already does this where a
default was wrong for the design: no continuity correction, no spurious
covariate in a contrast, the unpooled Steiger test, and the direction of a
one-sided variance test.

**Who decides.** Which method is right is the maintainer's call, with the
literature behind it, and some questions need a statistician. A thread
never settles it quietly, and never settles it by reaching for what is
already installed.

## 2026-10-26 · Three product ideas from an outside review, recorded not adopted

**Where they came from.** A catalogue of psychology power analyses the
maintainer commissioned from a language model (26 October 2026). Most of it
restates what [`coverage-roadmap.md`](coverage-roadmap.md) already holds,
and its frequency figures ("70% of studies use ten tests") and
effect-size benchmarks ("median d of 0.36 to 0.40") are unsourced, so
nothing numerical from it is used. The test names it mentions that the
roadmap misses are listed there. Three product ideas are worth keeping:

1. **A safeguard-power adjuster.** When a user takes an effect size from a
   pilot or a single published study, offer the lower confidence bound of
   that estimate instead of the point estimate (the method is attributed to
   Perugini and colleagues; **to read before use**). This fits what
   powerkit already does — it asks where an effect size came from and
   whether the reasoning still applies — and would answer the commonest way
   a power analysis goes wrong: a noisy pilot estimate taken at face value.
2. **A power curve with three lines.** The expected effect, plus an
   optimistic and a conservative one either side, so the user sees how
   sensitive the sample size is to being wrong about the effect. powerkit
   draws one curve today.
3. **A downloadable synthetic data set** beside the R script, for
   registered reports: analysis code can be written and pre-registered
   against simulated data before real participants are recruited. Cheap for
   the simulated designs, because the engine already generates one large
   data set per run for its check run. **Caveats to settle first:** it
   would carry powerkit's data-generating assumptions, which are thinner
   than real data (no missingness beyond attrition, no floor or ceiling
   effects unless asked for), so it must be labelled as simulated in the
   file itself, and it must not read as a substitute for the real analysis
   plan.

**Not adopted from the review.** Its technical recommendation — implement
the closed-form distributions in the browser in TypeScript or Rust — is the
opposite of how powerkit works and of why its numbers are defensible:
powerkit never writes the statistics itself, and every result names the
validated R package that produced it (`CLAUDE.md`). Its advice to ban
post-hoc observed power also runs against the maintainer's decision of
22 October 2026 (allowed, with a warning), though its reasoning — that
observed power is a transformation of the p-value and adds nothing — is the
argument the warning already makes.
## 2026-10-26 · "I know my analysis" can skip the screening

**What.** The "I know my analysis" route now offers, on every screening
question, a button that skips the four questions and lists every end point
powerkit knows about (53 today, against the 31 that a score measured once
leaves). The questions are then offered on the list itself, as a filter to
apply if the user wants one. "Help me choose" and "Plan my whole study"
are unchanged: they need the screening answers to route at all, so they
don't offer the skip.

**Why.** The route's own help text already describes it as a menu, "as in
G\*Power's or PAMLj's menus", and someone who knows their test — a
supervisor checking a student's number, or anyone re-running a
calculation — answered four questions to reach a list they could have
read straight away.

**What it costs.** The screening questions are not ceremony: they route
clustered data away from an independent t-test, counts away from a linear
model, a single ordered rating to its own card, and equivalence questions
away from power for detecting an effect. Someone who skips them can pick
a test that gives a confident sample size for a design where it is the
wrong analysis. Three things stand in for the questions on that path:

- the list says nothing was screened out, and that some analyses won't
  suit the design;
- every card still states what its test assumes and what it needs;
- the filter is one button away on the list.

**Not done:** a separate tab. The list, the cards and the input screens
are the same ones the guided routes use, so a second route to them would
have duplicated the list, the departures and the write-up plumbing for the
same benefit. The skip is one option in `tree.yaml` and one branch in the
server.

**Tests.** `app/routing/tests/testthat/test-screens.R`: the skip appears on
every screening question of this route and on no question of the others;
the skipped list holds every end point, says how many, and offers the
filter; the filtered list still says how many fit; and the skip is part of
the state the browser's Back and Forward buttons restore.

## 2026-10-26 · Consistency between analyses in the whole-study plan (open question 12)

**Decision.** Both approaches, in two steps.

1. **Enter once (build now).** On "Plan my whole study", a relationship
   that several analyses share (for example, the effect of X on the
   outcome, which is the total effect in a mediation with the same X) is
   entered once on the plan, and each analysis's input screen starts from
   those values. Each analysis is still calculated by its own backend,
   with that backend's established method, so nothing departs from the
   tools researchers compare against.
2. **Whole-study simulation (later, optional).** One data-generating
   model for the whole study, simulated by an existing package (a
   candidate is power4mome, whose models are written in lavaan syntax;
   its coverage of every combination the plan allows is not yet checked),
   giving power for every main analysis from the same simulated data sets
   and one sample size. No established tool plans a whole study this way,
   so before it is offered it is recorded in `conventions.md`, shown on the
   results screen, stated in the methods paragraph, covered by a test of
   the size of the difference, and checked by a statistician.

**Why.** Separately entered values can contradict each other, and a plan's
sample size is then right for no single study (`decision-tree.md` 4.2).
Entering shared values once removes the contradiction at the source, with
no new method. Whole-study simulation is more coherent still, and handles
"every result must be significant" exactly rather than by raising each
test's power, but it is new and slower, so it waits for checking.

**Recorded in:** setting `consistency_approach` (`both`); `next.md`;
`archive/judgement-calls-decided.md` (D6).

## 2026-10-26 · CI runs in a prebuilt image

**What.** The four test workflows (R CMD check, the app's tests, the
nightly and the full validation) run inside a Docker image that already
holds R at `renv.lock`'s version, the system libraries, and every package
in `renv.lock` at its locked version (`.github/ci/Dockerfile`).
`.github/workflows/ci-image.yaml`, the first job of each workflow, tags
the image with a hash of `renv.lock` and the Dockerfile and builds it in
GitHub's container registry only when that tag is missing.

**Why.** Each job used to install R (`r-lib/actions/setup-r`) and apt
packages before any code ran. On a good day that took two minutes; on
26 October the apt step took up to 12 minutes and setup-r up to 21, so a
check that runs in 10 minutes took 45, and several runs failed when a
download timed out. The renv package cache was never the slow part.

**What stays the same.** The 17 October decision holds: CI uses exactly
the versions in `renv.lock`, and a new backend release changes results
only through a PR that updates it. The build stops if the base image's R
differs from the lockfile's, or if any locked package fails to load or
isn't its locked version. A lockfile change rebuilds the image once (about
three minutes); every other run pulls it. `NOT_CRAN` is set in each job,
since setup-r, which used to set it, is no longer used.

**Not changed.** `online-app-manifest.yaml` (it writes the manifest from
an activated renv project) and `run-it-yourself.yaml` (it exists to test
a clean install on each operating system).

## 2026-10-27 · The Labs methods map: a pan-and-zoom diagram

**Decision (maintainer, 27 October 2026).** The first version of the map of
the methods (`next.md`, Labs tool 2) is a diagram the user can pan and
zoom, rather than a grid of grouped lists. Whether each analysis's page
later gets a sourced reading list is still open.

**How it is built.** The map is generated from `tree.yaml`, the design
finder's own questions (`app/routing/R/map.R`), so it cannot drift from
them: the research questions, the questions that narrow them down, and
every analysis, coloured by whether powerkit calculates it; a second group
holds the designs the screening questions route elsewhere. Questions open
and close on a click, so the first view shows only the research questions.
It is drawn as an SVG with a small amount of the app's own JavaScript for
panning and zooming, so no new package is needed. A plain nested list of
the same map is offered for screen readers and keyboard use. Clicking an
analysis opens its card, as the design finder shows it.
