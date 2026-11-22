* Validation: the formula cards now have checks that don't call pwrss
  (docs/validation-log.md, "Independent checks by card"). A new chunk,
  `formula` (`test-validation-formula-tests.R`), checks one proportion and
  McNemar's exact test against `binom.test()`'s power summed over every
  outcome, goodness of fit against `chisq.test()` on simulated counts, and
  the regression F tests (R-squared against 0, an R-squared increase, one
  coefficient) against `lm()` with the predictors set by the design. The
  `two_correlations` chunk gains Fisher's z on simulated studies, and the
  `ancova` chunk `lm()` with the covariates drawn afresh in each study
  (Shieh's model), one and two factors. Simulators are in
  `helper-independent-simulation.R`. With predictors measured afresh in
  each study, simulated regression power is about 1 to 2 points below the
  fixed-model F test's.
