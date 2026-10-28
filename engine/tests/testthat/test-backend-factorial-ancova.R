# Two-way ANCOVA (template factorial_ancova): two between-participants
# factors, adjusting for covariates, by pwrss's power.f.ancova.shieh()
# (Shieh's method) with the effect's rows of pwrss's factorial.contrasts().
# Checked against pwrss called directly and against Superpower's
# ANCOVA_analytic(), which also uses Shieh's method.

ancova_example <- function(goal, effect = "interaction", ...) {
  spec <- example_spec("anova_factorial_ancova")
  spec$options <- list(seed = 7, ...)
  spec$goal <- goal
  spec$target_test$effect <- effect
  spec
}

# The example's adjusted cell means, A1:B1, A1:B2, A1:B3, A2:B1, ...
example_mu <- c(20, 20, 20, 16, 17, 18)
# pwrss prints the order of the cells even with verbose = 0.
quiet_pwrss <- function(expr) {
  utils::capture.output(value <- suppressMessages(expr))
  value
}
rows <- c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")

test_that("the two-way ANCOVA runs on pwrss, exactly, and passes its check run", {
  result <- run_spec(ancova_example(list(type = "power", n = 120)))
  expect_equal(result$provenance$backend, "pwrss")
  expect_equal(result$provenance$backend_function, "pwrss::power.f.ancova.shieh")
  expect_true(all(result$check_run$ok))
})

test_that("each effect equals pwrss called directly with its contrast rows", {
  full <- quiet_pwrss(pwrss::factorial.contrasts(factor.levels = c(2, 3), intercept = FALSE, verbose = 0))$contrast.matrix
  picks <- list(main_effect_A = "A1", main_effect_B = c("B1", "B2"), interaction = c("A1:B1", "A1:B2"))
  for (effect in names(picks)) {
    direct <- quiet_pwrss(pwrss::power.f.ancova.shieh(
      mu.vector = example_mu, sd.vector = rep(6, 6), n.vector = rep(20, 6), factor.levels = c(2, 3),
      r.squared = 0.36, k.covariates = 1, contrast.matrix = full[picks[[effect]], , drop = FALSE],
      alpha = 0.05, ceil.n = FALSE, verbose = 0
    ))
    power <- run_spec(ancova_example(list(type = "power", n = 120), effect = effect))$curve$power
    expect_equal(power, direct$power, label = effect)
  }
  # pwrss's own default with factor.levels tests the interaction.
  default <- quiet_pwrss(pwrss::power.f.ancova.shieh(
    mu.vector = example_mu, sd.vector = rep(6, 6), n.vector = rep(20, 6), factor.levels = c(2, 3),
    r.squared = 0.36, k.covariates = 1, alpha = 0.05, ceil.n = FALSE, verbose = 0
  ))
  expect_equal(run_spec(ancova_example(list(type = "power", n = 120)))$curve$power, default$power)
})

test_that("each effect agrees with Superpower's ANCOVA_analytic()", {
  skip_if_not_installed("Superpower")
  other <- Superpower::ANCOVA_analytic(
    design = "2b*3b", mu = example_mu, n = 20, sd = 6, r2 = 0.36, n_cov = 1, alpha_level = 0.05
  )$main_results
  for (effect in names(rows)) {
    power <- run_spec(ancova_example(list(type = "power", n = 120), effect = effect))$curve$power
    expect_equal(power, other$power[other$factor == rows[[effect]]] / 100, tolerance = 1e-4, label = effect)
  }
})

test_that("the two-way ANCOVA finds a sample size in whole cells", {
  result <- run_spec(ancova_example(list(type = "sample_size", power = 0.8), effect = "main_effect_A"))
  n <- result$n_required$n
  expect_equal(n %% 6, 0)
  expect_lt(run_spec(ancova_example(list(type = "power", n = n - 6), effect = "main_effect_A"))$curve$power, 0.8)
  expect_gte(run_spec(ancova_example(list(type = "power", n = n), effect = "main_effect_A"))$curve$power, 0.8)
})

test_that("the two-way ANCOVA refuses plainly what it can't do", {
  spec <- ancova_example(list(type = "power", n = 100))
  expect_spec_problem(spec, "split into 6 equal groups, one per cell")
  spec <- ancova_example(list(type = "power", n = 120))
  spec$population$means <- list(list(20, 20), list(16, 17))
  expect_spec_problem(spec, "should have 2 rows (one per level of Intervention (A)), each with 3 means")
  spec <- ancova_example(list(type = "power", n = 120), method = "simulation")
  expect_spec_problem(spec, "'simulation' isn't available for this test yet")
})

test_that("the two-way ANCOVA: exported scripts reproduce powerkit's results", {
  skip_on_cran()
  for (effect in names(rows)) {
    spec <- ancova_example(list(type = "power", n = 120), effect = effect)
    out <- run_exported_script(spec, run_spec(spec))
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, label = effect)
  }
  spec <- ancova_example(list(type = "sample_size", power = 0.8), attrition = 0.1)
  out <- run_exported_script(spec, run_spec(spec))
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
})
