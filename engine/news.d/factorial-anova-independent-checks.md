* The factorial ANOVA cards beyond 2 x 2 (two factors between or within
  participants, and three factors) have validation checks independent of
  Superpower: studies drawn from the cell means, SD and correlation and
  analysed by `aov()`, with an Error() stratum per participant for within
  factors (`independent_factorial_power()` in
  helper-independent-simulation.R; chunk `anova`). Every effect agrees.
  The validation log now records the independent checks the survival,
  meta-analysis, reliability, trend and MANOVA cards already had.
