* The smallest detectable effect (goal `sensitivity`) for five more
  formula tests, by the same search over the backend's own exact power at
  the fixed n (`formula_search_sensitivity()`). No new formula.
  - Two groups on an ordinal outcome (powertools' `propodds()`): the odds
    ratio, group 1's shares kept. With no odds ratio entered (1, which
    powertools refuses) the check run uses 2.
  - The log-rank test (Hmisc's `cpower()`): group 2's proportion with the
    event by the reference time, group 1's kept.
  - A Cox regression predictor (powerSurvEpi): the hazard ratio per SD.
  - Growth curves (longpower): the difference in rates of change, the SDs
    and correlation kept (Diggle's formula, or Hu, Mackey and Thomas's).
  - Reliability (the ICC by its F test or Walter's approximation,
    Cronbach's alpha by statpsych, kappa by kappaSize): the value the
    study could show is beyond the one named. The Bland-Altman limits are
    simulated and have no sensitivity analysis yet.
  Tests (`test-sensitivity-search.R`): Hmisc's `popower()`, which gives
  the same power from the shares pooled over the groups; powerSurvEpi's,
  statpsych's and kappaSize's own sample sizes at the value found;
  longpower's own solver for `delta`; simulations of the log-rank test
  (survival's `survdiff()`) and of the ICC's F test; every script is run.
