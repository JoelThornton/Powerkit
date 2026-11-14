* A Greenhouse-Geisser or Huynh-Feldt corrected F test whose effect is
  not spherical (Greenhouse-Geisser epsilon below 1) is simulated by
  default with `Superpower::ANOVA_power()` (Departure 27). Superpower's
  `ANOVA_exact()` multiplies the noncentrality and degrees of freedom by
  epsilon. That is an approximation, which missed the corrected test's
  simulated power by -3.2 to +3.3 points (`docs/validation-log.md`,
  14 November 2026). It stays available with `options > method =
  "exact"`, and it still finds the smallest detectable effect: the
  backend's new `sensitivity_method`. The backend reads the population
  epsilon from afex's sphericity corrections on the exact dataset
  (`superpower_gg_epsilon()`). The MANOVA approach is still reported
  beside the simulated test, from the exact dataset. Spherical designs
  and uncorrected tests are unchanged.
* App: the one-way repeated-measures, mixed and two-factor within cards
  start "How power is worked out" at simulation once the SDs or
  correlations differ and a correction is chosen (`gg_method`). The
  exact dataset, chosen or used for the smallest detectable effect,
  puts a warning above the answer; Departure 27 is listed when the test
  is simulated. Departure 3 is no longer listed for a simulated ANOVA.
* The nightly mixed-design GG failure is explained by the approximation
  above. The binary-X moderated-mediation null failure comes from its
  fixed seed: the true rate is 5.38% in 20,000 studies.
  `docs/upstream/superpower-gg-grid.R` is the independent check.
