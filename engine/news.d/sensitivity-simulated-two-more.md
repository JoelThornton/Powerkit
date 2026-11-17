* The smallest detectable effect (goal `sensitivity`) for two more
  simulated tests, by the simulated search
  (`simulated_effect_sensitivity()`), with a 95% interval:
  - The Jonckheere-Terpstra trend test: the pattern of group means is
    scaled about its average, the SD and the score shape kept, and the
    result is reported as the difference between the largest and smallest
    mean.
  - The factorial logistic regression (Wald test of one effect): the tested
    effect's coefficients on the log-odds scale (sum-to-zero coding) are
    scaled, the other effects kept. A main effect is reported as the odds
    ratio between the factor's levels with the most and the fewest 'yes',
    averaged over the other factor on the log-odds scale; the interaction
    as the largest ratio of odds ratios over any two levels of each factor
    (in a 2 x 2 design, the ratio of the odds ratios).
  A flat pattern is refused plainly. The exported scripts repeat the
  search. Tests: power simulated afresh at each effect found (4,000
  replications, another seed) is within 0.04 of the target, every script
  is run, and the reported odds ratios are checked by hand.
