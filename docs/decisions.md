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
