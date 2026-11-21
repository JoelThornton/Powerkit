## 2026-11-21 · One proportion: the z test offered beside the exact binomial test, its power summed over the counts

Many researchers test one proportion against a fixed value with the z test
(R's `prop.test()`, which applies the continuity correction by default, or
the equivalent chi-square test against the fixed value). E25's card named it as an alternative but offered only the exact
binomial tests, so a researcher who will run `prop.test()` planned for a
different test. Part of the audit of method choices (next.md item 25).

- **Choice:** E25 offers the z test without (`z_test`) and with
  (`z_test_corrected`) the continuity correction beside the two exact
  binomial tests. The exact binomial test with alpha / 2 in each tail stays
  preselected, as in G*Power and pwrss; nothing about the researcher's study
  decides between the tests, so the dropdown shows the default and the help
  says to choose the test that will be run.
- **Method:** power is the probability of every count times whether
  `prop.test()` rejects on it, summed, as for `binom.test()`'s rule (19
  November 2026) and the corrected two-proportion test (worked out exactly
  over every possible result). pwrss's `power.z.oneprop()` uses a normal
  approximation, which is off by a few percentage points either way and
  cannot show that the correction often changes no decision; the sum is the
  test's own power, with no random error. Recorded as Departure 36
  (conventions.md), with its size: 78 people against pwrss's 86 without the
  correction, 89 against 96 with it, for 20% against 10% at 80% power.
- **Not offered:** the Wald version of the z test (the standard error from
  the observed proportion). `prop.test()` and pwrss's default
  (`std.error = "null"`) use the standard error under the fixed value, the
  score test; the Wald version can be added if researchers ask for it.
