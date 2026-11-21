* Validation: simulations written separately from each card's package for
  the equivalence tests (two one-sided `t.test()`s, two groups, pairs and
  one sample), the Mann-Whitney and signed-rank tests (one-sided
  `wilcox.test()` on skewed and heavy-tailed scores, unequal groups) and
  the logistic factorial (`glm()` with sum-to-zero contrasts, each
  effect's Wald chi-square), in `helper-independent-simulation.R`.
