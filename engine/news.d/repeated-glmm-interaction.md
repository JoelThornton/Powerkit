* `mixed_model / repeated_glmm` (E75) takes two or more groups measured
  more than once: `variables > W`, a between factor, with X within
  people, `target_test > effect` `"interaction"`, and `rates`,
  `probabilities` or `odds_ratios` given one row per group of W (one
  value per condition of X; for ordered categories the first group's
  first condition is 1). The model is `y ~ group * cond + (1 | person)`,
  the people split equally between the groups, and the test is of
  `group:cond`: simr's `fixed("group:cond", "lr" or "chisq")` for
  Poisson and yes/no, and for negative binomial counts and ordered
  categories the likelihood-ratio test against `y ~ group + cond +
  (1 | person)` or the Wald chi-square test of the interaction terms, in
  `p_repeated_nb()` and `p_repeated_ordinal()` (new argument `groups`).
  `repeated_glmm_fixef()` solves for the treatment-coded fixed effects
  that reproduce every cell; the check run, the exported script and the
  simulated-data code follow the interaction model. Spec checks refuse
  rows of the wrong length, W not between people, X not within people,
  an interaction without W and, for a sample size, groups that change
  alike. New example spec `repeated_glmm_interaction.json`; the `glmm`
  validation chunk adds four interaction cases against a separately
  written simulation and a Type I check.
