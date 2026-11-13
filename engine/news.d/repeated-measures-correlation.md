* New template `basic_test/repeated_measures_correlation` (card E76): the
  repeated-measures (within-person) correlation of Bakdash and Marusich
  (2017), for two scores measured together on several occasions. Power is
  a Pearson correlation's at the effective sample size N(k - 1) + 1, the
  method rmcorr's documentation gives, computed by the exact distribution
  of r (`pwrss::power.exact.onecor()`), as for the correlation card (new
  `backend-rmcorr.R`). Sample size (number of people), power and the
  smallest detectable correlation; the exported script reproduces each.
  Checked against `pwrss` directly, rmcorr's documented example (0.8159
  against its Fisher's z 0.8157), and simulated studies analysed by
  `lm(y ~ person + x)`, with the Type I error (new validation chunk
  `rmcorr`). New reference `Bakdash2017_rmcorr`.
