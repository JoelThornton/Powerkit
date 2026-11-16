* The smallest detectable effect (a sensitivity analysis) for every
  formula test pwrss computes that lacked one: logistic and Poisson
  regression (the odds or rate ratio, the proportion of 'yes' or the base
  rate kept), one proportion (against its fixed value), McNemar's exact
  test (the proportion changing only in the second condition), two
  independent correlations (group 2's, searched on Fisher's z scale),
  goodness of fit (Cohen's w), the planned contrast and one- and two-way
  ANCOVA (the pattern of means kept and scaled), every ANOVA given by its
  partial eta-squared, and a two-way interaction given by its R-squared
  change. pwrss's power functions solve for n or power only, so
  `pwrss_sensitivity()` (new file `sensitivity-pwrss.R`) searches the
  effect with the package's own power call: power on a fixed grid from the
  smallest effect up, then `uniroot()` between the first grid value that
  reaches the target and the one before. Multiple regression's search
  (`regression_sensitivity()`, removed) moves to the same function. No
  new formula.
* The exported R script repeats that search (`pwrss_search_section()`),
  so it reproduces the result to the last digit; before, the script for
  multiple regression's smallest R-squared stopped with an error
  (`reproduced` was never defined).
* `test-sensitivity-pwrss.R` checks each against a calculation that does
  not use pwrss: G*Power's noncentral F for regression and the
  interaction, `pwr` for goodness of fit and the ANOVA from eta-squared,
  the exact binomial and McNemar tests and the contrast's noncentral t
  from `stats`, Fisher's z by its normal approximation, WebPower for
  logistic and Poisson regression, and a simulation of `glm()` for
  logistic regression.
