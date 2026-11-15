* Bayes factor ANCOVA (E23): `factorial_anova / oneway_ancova` and
  `factorial_ancova` take `target_test > method` `"bayes_factor"`, with
  `evidence_threshold`, `prior_scale` (default 0.5), the new
  `prior_scale_covariates` (default 0.354) and `inclusion`, JASP's
  Bayesian ANCOVA defaults. New file `backend-bayesfactor-ancova.R`:
  Spower runs `p_bayes_ancova()`, which draws equal cells and independent
  standard normal covariates explaining `r2_covariates` within cells, and
  scores each study with BayesFactor's `generalTestBF(whichModels =
  "withmain")` and bayestestR's `bayesfactor_inclusion()`; the no-effect
  side with the effect removed from the cell means. Check run, spec
  checks (no `eta_squared` metric), R script and design description.
  Validation: `test-validation-bayes-ancova.R`, new chunk `bayes_ancova`,
  against every model fitted with `lmBF()` and the inclusion Bayes factor
  averaged by hand.
