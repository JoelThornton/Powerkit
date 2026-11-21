* App: a study plan's page and planning document check the shared
  sample size (`plan_shared_n()`). Each analysis the engine calculates
  in closed form is rerun at the largest separate requirement; when any
  falls short of its target, N is stepped up until every target is met,
  and each analysis's power is shown at both numbers. Power is not
  monotone in N for exact tests, so the largest separate answer can fall
  short: two one-proportion outcomes (.80 against .50 and .70 against
  .40, two-sided `binom.test()`) need 20 and 21 separately, reach 76.9%
  and 85.2% at 21, and first both reach 80% at 24. A simulated analysis
  leaves the N an unchecked candidate. The text says these are each
  test's own power, not the chance that all succeed in one study.
* App: a replication plan's agreement criterion reads as three outcomes
  (inside the bound, entirely beyond it, or crossing it: inconclusive),
  citing Lakens (2017), now in refs.bib as `TOSTER_method` in place of
  its placeholder.
