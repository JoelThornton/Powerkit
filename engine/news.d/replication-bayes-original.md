* `replication_planning()` gains `original_analysis` (`"test"`,
  `"bayes_factor"`, `"posterior"`), `original_bf`, `original_prior_scale`
  and `original_prior`. A t-test's Bayes factor is read back to its t
  statistic and effect (BayesFactor's `ttest.tstat()` inverted); a
  posterior from a vague or default prior stands in for the estimate and
  standard error, and an informative prior is refused. Either Bayesian
  route leaves out small telescopes and, for a t-test, adds `bf_repeat`
  (the original's Bayes factor test repeated, under each belief) and
  `bf_null` (evidence for no effect), with bfpwr's `ntbf01()`. The result
  gains `sequential`, each belief as a design prior for
  `bayes_sequential()`, and the R script reproduces the new goals.
* refs.bib: Verhagen and Wagenmakers (2014), Ly et al. (2018, 2019) and
  McLatchie, Warmelink and Tkacheva (2020), from the published articles.
* Tests: the Bayes factor round trip; bfpwr's Bayes factor against
  BayesFactor's; the Bayesian goals against bfpwr; the script; and an
  absolute tolerance for the generic correlation gap, which a `scale`
  argument testthat 3e ignores had made unable to fail.
