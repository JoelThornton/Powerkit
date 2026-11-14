* The Bland-Altman limits of agreement are a new template,
  `reliability / bland_altman` (`population > metric` `"bland_altman"`,
  with `bias`, `sd_difference` and `margin`; `target_test > effect`
  `"limits_of_agreement"`, `method` `"mover"` (default),
  `"bland_altman"` or `"lu_formula"`, and `agree_level`, default 0.95).
  The simulated methods run powerkit's experiment `p_bland_altman()` in
  Spower, analysing each study with SimplyAgree's `agreement_limit()`
  (its `alpha` given alpha / 2, so the outer bounds are those of
  two-sided 1 - alpha intervals); `"lu_formula"` is SimplyAgree's
  `blandPowerCurve()`, clipped at 0. New backend file
  `backend-agreement.R` (backend name "SimplyAgree"). SimplyAgree joins
  Suggests and `renv.lock` (with patchwork). Planning for the simulated
  MOVER analysis rather than Lu et al.'s formula is Departure 27. Spec
  checks refuse limits that already reach the margin, and a calculation
  method that doesn't fit the chosen test version. The check run
  recovers the bias, the SD of the differences and the upper limit. The
  R script reproduces both routes. `refs.bib` gains SimplyAgree's paper
  (`SimplyAgree_method`), Bland and Altman (1999), Zou (2013) and Lu et
  al. (2016), the last cited for the formula route. Validation:
  `test-validation-agreement.R` (chunk `agreement`).
* In the app, `simulations > method_routes` accepts a list of test
  versions (E69's two simulated ones).
