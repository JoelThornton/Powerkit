* Multiple regression's F tests (`multiple_regression`, templates
  `r2_zero`, `r2_increase` and `single_coefficient`, method `f_test`) take
  the predictors as measured by default (`target_test > predictor_model`
  "random", Departure 39): power is the fixed-predictor power averaged over
  multivariate normal predictors, the noncentral F's tail integrated over
  the chi-square distribution of its noncentrality (Shieh, 2007;
  `R/regression-measured.R`), computed in base R (backend "stats").
  `predictor_model = "fixed"` keeps pwrss's `power.f.regression()`, G*Power's
  fixed model. The exported script computes the same integral. The
  validation chunk `formula` checks both against `lm()` on simulated
  studies, with new predictors in each study and with the same ones.
  Shieh (2007) and Gatsonis and Sampson (1989) are added to refs.bib.
