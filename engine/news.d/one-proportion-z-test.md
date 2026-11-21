* One proportion (E25): the z test of one proportion, R's `prop.test()`
  without (`method = "z_test"`) or with (`"z_test_corrected"`) the
  continuity correction, beside the exact binomial tests. Power is summed
  over every count of `prop.test()`'s decisions (`prop_test_p()`, checked
  against `prop.test()` on every count), not pwrss's normal approximation
  (Departure 36: 78 against 86 people for 20% against 10% at 80% power).
  The R script reproduces each goal with base R. The continuity-correction
  helpers for two proportions and 2 by 2 tables now name their templates,
  so they don't apply to the one-proportion test.
