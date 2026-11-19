## 2026-11-19 · Replication plans: the "show it is absent" default and the reliability correction

Two method choices in the replication planner, recommended in the review
of its criteria, are kept as the defaults.

- **"Show it is absent".** A Bayesian t-test original (a Bayes factor or a
  posterior, for two groups, one group or pairs) is planned with the Bayes
  factor t-test for no effect; every other original with the equivalence
  test against the smallest effect that matters (d33 when none is entered
  and the original had a significance test). Both are planned for a true
  effect of zero, so their chance of showing absence is the one planned.
- **A changed measure's reliability.** When the replication's outcome
  measure is more or less reliable than the original's, the original's
  effect is attenuated by the square root of the ratio of the two
  reliabilities (Schmidt & Hunter, 1996): d directly, r through Fisher's
  z, the original's z kept the same in both. It is optional, stated on the
  result and in the methods paragraph, and small telescopes and BUCSS,
  which work in the original's own units, are left out when it is used.
