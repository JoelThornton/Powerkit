* The factorial logistic regression (`logistic_regression/factorial`,
  E47) offers the likelihood-ratio test (`target_test > method`
  "likelihood_ratio") beside the Wald test. `p_logistic_factorial_lr()`
  draws and fits each study with Spower's `p_glm()` and refits the model
  without the effect's columns of the sum-to-zero design matrix: the type
  III test `car::Anova(type = 3, test.statistic = "LR")` reports, which a
  unit test checks study by study. The app's form preselects it; the
  Wald test stays an option, and the engine's default when a spec names
  no test is unchanged. With
  sparse cells the Wald test loses power the likelihood-ratio test keeps
  (2 x 2, proportions 0.05, 0.1, 0.1, 0.7, 20 per cell: 17% against 30%).
  The exported script, check run, sensitivity search and the validation
  file (an independent `car::Anova()` simulation and a Type I error check)
  cover it.
