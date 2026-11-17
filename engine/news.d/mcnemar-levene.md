- McNemar's test (template `mcnemar`) takes `target_test > method`:
  `"mcnemar_exact"` (the default, pwrss's exact power, unchanged),
  `"mcnemar_chisq"` or `"mcnemar_chisq_corrected"`. The chi-square
  versions are simulated with Spower's `p_mcnemar.test()`
  (`stats::mcnemar.test()`, with or without the continuity correction) in
  powerkit's experiment `p_mcnemar_chisq()` (`backend-mcnemar-chisq.R`),
  with a check run, an exported script and the smallest detectable change
  by simulation. They are two-sided; a one-sided plan is refused.
- Two variances (template `two_variances`) take `target_test > method`
  `"levene"` or `"brown_forsythe"` beside `"f_var"`, with
  `population > score_shape` (normal, skewed or heavy-tailed). They are
  simulated with Spower in powerkit's experiment `p_levene()`, which runs
  `car::leveneTest()` (center = mean or median), with unequal groups
  allowed, a check run, simulated data, an exported script and the
  smallest detectable variance ratio by simulation (`backend-levene.R`).
  Two-sided only.
- New validation: `test-validation-mcnemar-chisq.R` and section 4 of
  `test-validation-variance-tests.R` compare both routes with simulations
  written without their packages and check their Type I error (chunk
  `variances`).
