* Two variances: the input screen preselects the Brown-Forsythe test
  (Departure 32), with Levene's test and the F test in the same dropdown;
  the direction question is shown for the F test only, and for McNemar's
  exact test only on the McNemar card. A spec naming `f_var` is unchanged.
  `test-backend-levene.R` measures the departure's size (with normal
  scores, 0.466 against the F test's 0.518 at 200 people).
* The analysis search finds Levene's test, the Brown-Forsythe test of
  equal variances, the F test of two variances and McNemar's three tests
  by name (tree.yaml `test_versions`), opening the input screen with that
  test chosen.
