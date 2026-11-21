* The repeated-measures card for a count, a yes/no answer or ordered
  categories (`mixed_model` / `repeated_glmm`, E75) and Cochran's Q (E78)
  find the smallest detectable effect by the simulated search
  (`repeated_glmm_search()`, `simulated_effect_sensitivity()`). The
  conditions' differences on the model's scale (log rates, log odds or log
  odds ratios of a higher category) are multiplied by the scale, the first
  condition kept; with groups, only the group-by-condition interaction
  coefficients (treatment coding) are, so the groups' and conditions' own
  differences are kept. The result is the rate or odds ratio between the
  conditions furthest apart, or the largest ratio of ratios between two
  groups and two conditions (`ratio_of_rate_ratios`,
  `ratio_of_odds_ratios`). The person SD, category shares and
  overdispersion are kept, and the search stops where two cells would be
  1,000 times apart. The exported scripts' `set_effect()` repeats the
  change, recomputing simr's fixed effects with groups.
