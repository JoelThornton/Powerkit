# The Bayes factor for R-squared in a linear regression (BayesFactor's
# linearReg.R2stat(), JASP's r scale of 0.354), by exact calculation from
# the noncentral F.

reg_bf_spec <- function(n = NULL, r2 = 0.1, predictors = 3L, threshold = NULL, scale = NULL, power = 0.8) {
  spec <- example_spec("regression_r2_zero")
  spec$population <- list(metric = "r_squared", r2 = r2, predictors = predictors)
  spec$target_test <- list(effect = "r_squared", method = "bayes_factor", evidence_threshold = threshold, prior_scale = scale)
  spec$target_test <- Filter(Negate(is.null), spec$target_test)
  spec$goal <- if (is.null(n)) list(type = "sample_size", power = power) else list(type = "power", n = n)
  spec$options <- NULL
  spec
}

test_that("linearReg.R2stat() gives regressionBF()'s Bayes factor, with JASP's r scale of 0.354 by default", {
  inputs <- bfreg_inputs(reg_bf_spec(80))
  expect_equal(inputs$prior_scale, 0.354)
  set.seed(4)
  x <- matrix(stats::rnorm(240), 80)
  data <- data.frame(y = drop(x %*% c(0.3, 0.2, 0)) + stats::rnorm(80), x)
  fit <- summary(stats::lm(y ~ ., data))
  f_stat <- fit$fstatistic[["value"]]
  bf <- BayesFactor::extractBF(BayesFactor::lmBF(y ~ X1 + X2 + X3, data = data, rscaleCont = 0.354, progress = FALSE), logbf = TRUE)$bf
  expect_equal(bfreg_log_bf10(f_stat, 80, inputs), bf, tolerance = 1e-4)
  expect_equal(bfreg_r2_of_f(f_stat, 80, 3), fit$r.squared)
})

test_that("power is the chance of an F beyond the one where BF10 reaches the threshold", {
  spec <- reg_bf_spec(150)
  inputs <- bfreg_inputs(spec)
  f_star <- bfreg_f_at(log(10), 150, inputs)
  expect_equal(exp(bfreg_log_bf10(f_star, 150, inputs)), 10, tolerance = 1e-6)
  result <- run_spec(spec)
  expect_identical(result$provenance$backend, "BayesFactor")
  expect_equal(result$curve$power, stats::pf(f_star, 3, 146, ncp = inputs$f2 * 150, lower.tail = FALSE))
  expect_true(all(result$check_run$ok))
  expect_equal(result$bayes$misleading_evidence, stats::pf(f_star, 3, 146, lower.tail = FALSE))
  expect_gt(result$bayes$evidence_for_null, 0)
  # A higher threshold needs more evidence.
  expect_lt(run_spec(reg_bf_spec(150, threshold = 30))$curve$power, result$curve$power)
})

test_that("the sample size is the smallest reaching the target", {
  spec <- reg_bf_spec()
  result <- run_spec(spec)
  n <- result$n_required$n
  expect_gte(bfreg_power(bfreg_inputs(spec), n), 0.8)
  expect_lt(bfreg_power(bfreg_inputs(spec), n - 1), 0.8)
})

test_that("the data set for the check run has exactly the spec's R-squared", {
  data <- bfreg_exact_data(40, 4, 0.25)
  expect_equal(summary(stats::lm(y ~ ., data))$r.squared, 0.25)
})

test_that("the exported script reproduces the Bayes factor for R-squared", {
  skip_unless_scripts_can_run()
  spec <- reg_bf_spec(150)
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_match(paste(run$script, collapse = "\n"), "linearReg.R2stat", fixed = TRUE)
})

test_that("the Bayes factor for R-squared is refused where it doesn't apply", {
  spec <- reg_bf_spec(90)
  spec$target_test$alpha <- 0.05
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- reg_bf_spec(90)
  spec$target_test$prior_width <- 1
  expect_spec_problem(spec, "Cauchy prior on the coefficients")
  # The other regression templates have no Bayes factor version yet.
  coef <- example_spec("regression_coefficient")
  coef$target_test$method <- "bayes_factor"
  coef$target_test$alpha <- NULL
  expect_error(validate_spec(coef), class = "powerkit_spec_error")
})
