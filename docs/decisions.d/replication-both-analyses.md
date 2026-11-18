## 2026-11-18 · Replication plans: an original analysed with both a significance test and a Bayes factor

Many papers report a t-test's p-value and a default Bayes factor for the
same comparison. The replication plan now has "Both: a significance test
and a Bayes factor" beside the three single analyses.

- **The effect comes from the test.** The test's effect (d, d_z, r, or
  the t statistic) is the original's most direct report of its estimate.
  Reading the effect back out of the Bayes factor (as the Bayes-factor
  route does, by inverting BayesFactor's `ttest.tstat()`; Ly et al., 2018)
  would add rounding in the reported Bayes factor to a number the paper
  already gives. So the engine is called exactly as for a test original,
  and every goal, the BUCSS comparison and the card's effect field work
  as they do for one.
- **The Bayes factor's prior is kept.** For a t-test, the scale of the
  original's Cauchy prior is passed as `original_prior_scale`, so the
  goal "Evidence for an effect, from the original's own Bayes factor
  test, repeated" repeats the test the paper ran rather than the default
  one. The Bayes factor itself is optional and is recorded in the
  write-up with its prior.
- **The main criterion is not changed.** With "The usual one" chosen, a
  plan for confirming the effect uses a significant result, as for a
  test original; the Bayes factor goals stay available to choose or to
  report beside it. Choosing between them is the researcher's call.
