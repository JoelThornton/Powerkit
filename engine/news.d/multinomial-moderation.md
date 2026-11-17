* Moderation of an outcome in three or more unordered categories
  (`logistic_regression / multinomial_interaction`, new
  `R/backend-multinomial-interaction.R`): whether X's effect on the odds
  of each category against the first depends on W, in a multinomial
  logistic regression with X, W and X x W. No package computes its power,
  so Spower runs powerkit's experiment `p_multinomial_interaction()`
  around `nnet::multinom()`: the default test is the likelihood-ratio
  test of the K - 1 product terms (y ~ x * w against y ~ x + w), and the
  Wald z test of one category's product is an option
  (`target_test > method "wald_z"`, `category`). X and W are each a score
  or a yes/no group, correlated through `r_xw`. The population is given by
  the shares in each category at the starting point and, for each
  category but the first, the odds ratios for X and W and the ratio of
  odds ratios for X x W. A data set with an empty category counts as not
  significant. The check run recovers every coefficient; the exported
  script reproduces both tests; the minimum n allows ten people per
  coefficient. New example spec `multinomial_interaction.json`;
  validation in test-validation-multinomial-interaction.R (an independent
  simulation drawing the categories by the Gumbel-maximum rule and fitting
  the Poisson log-linear form in `stats::glm()`, Type I error with both
  main effects, a published-example placeholder), run in the `multinomial`
  chunk.
