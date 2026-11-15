* New template `poisson_regression / interaction` (E32): moderation of a
  count outcome, X and W each a score or a yes/no group. Spower runs
  `p_count_interaction()` (new file `backend-count-interaction.R`), which
  draws Poisson or negative binomial counts (variance mu + k mu^2) whose
  log mean is linear in X, W and X x W, fits `glm(family = poisson())` or
  `MASS::glm.nb()`, and tests the product by its Wald z test. Population
  fields `base_rate`, `rate_ratio_x`, `rate_ratio_w`, `rate_ratio_xw`,
  `dispersion` (negative binomial only), `x_prob`, `w_prob` and `r_xw`;
  methods `wald_z` (Poisson) and `negative_binomial`. The poisson design's
  `variables` block moves into `template_single_predictor_count`. Check
  run, spec checks, zero-effect check, simulated-data code, R script and
  example spec `poisson_interaction.json`. New validation chunk
  `count_interaction`: agreement with the Wald test's large-sample power
  from each model's expected information, an independent simulation, Type
  I error, and a published-example placeholder.

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
