* Bayes factor t-tests (one sample, paired, two groups) take an informed
  t analysis prior: `target_test > prior_location` and `prior_df` join
  `prior_scale`. With a prior other than the default JZS one, the chance
  of evidence is worked out exactly from `bfpwr::tbf01()` by
  root-finding its threshold crossings and summing noncentral t
  probabilities over the normal design prior (new `bayes-informed-t.R`),
  because `bfpwr::powertbf01()` is wrong for informed priors at small
  samples (Departure 37). The check run, the exported R script and the
  methods paragraph follow; validation in
  `test-validation-bayes-informed.R` (chunk `bayes`).
* `bayes_robustness()` compares an informed prior with the default
  prior's three named widths, centred on 0; the sequential design card
  (`bayes_sequential()`, Cauchy prior only) isn't offered for an
  informed prior.
