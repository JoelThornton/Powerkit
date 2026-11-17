* New: `target_test > covariate_model` for the ANCOVAs (`oneway_ancova`,
  `factorial_ancova`). "random", the default, is Shieh's (2020) method for
  covariates measured on each person (`power.f.ancova.shieh()`), as
  before; "fixed" plans covariates set by the design as G*Power does:
  pwrss's `power.f.ancova()` from the partial eta-squared of the adjusted
  means, with noncentrality N gamma^2. For one factor this equals pwrss's
  `power.f.ancova.keppel()`; the exported script reproduces it, and the
  ancova validation chunk checks it against lm()'s F test on simulated
  studies with fixed covariate values. An effect given as partial
  eta-squared is planned this way and refuses "random".
