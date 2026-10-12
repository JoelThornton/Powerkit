# powerkit 0.0.0.9000

* New `run_spec()` runs a power analysis for 2x2 between and 2x2 mixed ANOVA
  designs, via Superpower. It returns power at a fixed n, or the required n
  with a 95% interval, plus a power curve with Monte Carlo standard errors,
  a check that Superpower reproduces the specified population, and a
  provenance record (spec hash, seed, replications, backend, R and package
  versions). Set `options(powerkit.cores = k)` or `POWERKIT_CORES` to run
  replications on several cores.
* Other designs, and sensitivity goals, give a plain-English "not available
  yet" error.
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
