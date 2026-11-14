* Yuen's trimmed-means tests are a test version of the two-group and
  paired t-tests (`target_test > method` `"yuen"` on templates
  `independent_t` and `paired_t`), simulated with Spower by powerkit's
  experiments `p_yuen()` and `p_yuend()`, which call WRS2's `yuen()` and
  `yuend()` (WRS2 joins Suggests). New spec fields: `target_test > trim`
  (default 0.2, WRS2's default) and, for the paired version,
  `population > r`, the correlation between the two measurements, which
  it needs because it trims each measurement separately. The two-group
  version takes `score_shape` and `sd_ratio` as the Brunner-Munzel test
  does. The check run recovers d (or d_z), the SD ratio and the
  correlation, the last with a standard error from r's influence
  function so that heavy-tailed scores don't fail it. The R script and
  the simulated data set cover both versions. Validation:
  `test-validation-yuen.R` (chunk `yuen`).
