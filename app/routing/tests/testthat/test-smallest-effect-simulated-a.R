# The cards whose smallest detectable effect is found by a simulated search:
# paired variances, the trend tests, d', groups' correlations and an
# interrupted time series. Moderation and the logistic regressions are in
# test-smallest-effect-simulated-b.R.

test_that("paired variances, the trend tests, d', groups' correlations and an interrupted time series find the smallest effect by a simulated search", {
  cases <- list(
    list(ep = "E57", extra = list(var1 = ""), label = "the smallest variance ratio you could detect", name = "variance ratio = "),
    list(ep = "E66", extra = list(), label = "the smallest difference between the highest and lowest proportions you could detect",
      name = "difference between the highest and lowest proportions = "),
    list(ep = "E72", extra = list(d2 = ""), label = "the smallest difference in d' you could detect", name = "difference in d' = "),
    list(ep = "E64", extra = list(), label = "the smallest difference between the largest and smallest mean you could detect",
      name = "difference between the largest and smallest mean = "),
    list(ep = "E30", extra = list(), label = "the smallest difference between the largest and smallest group's correlation you could detect",
      name = "difference between the largest and smallest group's correlation = "),
    list(ep = "E45", extra = list(level_change = ""), label = "the smallest change in level you could detect", name = "change in level = ")
  )
  for (case in cases) {
    n <- switch(case$ep, E47 = "420", E30 = "300", E45 = "24", E32 = "400", E70 = "400", E15 = "300", "100")
    run <- smallest_effect_run(case$ep, c(case$extra, list(n = n, simulation_accuracy = "quick")))
    expect_true(isTRUE(run$result$sensitivity$simulated), label = case$ep)
    expect_identical(result_figure(run$spec, run$result)$label, case$label)
    expect_match(result_sentences(run$spec, run$result)[["headline"]], case$name, fixed = TRUE)
    expect_false(is.na(usual_seconds(forms, case$ep, "sensitivity")), label = case$ep)
  }
})
