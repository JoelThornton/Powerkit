* Bayes factor three-factor ANOVA (E56): `factorial_anova /
  factorial_three` takes `target_test > method` `"bayes_factor"`, with
  `evidence_threshold`, `prior_scale` (default 0.5) and `inclusion`, JASP's
  Bayesian ANOVA defaults. New file `backend-bayesfactor-three.R`: Spower
  runs `p_bayes_three()`, which draws equal groups across the between
  factors, each person scored in every within cell with their own level
  (correlation `r`), and scores each study with BayesFactor's
  `anovaBF(whichModels = "withmain")` (participants a random factor with
  a within factor) and bayestestR's `bayesfactor_inclusion()`; the
  no-effect side removes the effect from the cell means by the
  equal-weight decomposition. Check run, spec checks (no `eta_squared`
  metric, no sphericity correction), R script and design description. New
  validation chunk `bayes_three`.
