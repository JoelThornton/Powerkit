* New template `mediation / binary_or_count_outcome` (E32): mediation with
  a yes/no or count outcome and a mediator that is a score, X two equal
  groups or a score. Spower runs `p_mediation_yglm()` (new file
  `backend-mediation-yglm.R`), which draws M from a linear model and Y from
  a logistic, Poisson or negative binomial one, and analyses each study
  with `regmedint::regmedint(mreg = "linear")` (regression-based causal
  mediation analysis, Valeri and VanderWeele 2013): significant when the
  natural indirect effect's delta-method p value is below alpha. Population
  fields `a`, then `y_baseline`, `b_odds_ratio` and `direct_odds_ratio`
  (yes/no Y) or `base_rate`, `b_rate_ratio`, `direct_rate_ratio`,
  `count_model` and `dispersion` (count Y); method `delta_method`. Check
  run, spec checks, zero-effect check, group split rule, simulated-data
  code, R script and example spec `mediation_binary_or_count_outcome.json`.
  New validation chunk `mediation_yglm`: agreement with an independent
  simulation for a yes/no, Poisson and negative binomial outcome, Type I
  error, and a published-example placeholder.
