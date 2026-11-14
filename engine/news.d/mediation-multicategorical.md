* Mediation with X in three or more groups is a new template,
  `mediation / multicategorical` (E42): X categorical with at least three
  levels, dummy-coded against the first; `population > metric`
  `"standardised"` with `m_differences` (each later group's Cohen's d on
  M, its path a_j), `b` (the within-group path M -> Y, between -1 and 1)
  and optional `direct_differences`; `target_test > path` `"X->M->Y"`,
  `method` `"monte_carlo_ci"` and `group` (`"all"`, the default, or one
  later group). Each study is drawn in equal groups and fitted by
  `lavaan::sem()`, and each tested relative indirect effect a_j * b gets a
  Monte Carlo percentile interval from `manymome::do_mc()`'s draws, in
  Spower running powerkit's experiment `p_mediation_mcx()`, since
  power4mome's `x_fun` can't draw the dummies of one factor. With `group`
  `"all"` a study counts only when every interval excludes 0. New backend
  file `backend-mediation-mcx.R`, with a check run recovering every path,
  an R script that reproduces the run exactly (the data are drawn before
  the fit, so lazy evaluation inside lavaan can't reorder the random
  numbers), simulated-data code and spec checks (fewer than three groups,
  mismatched lengths, an unknown group, reliability). The group split
  rule asks for a multiple of the number of groups. Citations name lavaan
  and manymome when a Spower run uses them; Hayes and Preacher (2014)
  joins refs.bib. New validation chunk `mediation_mcx`
  (`test-validation-mediation-mcx.R`): agreement with an independent OLS
  simulation for one group and every group, and Type I error.
