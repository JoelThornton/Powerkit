# powerkit 0.0.0.9000

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
