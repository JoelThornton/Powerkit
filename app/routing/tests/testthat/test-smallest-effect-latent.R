# Latent profiles and factor analysis: the smallest separation and loading,
# found by a simulated search.

test_that("latent profiles and factor analysis find their smallest separation and loading", {
  cases <- list(
    list(ep = "E58", extra = list(separation = ""), label = "the smallest separation between neighbouring profiles you could detect"),
    list(ep = "E73", extra = list(loading = ""), label = "the smallest loading you could detect")
  )
  for (case in cases) {
    run <- smallest_effect_run(case$ep, c(case$extra, list(n = "150", simulation_accuracy = "quick")))
    expect_true(isTRUE(run$result$sensitivity$simulated), label = case$ep)
    expect_identical(result_figure(run$spec, run$result)$label, case$label)
    expect_false(is.na(usual_seconds(forms, case$ep, "sensitivity")), label = case$ep)
  }
})
