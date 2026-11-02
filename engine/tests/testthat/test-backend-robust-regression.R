# One regression coefficient (template single_coefficient): the usual
# test by pwrss's formula, and the same coefficient tested with HC3 or HC4
# standard errors or by quantile regression, simulated with Spower by
# powerkit's experiment p_coefficient(). Translation, check run, refusals
# and the exported script; accuracy is checked by
# test-validation-robust-regression.R.

coef_spec <- function(method = "ols_hc3", n = 150, nrep = 100, ratio = 2, shape = NULL, quantile = NULL, partial_r2 = 0.05, k = 3) {
  spec <- example_spec("regression_coefficient")
  spec$target_test$method <- method
  spec$population <- list(metric = "r_squared", partial_r2 = partial_r2, predictors_total = k)
  if (method != "f_test") {
    spec$population$variance_ratio <- ratio
    spec$population$error_shape <- shape
    spec$population$quantile <- quantile
  }
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("the usual test of one coefficient is pwrss's F test of one predictor", {
  result <- run_quietly(coef_spec("f_test"))
  expect_equal(result$provenance$backend, "pwrss")
  increase <- example_spec("regression_r2_increase")
  # Partial R-squared 0.05 is an R-squared increase from 0.2 to 0.24 when
  # one of three predictors is tested.
  increase$population <- list(metric = "r_squared", r2_full = 0.24, r2_reduced = 0.2, predictors_total = 3, predictors_tested = 1)
  increase$goal <- list(type = "power", n = 150)
  expect_equal(result$curve$power, run_quietly(increase)$curve$power, tolerance = 1e-10)
})

test_that("robust standard errors and quantile regression run on Spower, and pass their check runs", {
  for (method in c("ols_hc3", "ols_hc4", "quantile_regression")) {
    result <- run_quietly(coef_spec(method, shape = if (method == "quantile_regression") "skewed"))
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "p_coefficient", fixed = TRUE)
    expect_true((if (method == "quantile_regression") "quantreg" else "car") %in% names(result$provenance$packages), info = method)
    expect_true(all(result$check_run$ok), info = method)
  }
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  set.seed(7)
  direct <- Spower::Spower(p_coefficient(n = 150, partial_r2 = 0.05, predictors = 3, variance_ratio = 2, shape = "normal",
    method = "ols_hc4"), replications = 100, verbose = FALSE)
  expect_equal(run_quietly(coef_spec("ols_hc4", shape = "normal"))$curve$power, direct$power)
})

test_that("the data have the spec's slope, spread and quantile", {
  big <- with_seed(3, coefficient_data(2e5, 0.2, 2, variance_ratio = 4, shape = "skewed"))
  fit <- stats::lm(y ~ x + z1, data = big)
  expect_equal(unname(stats::coef(fit)["x"]), 0.5, tolerance = 0.02)
  expect_equal(mean(stats::residuals(fit)^2), 1, tolerance = 0.03)
  above <- abs(big$x - 1) < 0.05
  below <- abs(big$x + 1) < 0.05
  expect_equal(stats::var(stats::residuals(fit)[above]) / stats::var(stats::residuals(fit)[below]), 4, tolerance = 0.1)
  # For quantile regression the error's quantile is 0: the outcome's
  # 0.75 quantile at x = 0 is 0.
  q <- with_seed(4, coefficient_data(2e5, 0.2, 1, shape = "heavy_tailed", quantile = 0.75))
  expect_equal(unname(stats::quantile(q$y[abs(q$x) < 0.05], 0.75)), 0, tolerance = 0.03)
})

test_that("the error's spread and shape belong to the simulated tests, and the quantile to quantile regression", {
  spec <- coef_spec("f_test")
  spec$population$variance_ratio <- 2
  expect_spec_problem(spec, "'population > variance_ratio' (the spread of the errors) is only used by the simulated tests")
  spec <- coef_spec("f_test")
  spec$population$error_shape <- "skewed"
  expect_spec_problem(spec, "'population > error_shape' (the shape of the errors) is only used by the simulated tests")
  spec <- coef_spec("ols_hc3", quantile = 0.5)
  expect_spec_problem(spec, "'population > quantile' is only used by quantile regression")
  spec <- example_spec("regression_r2_zero")
  spec$target_test$method <- "ols_hc3"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- coef_spec("ols_hc3")
  spec$target_test$alternative <- "greater"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("the R script reproduces the run, and the simulated data have the outcome and every predictor", {
  skip_unless_scripts_can_run()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (method in c("ols_hc3", "quantile_regression")) {
    spec <- coef_spec(method, n = 80, nrep = 100, shape = "heavy_tailed", quantile = if (method == "quantile_regression") 0.25)
    out <- run_exported_script(spec, run_quietly(spec))
    expect_equal(out$reproduced, out$powerkit, info = method)
  }
  data <- simulated_data(coef_spec("ols_hc3"), 200)
  expect_named(data, c("SIMULATED_NOT_REAL_DATA", "participant", "Hours_of_sleep", "Other_1", "Other_2", "Wellbeing_score"))
  expect_equal(nrow(simulated_data(coef_spec("f_test"), 50)), 50)
})
