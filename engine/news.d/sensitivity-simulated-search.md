* The smallest detectable effect (goal `sensitivity`) for three simulated
  tests, by the simulated search the Hartung-Knapp meta-analysis uses
  (`simulated_effect_sensitivity()`): power is simulated at values of the
  effect around a starting guess, a probit curve fitted to the rejections,
  and the effect read where it reaches the target, with a 95% interval.
  - Two paired variances (the Pitman-Morgan test): the ratio of the first
    measurement's variance to the second's, the second's and the
    correlation kept.
  - A trend in proportions (the Cochran-Armitage test): the pattern of
    proportions scaled about its mean, reported as the difference between
    the highest and lowest; `simulated_scale_search()` gains a `limit`, so
    no proportion leaves 0 to 1. A flat pattern is refused plainly.
  - d' in two conditions: the second condition's average d', the first's
    and the rest kept.
  The exported scripts repeat the search. Tests: power simulated afresh at
  each effect found (4,000 replications, another seed) is within 0.04 of
  the target, and every script is run.
