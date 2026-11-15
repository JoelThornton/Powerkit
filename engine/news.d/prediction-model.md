* Prediction model development (E77): new design `prediction_model /
  development` and goal type `"criteria"`, the minimum sample size for
  developing a multivariable prediction model by the criteria of Riley et
  al. (2019), computed by pmsampsize's `pmsampsize()` (Suggests) for a
  binary, continuous or time-to-event outcome. Population: `metric`
  (`c_statistic`, `cox_snell_r2`, `nagelkerke_r2` or `r2`), the matching
  value, `parameters`, and `prevalence`, `mean` and `sd`, or `rate`,
  `timepoint` and `mean_follow_up`; goal: `shrinkage` (default 0.9) and,
  for a continuous outcome, `intercept_margin` (default 1.1). A
  C-statistic's conversion always uses pmsampsize's default seed (123456),
  recorded in the provenance. New file `backend-prediction-model.R`: spec
  checks, the result's `$prediction` (each criterion's sample size, the
  binding criterion, events and events per parameter), check run, R
  script and design description. Riley et al. (2019) is in refs.bib as
  `pmsampsize_method`. New validation chunk `prediction`: agreement with
  pmsampsize called directly, and the binary criteria from their closed
  forms.
* Prediction model validation (E77): template `prediction_model /
  validation`, the minimum sample size for validating an existing model of
  a binary outcome by the criteria of Riley et al. (2021), computed by
  pmvalsampsize's `pmvalsampsize()` (Suggests): precise O/E ratio,
  calibration slope, C-statistic and, given `population > threshold`,
  standardised net benefit. Population: `prevalence`, `c_statistic`,
  `lp_distribution` (`normal` with `lp_mean` and `lp_sd`, or `beta` with
  `beta_a` and `beta_b`), and optionally `oe`, `calibration_slope`,
  `threshold`, `sensitivity` and `specificity`; goal: `oe_ci_width`,
  `cslope_ci_width`, `cstat_ci_width` and `nb_ci_width` (pmvalsampsize's
  defaults). The linear predictor is simulated with pmvalsampsize's
  default seed and draws, recorded in the provenance. New file
  `backend-prediction-validation.R`; Riley et al. (2021) is in refs.bib as
  `pmvalsampsize_method`. The `prediction` chunk adds agreement with
  pmvalsampsize and the O/E and C-statistic criteria from their closed
  forms; pmvalsampsize's grid search for the O/E standard error is noted
  in docs/upstream-questions.md.
