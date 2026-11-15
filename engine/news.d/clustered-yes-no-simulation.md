* A clustered trial with a yes/no outcome (E34's cluster-randomised and
  multisite templates) can be planned by simulation as well as by
  powertools' `crt.parallel.bin()` and `multisite.bin()`: method
  `glmer_simulation` (`backend-cluster-glmer.R`) runs a Spower experiment
  that draws each group's log odds (cluster-randomised: a random
  intercept; multisite: a random effect of condition, coded +-1/2), fits
  `lme4::glmer()` and tests the condition with the Wald z test, one- or
  two-sided. It has no factor 1.2, so Known difference 16 is shown only
  for the formula, which stays the default (decisions.md, 15 November
  2026). Check runs at 400 groups recover the log odds ratio and the
  random-effect SD; the exported script reproduces the run; with full
  validation, the simulation agrees with the formula without the factor.
