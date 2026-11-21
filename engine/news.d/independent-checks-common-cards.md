* Validation: simulations written separately from each card's package
  (`helper-independent-simulation.R`) for moderation in regression
  (`lm()`, with and without measurement error), the ordinal outcome in two
  groups (`MASS::polr()`, both directions of the shift, uneven shares,
  unequal groups), one-way repeated measures and the mixed ANOVA
  (`aov()` with an Error stratum). The record of which cards have a check
  independent of their backend is in docs/validation-log.md.
