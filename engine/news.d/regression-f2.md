* Engine: `convert_effect()` and a spec's `effect_justification >
  conversion` take Cohen's f-squared (`from: "f2"`) for multiple
  regression: into R-squared (`r2_zero`), the partial R-squared
  (`single_coefficient`), or R-squared with all the predictors given
  `population > r2_reduced` (`r2_increase`), with effectsize's
  `f2_to_eta2()`. New argument `r2_reduced`.
* App: the regression card (E24) offers "As Cohen's f-squared, as in
  G*Power" for the sample size and power goals; the result and write-up
  show the conversion.
