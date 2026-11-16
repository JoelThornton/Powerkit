* `repeated_ordinal_wald()` (E75, ordered categories in two or more
  groups, Wald test) tests the group-by-condition terms on their own
  degrees of freedom, (groups - 1) x (conditions - 1), rather than
  conditions - 1. With three groups the old test rejected about 17% of
  null studies at alpha .05 and overstated power; a null-rate test with
  three groups now covers it.
* `pwr_sensitivity_p2()` (E5, two proportions, smallest detectable
  effect) starts its search just past `p1`, so unequal groups no longer
  stop with pwrss's "The value of margin should be different from the
  prob1 - prob2 difference".
* The Bayes factor methods paragraphs and exported scripts call the
  Bayes factor the study should reach its evidence threshold ("the
  evidence threshold is BF10 of at least 10"), as the cards do, rather
  than "strong evidence".
