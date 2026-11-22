* Three-way interaction (E31): the three-way effect is labelled as what
  InteractionPoweR's `b.x1x2x3` is, the coefficient of the product of the
  standardised X, W and Z (Y standardised too), not the product's fully
  standardised coefficient, in the input screen, schema, sensitivity
  wording and R script. A population built separately on that meaning
  reproduces InteractionPoweR's R-squared with and without XWZ
  (`test-validation-three-way.R`). Known difference 17 is re-measured on
  that meaning: the formula's 853 for 80% gives about 78% in simulated
  studies (not 76%), and about 900 people are needed (not 940).
