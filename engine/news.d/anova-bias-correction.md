* Engine: a design spec for an ANOVA without covariates whose effect is
  one earlier study's F (`effect_justification > conversion` from "F",
  with both dfs) can ask for `effect_justification > bias_correction`
  (the earlier study's total `n`, and whether it was `published` because
  it was significant). With the goal `sample_size`, the result's new
  `bias_correction` is BUCSS's sample sizes at 50% and 80% assurance,
  corrected for publication bias and uncertainty (Anderson, Kelley &
  Maxwell, 2017), through `replication_bucss()`; the plan's own result
  still uses the F as published. Refused in plain words for an ANCOVA or
  an F whose df doesn't match the design (`bias-correction.R`,
  test-bias-correction.R).
* Engine: safeguard power now also covers an ANOVA or ANCOVA given by one
  earlier study's F: the plan uses the lower end of the two-sided
  interval around its partial eta-squared, from effectsize's
  `F_to_eta2()` (new `safeguard_eta_squared()`; test-safeguard-anova.R).
* App: on the ANOVA and ANCOVA screens, an effect from one earlier
  study's F asks how to plan from it, with nothing chosen: BUCSS's
  correction (first, for a sample size, not on the ANCOVAs), safeguard
  power, or the F as published; the result and the write-up say which
  (`bias_correction_fields()`, `bias_correction_sentence()`;
  test-bias-correction-screen.R).
