* Known difference 16 is recorded and tested: powertools' `crt.parallel.bin()`
  and `multisite.bin()` multiply the variance of the log odds ratio by an
  unsourced 1.2, so a clustered yes/no design asks for about a sixth more
  groups than a `glmer()` simulation needs (28 against 24 groups in the
  example). `test-backend-powertools.R` shows the size.
* Known difference 17 is recorded and tested: the three-way interaction's
  fixed-model formula (`power_interaction_3way_r2()`) gives about 4 points
  more power than simulated studies with random predictors at the example's
  N (853 people: 80% against 76%; about 940 needed).
  `test-backend-three-way.R` shows the size.
* Cronbach's alpha: `docs/conventions.md` records that statpsych's formula
  plans Bonett's test about a point below its target power at typical sizes
  (84.1% at the example's 139 for 85%).
