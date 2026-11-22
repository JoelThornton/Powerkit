* Multiple regression's Bayes factors (`multiple_regression`, method
  `bayes_factor`) take `target_test > predictor_model` too, measured
  ("random") by default (Departure 39). R-squared against 0 stays exact:
  the chance of an F past the one where BF10 reaches the threshold,
  averaged over the chi-square distribution of its noncentrality
  (`regression_measured_tail()`). The R-squared increase and one
  coefficient draw each simulated study's two noncentralities before its
  sums of squares (`regression_measured_draw()`), checked against `lm()`
  on new normal predictors. The exported scripts follow the setting,
  Shieh (2007) is cited beside BayesFactor's method paper, and the
  validation chunks `bayes` and `bayes_r2change` add `lmBF()` on data sets
  with new normal predictors in each; their earlier cases now set
  `predictor_model = "fixed"`.
