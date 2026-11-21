## 2026-11-21 · Informed priors for the Bayes factor t-tests, worked out exactly

- **Decided by the maintainer (17 November 2026):** plan Bayes factor
  t-tests with an informed analysis prior by an exact calculation in the
  engine, rather than waiting for a corrected `bfpwr::powertbf01()` or
  simulating studies.
- **What it covers.** E1, E2 and E3's Bayes factor version take a t
  analysis prior with any location, scale and degrees of freedom
  (`target_test > prior_location`, `prior_scale`, `prior_df`), as bfpwr's
  `tbf01()` defines it. Empty location and degrees of freedom keep the
  default JZS prior, which still goes to `powertbf01()`.
- **Method.** bfpwr's own Bayes factor; the t values where BF01 crosses
  the threshold found by root-finding (BF01 has one peak in t); the
  noncentral t distribution's chance beyond them; numerical integration
  over the normal design prior (`bayes-informed-t.R`). No simulation, so
  no random error, and a run takes a fraction of a second.
- **Departure 36** in docs/conventions.md records the difference from
  `powertbf01()` and its size.
