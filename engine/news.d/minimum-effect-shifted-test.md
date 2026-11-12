* Minimum-effect tests on the one-sample, paired and two-group t-tests are
  now planned as the test researchers run, `t.test(mu = margin)` (a
  central t shifted by the smallest effect of interest), as
  non-inferiority tests already are: pwrss's `power.t.student()` receives
  the effect minus the margin. pwrss's `margin` argument, used before,
  tests a margin fixed in SD units and asked for a few more people (282
  rather than 278 for d = 0.5, a margin of 0.2 and 80% power). Two-sided
  tests add the far tail from pwr's one-sided t-test. The smallest
  detectable effect is found by root-finding, and the R script reproduces
  every goal. Known difference 10 is retired.
