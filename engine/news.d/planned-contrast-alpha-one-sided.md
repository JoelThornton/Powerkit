* The planned contrast (`factorial_anova/oneway_contrast`, E19) now uses
  the alpha the spec sets and offers a one-sided test. pwrss 1.3.3's
  `power.t.contrasts()` calls `power.t.test()` without its alpha when there
  are no covariates, so it gave the power at 0.05 whatever alpha it was
  passed (four groups of 5, means 1.5, 2, 3, 4, SD 2, a linear trend: 0.51
  at alpha 0.01, where the noncentral t gives 0.25). The engine passes the
  same noncentrality, the contrast over SD x sqrt(sum(weight^2 / group
  size)), and df, n - groups, to pwrss's `power.t.test()` with the alpha and
  sidedness asked for. At alpha 0.05, two-sided, results are unchanged. A
  one-sided test runs in the direction of the contrast; one pointing the
  other way is refused. The exported script, sensitivity search and check
  run follow (docs/upstream-questions.md, pwrss).
