* The smallest detectable effect (goal `sensitivity`) for the
  meta-analysis's average effect and for structural equation models, by
  the same search over the backend's own power at the fixed n
  (`formula_search_sensitivity()`, `R/sensitivity-search.R`). No new
  formula.
  - Meta-analysis, average effect (metapower's z test): the average d or
    r, the typical study's size and I-squared kept. The Hartung-Knapp
    test, which powerkit simulates with metafor, searches the average
    effect by simulation (`simulated_effect_sensitivity()`, sharing
    `simulated_scale_search()` with Welch's F), with a 95% interval, and
    its exported script repeats the search. The other meta-analysis
    questions still refuse the goal plainly.
  - SEM model fit: the population RMSEA. For the test of exact fit
    (semPower) the smallest misfit it detects; for close fit (WebPower)
    the smallest RMSEA above the null value; for not-close fit the largest
    below it at which the test shows close fit. `population > rmsea` may
    be left out for this goal only (schema and `check_sem()`).
  - SEM factor correlation and latent slope (semPower): the correlation or
    the slope tested, the rest of the model kept, the slope within the
    values that keep the outcome's explained variance below 1
    (`sem_slope_limit()`). Invariance compares a pattern and still has no
    sensitivity analysis.
  Tests (`test-sensitivity-search.R`): metapower's z test against
  metafor's DerSimonian-Laird test on simulated meta-analyses, the
  Hartung-Knapp search against a fresh simulation at the effect found,
  the RMSEA against WebPower's own solver for `rmsea1` (to its default
  `uniroot()` tolerance), and the factor correlation and slope against
  semPower's own a-priori sample size at the value found; every script
  is run.
* `run_spec()`'s help says which tests have a sensitivity analysis.
