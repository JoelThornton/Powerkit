* Bayes factor for R-squared (E24): `multiple_regression / r2_zero` takes
  `target_test > method` `"bayes_factor"`, with `evidence_threshold` and
  `prior_scale` (default 0.354, JASP's Bayesian linear regression and
  BayesFactor's "medium"). New file `backend-bayesfactor-regression.R`:
  BayesFactor's `linearReg.R2stat()` rises with the regression's F, so the
  chance of strong evidence is the noncentral F (noncentrality f^2 n)
  beyond the F at which BF10 reaches the threshold, found by root-finding;
  the no-effect side from the central F. Check run against `lmBF()` on a
  data set with exactly the spec's R-squared; R script; spec checks. The
  schema now restricts `single_coefficient`'s methods to the four it
  supports. Validation: `test-validation-bayes-regression.R` in chunk
  `bayes`.
