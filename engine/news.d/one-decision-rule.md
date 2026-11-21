* App: the decision an analysis commits the researcher to (its test name
  with version and correction, direction, bounds, what counts as success
  and how to read each outcome) is built once, in `decision-rule.R`, and
  used by the planning document, a study plan's target column and its
  Registered Report table. Before, the table called a non-inferiority test
  TOST, a validation plan's target said developing with shrinkage 0.9, the
  one-proportion z test was named as the exact binomial test, the test of
  not-close fit was called a test of exact fit, and factor recovery and
  profile selection read "a significance test at alpha = ,". A one-way
  ANOVA's F test is no longer called two-sided. The ethics paragraph of a
  minimum-effect test gives the chance of showing the effect is larger
  than the smallest effect of interest. `methods_test_name()` moves the
  methods paragraph's test naming out of `writeup_text()`.
