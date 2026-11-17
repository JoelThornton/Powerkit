* The continuity-corrected two-proportion test and the corrected 2 x 2
  chi-square test are worked out exactly by default
  (`backend-corrected-exact.R`): power sums every possible result's
  probability where R's `prop.test()` or `chisq.test()` (with
  `correct = TRUE`) rejects, so the sample size is the smallest that
  reaches the target, with no simulation error. Simulation with fresh
  confirmation checks stays available through `options > method`. The
  standalone script needs base R only. `expect_power_near()` holds an
  exact result to 0.0005 against a finite reference.
