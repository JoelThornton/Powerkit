* E75 (repeated yes/no answers): every run also simulates the
  likelihood-ratio test with no difference at the planned sample size,
  `repeated_glmm_type1()` (the tested coefficients set to 0, the run's
  seed and number of studies), and records it in `result$type1` with
  `kind = "repeated_yes_no"` and the expected number of the rarer answer
  in the rarest cell (`repeated_glmm_rarest()`). A 19-setting grid
  (validation-log.md, 21 November 2026) found 6.3% to 8.9% at alpha .05
  with two or fewer of the rarer answer in the rarest cell, and 7.3% with
  a 2% chance of yes even at 100 people a group, so no input rule marks
  where the excess starts. The app lists the rate among the analysis's
  limitations (result, write-up, planning document) when it is more than
  2 Monte Carlo SEs above alpha (`repeated_yes_no_type1_note()`).
