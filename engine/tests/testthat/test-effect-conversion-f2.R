# Cohen's f-squared, G*Power's input for multiple regression, converted
# into the R-squared each regression template takes (12 November 2026).
# The power from the converted spec must equal the power from the
# R-squared values that give the same f-squared, and the noncentral F
# power with lambda = f^2 N.

f2_spec <- function(template, f2, goal = list(type = "power", n = 150), reduced = NULL) {
  spec <- example_spec(switch(template, single_coefficient = "regression_coefficient", paste0("regression_", template)))
  spec$options <- list(seed = 7)
  spec$goal <- goal
  effect <- switch(template, r2_zero = "r2", single_coefficient = "partial_r2", r2_increase = "r2_full")
  spec$population[[effect]] <- NULL
  if (!is.null(reduced)) spec$population$r2_reduced <- reduced
  spec$effect_justification$conversion <- list(from = "f2", value = f2)
  spec
}

analytic_power <- function(f2, df1, df2, n, alpha = 0.05) {
  1 - stats::pf(stats::qf(1 - alpha, df1, df2), df1, df2, ncp = f2 * n)
}

test_that("f-squared becomes R-squared, the partial R-squared, or R-squared with all the predictors", {
  expect_equal(convert_effect("f2", 0.15, "r2_zero")$value, 0.15 / 1.15)
  expect_equal(convert_effect("f2", 0.0588, "single_coefficient")$value, 0.0588 / 1.0588)
  # For a set: (R2_full - R2_reduced) / (1 - R2_full) gives back f-squared.
  full <- convert_effect("f2", 0.0588, "r2_increase", r2_reduced = 0.1)$value
  expect_equal((full - 0.1) / (1 - full), 0.0588)
  expect_match(convert_effect("f2", 0.0588, "r2_increase", r2_reduced = 0.1)$function_used, "effectsize::f2_to_eta2", fixed = TRUE)
  expect_error(convert_effect("f2", 0, "r2_zero"), class = "powerkit_spec_error")
  expect_error(convert_effect("f2", 0.1, "independent_t"), class = "powerkit_spec_error")
})

test_that("a regression given by f-squared has the power of the same f-squared given as R-squared", {
  spec <- f2_spec("r2_increase", 0.0588, reduced = 0.1)
  checked <- validate_spec(spec)
  expect_equal(checked$effect_justification$conversion$result, checked$population$r2_full)
  power <- run_spec(spec)$curve$power
  k_total <- checked$population$predictors_total
  k_tested <- checked$population$predictors_tested
  expect_equal(power, analytic_power(0.0588, k_tested, 150 - k_total - 1, 150), tolerance = 1e-8)

  zero <- f2_spec("r2_zero", 0.15)
  k <- validate_spec(zero)$population$predictors
  expect_equal(run_spec(zero)$curve$power, analytic_power(0.15, k, 150 - k - 1, 150), tolerance = 1e-8)

  one <- f2_spec("single_coefficient", 0.0588)
  one$target_test$method <- "f_test"
  one$population$variance_ratio <- NULL
  given <- example_spec("regression_coefficient")
  given$target_test$method <- "f_test"
  given$population$variance_ratio <- NULL
  given$options <- list(seed = 7)
  given$goal <- list(type = "power", n = 150)
  given$population$partial_r2 <- 0.0588 / 1.0588
  expect_equal(run_spec(one)$curve$power, run_spec(given)$curve$power, tolerance = 1e-10)
})

test_that("the sample size for f-squared 0.0588 with 2 of 5 predictors tested", {
  spec <- f2_spec("r2_increase", 0.0588, goal = list(type = "sample_size", power = 0.8), reduced = 0)
  spec$population$predictors_total <- 5
  spec$population$predictors_tested <- 2
  n <- run_spec(spec)$n_required$n
  # The smallest N whose noncentral F power reaches 0.8.
  expect_gte(analytic_power(0.0588, 2, n - 6, n), 0.8)
  expect_lt(analytic_power(0.0588, 2, n - 7, n - 1), 0.8)
})
