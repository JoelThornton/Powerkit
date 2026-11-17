* `r2_increase` and `single_coefficient` take `target_test.method`
  "bayes_factor" (`backend-bayesfactor-r2change.R`): the Bayes factor of
  the full model against the model without the tested predictors, each
  model's Bayes factor from BayesFactor's `linearReg.R2stat()`, simulated
  from the three independent sums of squares of a regression with fixed
  predictors. The chance of evidence for no increase and of misleading
  evidence come from studies with no increase. `single_coefficient`
  takes `population.r2_reduced`, the R-squared of the other predictors,
  which this Bayes factor needs. Validation chunk `bayes_r2change`.
