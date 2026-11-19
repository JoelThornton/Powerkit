## 2026-11-19 · E25: the two-sided exact binomial test offers binom.test()'s p-value

Two-sided exact binomial tests form their p-value in different ways.
pwrss's `power.exact.oneprop()`, E25's default, puts alpha / 2 in each
tail; R's `binom.test()` adds up the probability of every count no more
likely than the one observed, so its tails need not hold half each. For
20% against a fixed value of 10% at alpha .05 the first n with 80% power is
94 by equal tails and 83 by `binom.test()`, and the card did not say which
it used.

- **Both are offered.** The test-version choice lists "alpha / 2 in each
  tail" and "the p-value R's binom.test() gives", because R users run the
  second and should plan for the test they will run.
- **Equal tails stays the default**, as the route E25's validation was
  built on; the write-up names the rule used for a two-sided test.
  One-sided, the two are the same test.
- **How it is computed.** No package computes `binom.test()`'s power, so
  it is summed over every count from `binom.test()`'s own steps
  (`backend-binom-test.R`), the approach `backend-corrected-exact.R` takes
  for `prop.test()`, with its p-values checked against `binom.test()` on
  every count. The engine's G*Power comparison for E25 uses a fixed value
  of 0.5, where the two rules agree; which rule G*Power uses for other
  fixed values is not checked yet.
