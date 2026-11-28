## 2026-11-28 · One earlier study's F on the ANOVA screens

When an ANOVA or ANCOVA effect comes from one earlier study's F, the screen
asks how to plan from it, with nothing chosen, and offers both corrections:
BUCSS's correction for publication bias and uncertainty (Anderson, Kelley &
Maxwell, 2017) first, and safeguard power (Perugini, Gallucci & Costantini,
2014) second, beside planning from the F as published.

- BUCSS corrects for both sources of inflation in a published estimate. It
  gives a sample size, so it is offered for that goal and shown beside the
  plan's own sample size. It is not offered on the ANCOVAs, because BUCSS has
  no design with covariates. It assumes the earlier study had the same design,
  and refuses an F whose degrees of freedom don't match.
- Safeguard power works for every goal and on the ANCOVAs. It plans with the
  lower end of the two-sided interval around the partial eta-squared
  (effectsize's `F_to_eta2()`), as the t-tests do for d and r. It corrects
  for uncertainty, not for publication bias.

Why: a partial eta-squared from one published study is the most inflated
effect a plan can start from, and the ANOVA screens could only warn about it.
Offering both keeps the choice with the researcher, with the method that
corrects for publication bias listed first.
