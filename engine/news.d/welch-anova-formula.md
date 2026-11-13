* Welch's one-way ANOVA (`target_test > method = "welch_f"`) is worked out
  by Levy's (1978) noncentral F approximation in base R's `stats::pf()`
  (new `backend-welch-anova.R`), as Jan and Shieh (2014) recommend and
  program it, instead of by simulation: power, sample size and the
  smallest detectable effect come at once and have no Monte Carlo error.
  Spower's simulation stays available with `options > method =
  "simulation"`. The approximation reproduces Jan and Shieh's published
  Levy powers (Tables 1 and 2) to four decimals, and agrees with Spower's
  simulation and with separately generated `stats::oneway.test()` studies
  within .01 plus Monte Carlo error (`test-backend-welch-levy.R`, the
  `welch_spreads` validation chunk). The exported script computes it in
  base R. New reference `Jan2014_welch_anova`.
