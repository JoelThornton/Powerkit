* Cochran's Q: power and sample size for a yes/no answer given once by
  every person in each of three or more conditions, as a test version of
  the repeated-measures generalised mixed model card
  (`mixed_model / repeated_glmm`, `target_test > method "cochran_q"`).
  No package computes its power, so Spower runs powerkit's experiment
  `p_repeated_cochran()`: the answers are drawn from the card's logistic
  model (each person's intercept from N(0, sd_person^2)), and each study is
  tested with `stats::friedman.test()` on the 0/1 answers, which is
  Cochran's Q (test-backend-glmm.R checks it against Q's own formula, and
  McNemar's test with two conditions). Its check run compares each
  condition's share of 'yes' across everyone with the share the model
  implies. `check_repeated_cochran()` refuses two conditions (McNemar's
  card), several answers per condition, groups and a between factor. New
  example spec `repeated_glmm_cochran.json`; validation in
  test-validation-cochran-q.R (an independent simulation computing Q from
  its formula, Type I error, a published-example placeholder), run in the
  `glmm` chunk. The exported script and the design line say Cochran's Q.
