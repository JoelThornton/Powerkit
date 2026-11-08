* New: `population > tau` on the one-sample, two-group and paired t-test
  templates plans for a true effect that varies between studies, with the
  given SD in d (d_z for pairs) around the planned average effect, following
  Kenny and Judd (2019). Power is pwr's own t-test power given their
  effective significance level and adjusted effect, for power, the sample
  size and the smallest detectable effect. Results record it in
  `result$heterogeneity` (tau, the effective alpha, q, and the power with
  and without the variation), and the R script reproduces it with pwr alone.
  It reproduces Kenny and Judd's worked example and agrees with an
  independent simulation. Student's t-test, or Welch's with equal SDs, by
  formula; not with rank tests, Bayes factors, simulation or small
  telescopes. Empty or 0 leaves the usual analysis unchanged.
