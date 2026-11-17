* Fixed: the ordinal outcome in two groups (E29) shifted group 2 the wrong
  way in `powertools::propodds()`. powertools takes group 1's shares from
  best to worst and shifts group 2 towards the first category; powerkit
  passed its shares lowest first, so an odds ratio above 1, which powerkit
  defines as group 2 tending to higher categories, was planned as group 2
  tending to lower ones. Whitehead's variance uses the two groups' average
  shares, so with uneven shares the answer was wrong: with group 1's shares
  .7, .2 and .1, an odds ratio of 2.5 and 50 per group, power was .477
  where it is .634 (a simulation of the Wilcoxon-Mann-Whitney test on the
  same population gives about .63, and of the proportional-odds model's
  Wald and likelihood-ratio tests about .65). An odds ratio above 1 now
  passes the shares highest first; one below 1 passes them as given with
  the reciprocal (`propodds_inputs()`). The input screen no longer says
  power is the same for an odds ratio and its reciprocal, and the R script
  says which order it passes. With even shares the change is small.
