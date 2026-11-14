* The same people measured more than once with a count, yes/no or
  ordered-categories outcome are a new template, `mixed_model /
  repeated_glmm` (E75): `population > metric` `"rate"` (with `rates`),
  `"probability"` (with `probabilities`) or `"proportion"` (Y
  categorical, with `category_probabilities` for the first condition and
  `odds_ratios`, the first 1), `sd_person`, `measurements` (default 1) and, for a
  negative binomial count, `dispersion` (variance mu + k mu^2); X a
  within or between factor with two or more levels; `target_test >
  effect` `"condition"`, `method` `"likelihood_ratio"` (default) or
  `"wald"`. The model is `y ~ cond + (1 | person)`: Poisson and logistic
  through simr's `makeGlmer()` and `powerSim()` (`fixed("cond", "lr")` or
  `"chisq"`); negative binomial through Spower running powerkit's
  experiment `p_repeated_nb()`, lme4's `glmer.nb()`, since simr has no
  negative binomial family; ordered categories through Spower running
  `p_repeated_ordinal()`, ordinal's `clmm()` (logit link, proportional
  odds), with the likelihood-ratio or Wald chi-square test of cond.
  ordinal joins Suggests. New backend file `backend-glmm.R`;
  `simr_model()` accepts a family. Spec checks refuse one measurement per
  person between people, and one yes/no answer per condition (McNemar's
  test or Cochran's Q), and category shares that don't add up to 1. The
  check run recovers each log rate (or odds) ratio, the person SD, the
  overdispersion and the thresholds. The R script and the simulated data
  set cover all four models. Validation:
  `test-validation-glmm.R` (chunk `glmm`).
