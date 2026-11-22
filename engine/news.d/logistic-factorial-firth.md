* The factorial logistic regression (`logistic_regression/factorial`,
  E47) offers Firth's penalised likelihood-ratio test (`target_test >
  method` "firth_likelihood_ratio"). `p_logistic_factorial_firth()` draws
  each study with Spower's `p_glm()`, fits it with logistf's `logistf()`
  and tests the effect's coefficients with `logistftest()`. With few events
  it keeps false positives near alpha (2 x 2, a 5% base rate, 20 per cell:
  2.9%, where the likelihood-ratio test ran at 6.5% and the Wald test at
  0.6%) without losing power. logistf joins Suggests and renv.lock. The
  app's form no longer preselects a test: the three test the same effect,
  so the researcher chooses the one they will run.
