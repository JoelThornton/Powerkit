* The smallest detectable effect (goal `sensitivity`) for more formula
  tests, found by searching the backend's own exact power over the effect
  at the fixed n, as for pwrss's tests: the first grid point that reaches
  the target, then `uniroot()` (`formula_search_sensitivity()`, new
  `R/sensitivity-search.R`; `pwrss_search_root()`). No new formula.
  - Two dependent correlations (Steiger's z, pwrss): the second
    correlation, the others kept, within the values that keep the
    correlation matrix positive definite (`dependent_correlation_range()`).
  - One and two variances (stats, the G*Power manual's chi-square and F
    distributions): the ratio of the variances, on the side the test
    looks at.
  - One-sample Hotelling's T-squared and the two-group MANOVA by its means:
    the Mahalanobis distance, the pattern of means scaled. MANOVA given by
    Pillai's V already had it in the engine; the card now offers it.
  - Equivalence tests (TOSTER, all five versions): the narrowest
    equivalence bounds the test shows with the target power, the expected
    difference kept. `population > bound` may be left out for this goal
    only (schema and `check_equivalence_test()`); TOSTER's check run then
    checks the expected difference alone.
  The exported R script repeats each search with its own `power_at()`
  (`formula_search_section()`, sharing `search_section()` with pwrss's).
  Tests: `test-sensitivity-search.R` checks each against a simulation of
  the test itself (`psych::r.test()`, `var.test()`, Spower's Hotelling
  simulation, two one-sided `t.test()`s and Fisher z tests) and runs all
  eleven scripts. Steiger's z: pwrss's asymptotic power, as G*Power's, is
  about 0.03 below the test's simulated rejection rate at both the entered
  and the found correlations.
