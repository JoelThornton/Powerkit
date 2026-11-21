# The cards whose smallest detectable effect is found by a simulated search:
# moderation, and factorial and multinomial logistic regression. The others are in
# test-smallest-effect-simulated-a.R.

test_that("moderation, and factorial and multinomial logistic regression, find the smallest effect by a simulated search", {
  cases <- list(
    list(ep = "E32", extra = list(odds_ratio_xw = ""), label = "the smallest interaction odds ratio you could detect", name = "interaction odds ratio = "),
    list(ep = "E15", extra = list(r_XW_Y = ""), label = "the smallest correlation of the interaction with Y you could detect",
      name = "is correlation of the interaction with Y = "),
    list(ep = "E70", extra = list(), label = "the smallest odds ratio you could detect", name = "odds ratio = "),
    list(ep = "E47", extra = list(), label = "the smallest odds ratio you could detect", name = "odds ratio = "),
    list(ep = "E47", extra = list(effect = "interaction"), label = "the smallest ratio of odds ratios you could detect",
      name = "ratio of odds ratios = ")
  )
  # Mediation on the moderation card has no smallest-effect goal.
  goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E32")))[[1]]
  expect_false(field_applies(list(shown_if = goal$choices_shown_if$sensitivity), list(analysis = "mediation")))
  for (case in cases) {
    n <- switch(case$ep, E47 = "420", E30 = "300", E45 = "24", E32 = "400", E70 = "400", E15 = "300", "100")
    run <- smallest_effect_run(case$ep, c(case$extra, list(n = n, simulation_accuracy = "quick")))
    expect_true(isTRUE(run$result$sensitivity$simulated), label = case$ep)
    expect_identical(result_figure(run$spec, run$result)$label, case$label)
    expect_match(result_sentences(run$spec, run$result)[["headline"]], case$name, fixed = TRUE)
    expect_false(is.na(usual_seconds(forms, case$ep, "sensitivity")), label = case$ep)
  }
})
