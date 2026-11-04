test_that("effect exploration retains the scientific decision and design assumptions", {
  spec <- list(design = "basic_test", template = "independent_t",
    population = list(metric = "standardised", d = 0.6, margin = 0.2, effect_sd = 0.15),
    target_test = list(method = "minimum_effect", alpha = 0.05),
    options = list(), goal = list(type = "sample_size", power = 0.8))
  result <- list(goal_type = "sample_size", n_required = list(n = 128))
  received <- list()
  run <- function(s) {
    received[[length(received) + 1L]] <<- s
    list(n_required = list(n = 128), curve = data.frame(n = s$goal$n %||% 128, power = 0.8))
  }
  for (method in c("minimum_effect", "bayes_factor")) {
    spec$target_test$method <- method
    received <- list()
    explore_curve(spec, result, effect = 0.4, run = run)
    scenario_n(spec, result, conservative = 0.3, run = run)
    scenario_curves(spec, result, conservative = 0.3, run = run)
    expect_gt(length(received), 0)
    expect_true(all(vapply(received, function(s) identical(s$population$margin, 0.2), logical(1))))
    expect_true(all(vapply(received, function(s) identical(s$population$effect_sd, 0.15), logical(1))))
    expect_true(all(vapply(received, function(s) identical(s$target_test$method, method), logical(1))))
  }
  expect_identical(spec$population$d, 0.6)
})
