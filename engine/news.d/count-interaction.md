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
