# powerkit 0.0.0.9000

* Engine: generic t, F, chi-square and z tests (design `generic_test`, not
  yet in the app), as G\*Power's "Generic" tests: power from a
  noncentrality parameter and degrees of freedom, or the noncentrality
  needed for a target power (goal `sensitivity`). There is no sample size,
  because the noncentrality already reflects it. Each is one pwrss call
  (`power.t.test()`, `power.f.test()`, `power.chisq.test()`,
  `power.z.test()`), checked against pwrss called directly and against
  base R's noncentral distributions. A generic binomial test is the exact
  test of one proportion, which powerkit already has.

* App: the result screen now has a write-up, replacing the methods-paragraph
  placeholder. A short version for the paper and a full version for a
  supplement or preregistration state the test and its sides, alpha, the
  target power and why (a new optional field), the effect size with your
  reasoning word for word, N in total and per group with the power reached,
  the number to recruit, how a claim over several tests was handled, the
  package, version and seed, and the departures. Both are editable, and like
  saving they need your reasoning. The noncentrality parameter and critical
  value are left out (the maintainer's decision, 18 October 2026).
  `export_citations()` now points to the write-up instead of a placeholder.

* Engine: four more tests by formula, each one pwrss call (not yet in the
  app): Fisher's exact test of two proportions (`target_test > method =
  "fisher_exact"`), the chi-square goodness-of-fit test (template
  `chi_square_gof`; equal fixed proportions unless given), two independent
  correlations (template `two_correlations`, Fisher's z test) and one-way
  ANCOVA (template `oneway_ancova`, Shieh's method). Each has an example
  spec, an R script that reproduces it, and tests against pwrss called
  directly; goodness of fit also agrees with pwr's formula, and ANCOVA
  with Superpower's. Not yet checked against G\*Power.

* App: four more designs calculate on their input screens. One-way ANOVA
  for three or more separate groups (E18, Superpower), multiple regression
  for R-squared against 0 or an R-squared increase, which also covers one
  predictor's coefficient (E24, pwrss), one proportion against a fixed
  value (E25, pwrss's exact binomial test) and McNemar's test (E26,
  pwrss's exact test). Welch's t-test (E2) can now be worked out by
  pwrss's formula as well as by simulation. One proportion and McNemar
  show Known difference 2 (power goes up and down with N for exact tests
  of counts). These designs match G\*Power in the engine's tests but are
  not yet in the full validation run; their cards say so.

* App, "Plan my whole study" analyses screen: each analysis now has one
  choice (not planned, main analysis, or extra analysis) instead of two
  separate ticks, so an analysis can no longer be marked "primary" without
  being planned. The question about how the main analyses support the claim
  appears only when two or more are main, and its options are written in
  plain words (no "intersection-union").

* The result screen now states every departure and known difference that
  applies: for mediation (E10–E14), lavaan's maximum-likelihood fit rather
  than PROCESS's OLS (Departure 6) and Boos and Zhang's method switched off
  (Departure 8); for parallel mediators (E11), residuals free to correlate
  (Departure 7); and for regression interactions (E9), that fixed-model
  tools such as G\*Power give slightly higher power than powerkit's
  simulation (Known difference 1, under a separate heading).

* App, screen D of the new design: every result now has a plain reading
  that keeps the condition ("if the true effect is the one you entered,
  about 8 in 10 studies like this would get a significant result"), the
  effect-size source and the user's reasoning beside the number, and a line
  on what power can't tell you. A required N is shown at 80% and 95% power
  side by side. The t-tests and the correlation have an explore panel: a
  slider for the effect size and a plot of power by sample size, which
  never changes the plan. A test checks that no output template uses a
  verdict word such as "justified" or "adequate".

* App, screen C of the new design: the effect-size source now includes
  "I can't justify an effect size" (spec type `none`, new in the schema)
  for the t-tests and the correlation. It leads to the smallest effect you
  could detect, at one sample size or across a range of sample sizes (a
  table at 80% and 95% power). The reasoning ("source") is optional to
  calculate and required only to save a project or download the R script;
  the spec schema no longer requires it. An effect size from one earlier
  study gets a short warning pointing to bias correction (BUCSS).

* App, screen A of the new design: the start screen now asks three
  questions before the design finder. "Your sample size" (choose or fixed)
  starts the input screen at the smallest effect you could detect when N
  is fixed. "Your aim" sends estimation and equivalence to their cards.
  "Your claim" (one test; several claims, each on its own; any of several;
  all of several) adds a note, and for "any of several" divides alpha
  between the tests (Bonferroni). The basic tests (E1–E6) now offer the
  smallest detectable effect, and the t-tests and correlation need no
  effect size for it.

* Smallest detectable effect for the basic tests (engine only; not in the
  app yet): goal type `sensitivity` now works for the one-sample, paired
  and independent t-tests, the correlation, two proportions and the
  chi-square test on the formula path. pwr solves for the effect when it is
  left empty (for two proportions, group 2's proportion is searched with the
  same power call), in the direction of the effect you specified. For the t-tests and the
  correlation no effect size is needed (a zero effect gives a positive
  result). The exported R script reproduces it. This is the first step of the fixed-N
  route in the new design.

* New `write_project()`, `read_project()` and `reproduce_project()`: save a
  power analysis (spec with its seed, how it was reached in the app, the
  result, and the powerkit, R and package versions) as one JSON file, open
  it again with any differences reported in plain English, and rerun it to
  check it reproduces the saved numbers. The app has "Save project" on the
  result screen and "Or open a saved project" on the start screen, which
  puts the input screen back with the same values.

* Trying the prototype: `docs/run-it-yourself.md` gives plain-English
  steps for Windows and macOS (install R 4.5.3, download the ZIP, run one
  line), with troubleshooting. `run_powerkit.R` restores the recorded
  packages and the engine if needed and opens the app. A new CI workflow
  (`run-it-yourself.yaml`) follows those steps on clean Windows and macOS
  machines and checks the app answers. The app has an "About this
  prototype" tab: what it does, that it's a prototype, which end points
  calculate, how to report problems, and credits for every foundation tool
  from its own `citation()`. `docs/hosting-options.md` compares ways to
  host it (options only).

* Wave 2 groundwork (engine only; not in the app yet): `run_spec()` now
  runs a one-way between-participants ANOVA (template `oneway_between`,
  Superpower's `ANOVA_exact()`), multiple regression R² against 0 and R²
  increase (new design `multiple_regression`, pwrss's
  `power.f.regression()`), one proportion against a fixed value (exact
  binomial, pwrss's `power.exact.oneprop()`) and McNemar's exact test
  (pwrss's `power.exact.mcnemar()`). Welch's t-test can be calculated by
  formula on request (`options > method = "exact"`, pwrss's
  `power.t.welch()`); its default stays Spower simulation. Each has an
  example spec, an exported script that reproduces it with the backend
  alone, and tests against the backend called directly. For exact tests
  of counts the required N is the smallest that reaches the target, which
  can be lower than pwrss's own answer; G\*Power reports the same N as
  powerkit (Known difference 2). One-way ANOVA, R² against 0, R² increase and one
  proportion match the maintainer's G\*Power screenshots to seven
  decimals, a priori N included (G\*Power also reports 90 for the
  one-proportion example). McNemar matches G\*Power's exact
  option too (power, and N = 129).

* Documentation: `docs/judgement-session.md` sets out the nine open calls
  that change what users see, ordered by impact, for the maintainer's
  judgement session, and `docs/saving-projects.md` compares five ways to
  save projects (judgement call E6). Options and sources only; no code
  change.

* Validation: the `basic` chunk now checks two proportions in unequal
  groups against the maintainer's G\*Power screenshots (1 : 2 and 1 : 3 in
  both directions, one tail at 1 : 2, and a priori at 1 : 3), so E5's
  "Validated" label is backed by the validation chunk as well as the unit
  tests. No change to results.

* New `export_run_script()`: an R script that runs a spec, with its seed,
  through `run_spec()` on the user's own computer, then saves the result
  and writes the backend-only reproduction script and the citations. The
  app offers it for calculations too long to run there (a mediation
  required N, and moderated mediation).

* New `power_interval()`: an exact binomial (Clopper-Pearson) range for a
  simulated power, from the recorded rejections (base R's `binom.test()`).
  The app shows its quick previews as this range.

* The app prototype now runs mediation and moderated mediation (E10-E14).
  For power at a fixed N: a rough preview from 100 simulations, shown as a
  range and labelled not to be reported, then either the full analysis in
  a separate process with a progress bar and Cancel (mediation) or the R
  script to run the full analysis on your computer (moderated mediation).
  A required N goes straight to the R script: a preview of it would take
  15 minutes or more and often couldn't narrow the N down.

* Documentation: the walkthrough pictures in `docs/figures/walkthroughs/`
  are re-rendered from the current app prototype (for example, E4's card
  now names Fisher's z and Departure 10). No code change.

* Attrition is now applied. With `options > attrition`, `run_spec()`
  returns the number to recruit (`recruitment`): each group's analysed n
  divided by (1 - attrition) and rounded up, for example 72 + 72 = 144 to
  recruit for 64 + 64 analysed at 10%. The app's result screen shows the
  numbers analysed and to recruit, with a caveat that this common heuristic
  ignores how missing data will be handled (Rubin, 2025), and the exported
  R script works it out too.

* The app prototype's card for two proportions (E5) says "Validated"
  again, after the `basic` validation chunk was rerun with the z test
  (pwrss for unequal groups).

* `refs.bib` now holds four sources the maintainer checked in full text:
  Rubin (2021), Rubin (2024), Mikael Rubin (2025) and Frane (2019). An
  entry may now be verified "from full-text PDF held by the maintainer" as
  well as from a URL a session opened. `pwrss_method` and `stats_method`
  stay placeholders: neither package's `citation()` names a method paper.

* Two proportions (E5) in unequal groups now use pwrss's z test
  (`pwrss::power.z.twoprops(std.error = "pooled")`), which matches
  G*Power's power, instead of Cohen's h, which under-estimated the
  required N (360 rather than about 370 for 95% power at a 1 : 2 split).
  pwrss is now a required package and is cited from its own
  `citation()`; the exported R script calls it for this case.

* Two proportions (E5) now use the z test as G*Power runs it: base R's
  `stats::power.prop.test(strict = TRUE)` for equal groups, which matches
  G*Power to seven decimals. Results change slightly from pwr's Cohen's h
  formula (for example 164 rather than 160 per group for 95% power with
  proportions .10 and .25). Cohen's h stays available with
  `options > proportions_formula = "arcsine"`, and unequal groups still use
  it (Departure 11 in `docs/conventions.md`). The result's backend is
  recorded as stats, and the exported R script calls `power.prop.test()`.

* When the app prototype reports a required N calculated exactly, the
  result screen also shows the power that N actually gives, for example
  "With 64 per group, power is 80.1%." Not shown for a simulated N.

* Correlations (E4) keep pwr's Fisher's z formula. This is now recorded as
  Departure 10 in `docs/conventions.md`: G*Power uses the exact
  distribution of r, and the two differ by at most 0.004 in power and 1
  participant in N (r = .3 to .5, N = 20 to 100). It is shown on E4's card
  and on the result screen.

* The app prototype (`app/routing/`) now calculates regression interactions
  (E9) on the input screen. The engine runs in a background R process, with
  an estimated progress bar and a Cancel button (about 5 seconds for power,
  about 80 seconds for a required N). The result screen, fixed seed, R
  script and citations are the same as for E1–E8. No engine change.

* Basic tests (one-sample, independent and paired t-tests, correlation, two
  proportions, chi-square test of independence) are now calculated by
  formula with the pwr package by default, not by simulation: the same
  inputs always give the same answer, with no Monte Carlo noise. Spower
  simulation stays available with `options > method = "simulation"`, and
  is used for Welch's t-test, which pwr doesn't cover. The correlation and
  two-proportion formulas are approximations (Fisher's z, Cohen's h). The
  exported R script calls pwr, and the citations export credits pwr. pwr is
  now a dependency (Imports). Departure 9 in `docs/conventions.md`.

* Basic tests now need Spower 0.7 or later. One-sided tests use Spower's
  own one-sided test (its new `alternative` argument) instead of powerkit's
  workaround for Spower 0.6.4, which halved the two-sided p-value whatever
  the direction (Departure 4, now retired). Results are unchanged: with the
  same seed, every basic test gives the same power as before. Exported
  scripts for one-sided tests now call Spower's `p_t.test()`, `p_r()` or
  `p_prop.test()` with `alternative`, and need Spower 0.7.
* Validation (for maintainers): two new chunks,
  `mediation_crosscheck_parallel` and `mediation_crosscheck_serial`,
  compare the joint-significance test for parallel and serial mediation
  in power4mome (with powerkit's translation of the spec) and in simsem,
  with data generated from residual variances worked out separately from
  the engine. Run with `scripts/run-validation.R --only <chunk>` or the
  `full-validation` workflow.

* The citations export (text and BibTeX) doesn't print a refs.bib entry's verification
  note ("Verified ..."), which records where the entry was checked rather
  than being part of the reference.
* Moderated mediation (PROCESS models 7 and 14) has passed its full
  validation again, rerun after the seeding fix (17 October 2026). The
  mediation cross-check against pwrss and simsem passed its first full run.
* Validation (for maintainers): a new `mediation_crosscheck` chunk
  (`scripts/run-validation.R --only mediation_crosscheck`, and the
  `full-validation` workflow) compares simple mediation with two tools
  written independently of power4mome: pwrss's `power.z.mediation()`
  (Monte Carlo interval and joint tests) and simsem (joint test). pwrss and
  simsem are new Suggests, used only by this chunk. The tolerance rule is
  in docs/validation-log.md.

* New `export_script(spec, result, file)` writes a standalone R script that
  reproduces a result by calling the package that computed it (Spower,
  Superpower, InteractionPoweR or power4mome) directly, with your values
  filled in and a comment on each argument. powerkit isn't needed to run
  it. With the same package versions it gives the same numbers: it uses
  powerkit's seeds and batches, and for a sample-size goal it simulates the
  same sample sizes and fits the same curve. It ends by comparing its
  numbers with powerkit's and printing `sessionInfo()`. Available for every
  design `run_spec()` runs.
* New `export_citations(result, format = "text" or "bibtex")` lists what to
  cite: the package that computed the result (its own `citation()`), its
  method paper, powerkit, and the software used underneath (SimDesign;
  afex and MASS; lavaan and manymome; and R), each from its own
  `citation()`. Method papers come from powerkit's curated reference list,
  copied from the packages' own `citation()`: Superpower's and
  InteractionPoweR's are included; Spower's and power4mome's, and
  powerkit's own paper, are shown as placeholders. The methods paragraph
  is a placeholder too (not written yet). The repository now has a
  `CITATION.cff`.
* Results record each simulated sample size's seed in
  `provenance$simulations` (with its rejections, analysable replications,
  and whether the required-n curve was fitted to it), so every simulated
  value can be reproduced.
* Moderated mediation (PROCESS models 7 and 14): a run's result now depends
  only on its seed. For a model with a product term, power4mome
  standardises the population by Monte Carlo before its own seed takes
  effect, so results depended slightly on earlier calls in the session (and
  on the number of cores). powerkit now seeds that step too. Results for
  these two models differ slightly from earlier runs with the same seed;
  other designs are unchanged. Their validation is being rerun.
* Tests that use more than 2 cores are skipped on CRAN.

* `validate_spec()` no longer fails with "non-character argument" when a
  field that accepts more than one kind of value is `null`, such as
  `population > sd` in the 2x2 ANOVA designs (reported in PR #4). It now
  gives a plain-English problem: "'population > sd' should be a number or a
  list ([ ... ]), but it is empty (null)." A missing SD is reported as
  missing, and an SD given for a design that has none is reported as a field
  that doesn't belong there.

* Validation (for maintainers): the `full-validation` GitHub workflow now
  installs the system library igraph needs (glpk) before restoring
  packages, checks that the packages load before the chunk starts, and
  doesn't start or summarise a chunk if setup failed.
  `scripts/run-validation.R` stops with a clear message if `--cores` or
  `--cores-per-test` is missing a value or isn't a positive whole number.

* Mediation and moderated-mediation simulations now run in batches of at
  most 200 replications per power4mome call (fewer above 1,000 draws per
  confidence interval), keeping only each batch's counts. Memory use no
  longer grows with the number of replications: before, 10,000
  replications of a PROCESS model 7 design needed many gigabytes, more than
  most laptops have. The method is unchanged (each batch is an ordinary
  `power4test()` call), but results are not identical to earlier,
  unbatched runs with the same seed. The batch size is recorded in the
  result's provenance (`batch_size`). The number of batches depends only
  on the number of replications and the batch size, so the same seed and
  batch size give the same result on any number of cores.
* Validation (for maintainers): a `full-validation` GitHub Actions
  workflow runs one validation chunk on demand on GitHub's machines and
  uploads the results (docs/validation-log.md, "Running the full
  validation on GitHub"); `scripts/run-validation.R --cores-per-test k`
  gives each test k cores (Linux and macOS), and its summary now also
  records the manymome version.

* The "not available yet" messages for a yes/no (binary) X or W in
  regression interactions and mediation designs no longer suggest treating
  the variable as continuous: they say that doing so may give an
  inaccurate power estimate. For regression interactions, a 2x2 ANOVA
  design is suggested only when both X and W are yes/no.
* Validation (for maintainers): published required sample sizes can be
  given as a range (`c(lower, upper)`), which passes if it overlaps
  powerkit's interval, with narrow overlaps reported; and
  `scripts/run-validation.R --retry-skipped` reruns tests saved as SKIP
  (for example, after published values are filled in) without discarding
  other results.
* `run_spec()` now runs every MVP design:
  * basic tests (one-sample, independent and paired t-tests, correlation,
    two proportions, chi-square test of independence) via Spower;
  * two-way regression interactions, with or without measurement error,
    via InteractionPoweR;
  * simple, parallel and serial mediation (PROCESS models 4 and 6) and
    first- and second-stage moderated mediation (PROCESS models 7 and 14,
    index of moderated mediation) via power4mome, with Monte Carlo or
    percentile bootstrap confidence intervals.

  These designs are simulated (`options > nrep` replications, seeded and
  reproducible). Goals: power at a fixed n, or the required n with a 95%
  interval. Every run first checks, on one large simulated data set, that
  the backend reproduces the population you specified.
* One-sided basic tests (`target_test > alternative` `"greater"` or
  `"less"`) test the direction you specify; "greater" means the spec's
  effect (d, dz, r, or p2 minus p1) is positive.
* In paired designs, d_z is the second condition minus the first (in the
  order of X's levels). Printing a paired spec says so, in your labels.
* The two-proportions z test and the Pearson chi-square have no continuity
  correction, as in G*Power.
* Mediation designs use power4mome's default number of Monte Carlo draws
  per confidence interval (1,000) when `options > ci_draws` isn't given,
  and always test with the confidence interval (Boos and Zhang's method is
  off).
* Exact 2x2 ANOVA results now equal a direct `ANOVA_exact()` call with the
  same seed on every platform (they could differ around the 15th decimal
  place).
* Not available yet, with a plain-English message: sensitivity goals for
  designs other than 2x2 ANOVAs; binary X or W in regression interactions
  and mediation designs; measurement error (reliability) in mediation
  designs.
* powerkit is now licensed under the GPL (>= 3).
* New `run_spec()` runs a power analysis for 2x2 between and 2x2 mixed ANOVA
  designs, via Superpower. Goals: power at a fixed n, the required n, or
  the smallest detectable effect (sensitivity: the specified pattern of
  means is scaled, and the effect is reported in your units and as Cohen's
  f). Power is exact by default (`ANOVA_exact()`); set
  `options > method` to `"simulation"` for Monte Carlo simulation (95%
  interval for the required n; `options(powerkit.cores = k)` or
  `POWERKIT_CORES` spreads replications over cores). Every result includes
  a check that Superpower reproduces the specified population and a
  provenance record (spec hash, method, seed, backend, R and package
  versions).
* New optional spec field `options > method` (`"exact"` or `"simulation"`).
* New design specification format (spec version 0.1), defined by the JSON
  schema in `inst/schema/design.schema.json`. It covers the MVP designs:
  basic tests (one-sample, independent and paired t-tests, correlation, two
  proportions, chi-square test of independence), 2x2 between and 2x2 mixed
  ANOVA, two-way regression interactions, simple, parallel and serial
  mediation (PROCESS models 4 and 6) and moderated mediation (PROCESS
  models 7 and 14).
* `read_spec()` reads a spec from a JSON file or string.
* `validate_spec()` checks a spec's structure and that the population it
  describes is possible (e.g. path values imply an R-squared below 1,
  correlations are possible together, cell probabilities add up to 1, the
  sample size splits into whole groups). All problems are reported together
  in plain English.
* `spec_hash()` gives a content hash of a spec that ignores field order.
* Example specs for every template are in `inst/specs/`.
