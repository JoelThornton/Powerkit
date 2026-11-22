# Validation: the Bayes factor for an R-squared increase and for one
# coefficient in a linear regression (the full model against the model
# without the tested predictors, BayesFactor's linear-regression Bayes
# factors, JASP's default r scale of 0.354).
#   1. a published example (placeholder for the maintainer)
#   2. agreement with simulation from the data: data sets drawn from a
#      regression with predictors measured on each person (the default,
#      Departure 39: new normal predictors in every data set) or set by
#      the design (the same values in every data set, so each model's sum
#      of squares has the F test's noncentrality), each one's Bayes factor
#      computed by lmBF() on the data for the full and the reduced model,
#      and the share passing the threshold compared with powerkit's
#      estimate
#   3. the no-effect side, simulated the same way with the tested
#      coefficients 0
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

r2c_validation_spec <- function(template, n, r2_full, r2_reduced, p, q, threshold = 10, scale = 0.354, nrep = validation_nrep(),
                                predictor_model = "fixed") {
  if (identical(template, "single_coefficient")) {
    spec <- example_spec("regression_coefficient")
    spec$population <- list(metric = "r_squared", partial_r2 = (r2_full - r2_reduced) / (1 - r2_reduced),
      predictors_total = p, r2_reduced = r2_reduced)
    spec$target_test <- list(effect = "coefficient", method = "bayes_factor", evidence_threshold = threshold, prior_scale = scale)
  } else {
    spec <- example_spec("regression_r2_increase")
    spec$population <- list(metric = "r_squared", r2_full = r2_full, r2_reduced = r2_reduced,
      predictors_total = p, predictors_tested = q)
    spec$target_test <- list(effect = "r_squared_change", method = "bayes_factor", evidence_threshold = threshold, prior_scale = scale)
  }
  spec$target_test$predictor_model <- predictor_model
  spec$options <- list(nrep = nrep, seed = 20261117)
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("Bayes factor for an R-squared increase: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer: a published power or sample
  #   size for the default JZS Bayes factor of a full regression model
  #   against a nested one (as BayesFactor's regressionBF(whichModels =
  #   "top") and lmBF() compute it). Transcribe both R-squared values, the
  #   numbers of predictors, the r scale, the threshold, the sample size
  #   and the published chance of reaching the threshold.
  r2_full <- TODO_PUBLISHED_VALUE
  r2_reduced <- TODO_PUBLISHED_VALUE
  p <- TODO_PUBLISHED_VALUE
  q <- TODO_PUBLISHED_VALUE
  scale <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(r2_full, r2_reduced, p, q, scale, threshold, n, published_power)
  result <- engine_function("run_spec")(r2c_validation_spec("r2_increase", n, r2_full, r2_reduced, p, q, threshold, scale))
  expect_power_near(result$curve[1, ], published_power)
})

# Fixed predictors: orthogonal, centred columns with sum of squares n; the
# kept predictors' squared coefficients sum to r2_reduced / (1 - r2_full)
# and the tested ones' to (r2_full - r2_reduced) / (1 - r2_full), so that
# with residual SD 1 each model's population R-squared is as given.
# Measured predictors: independent standard normal predictors drawn afresh
# for every data set, with the same coefficients.
simulate_r2c_bf <- function(nsim, n, r2_full, r2_reduced, p, q, scale, seed, measured = FALSE) {
  set.seed(seed)
  x <- qr.Q(qr(cbind(1, matrix(stats::rnorm(n * p), n))))[, -1, drop = FALSE] * sqrt(n)
  colnames(x) <- paste0("x", seq_len(p))
  kept <- seq_len(p - q)
  tested <- setdiff(seq_len(p), kept)
  beta <- numeric(p)
  if (length(kept)) beta[kept] <- sqrt(r2_reduced / (1 - r2_full) / length(kept))
  beta[tested] <- sqrt((r2_full - r2_reduced) / (1 - r2_full) / q)
  mu <- drop(x %*% beta)
  full <- stats::reformulate(colnames(x), "y")
  reduced <- if (length(kept)) stats::reformulate(colnames(x)[kept], "y")
  vapply(seq_len(nsim), function(i) {
    if (measured) {
      x[] <- stats::rnorm(n * p)
      mu <- drop(x %*% beta)
    }
    data <- data.frame(y = mu + stats::rnorm(n), x)
    bf <- function(f) BayesFactor::extractBF(BayesFactor::lmBF(f, data = data, rscaleCont = scale, progress = FALSE), logbf = TRUE)$bf
    bf(full) - if (is.null(reduced)) 0 else bf(reduced)
  }, numeric(1))
}

check_r2c_case <- function(template, n, r2_full, r2_reduced, p, q, scale = 0.354, threshold = 10, nsim = validation_nrep(), seed,
                           measured = FALSE) {
  result <- engine_function("run_spec")(r2c_validation_spec(template, n, r2_full, r2_reduced, p, q, threshold, scale,
    predictor_model = if (measured) "random" else "fixed"))
  log_bf <- simulate_r2c_bf(nsim, n, r2_full, r2_reduced, p, q, scale, seed, measured)
  expect_power_near(result$curve[1, ], mean(log_bf >= log(threshold)), reference_nrep = nsim)
  null_bf <- simulate_r2c_bf(nsim, n, r2_reduced, r2_reduced, p, q, scale, seed + 1, measured)
  se <- function(x) sqrt(max(x * (1 - x), 1e-3) * (1 / nsim + 1 / result$bayes$null_nrep))
  for_null <- mean(null_bf <= -log(threshold))
  expect_lt(abs(result$bayes$evidence_for_null - for_null), 4 * se(for_null) + 2e-3)
  misleading <- mean(null_bf >= log(threshold))
  expect_lt(abs(result$bayes$misleading_evidence - misleading), 4 * se(misleading) + 2e-3)
}

test_that("Bayes factor for an R-squared increase, measured predictors: agrees with lmBF() on data sets with new normal predictors", {
  skip_unless_full_validation()
  check_r2c_case("r2_increase", 200, 0.15, 0.08, 5L, 2L, seed = 85, measured = TRUE)
  check_r2c_case("r2_increase", 60, 0.3, 0.2, 8L, 3L, seed = 86, measured = TRUE)
})

test_that("Bayes factor for one coefficient, measured predictors: agrees with lmBF() on data sets with new normal predictors", {
  skip_unless_full_validation()
  check_r2c_case("single_coefficient", 150, 0.25, 0.2, 4L, 1L, seed = 87, measured = TRUE)
})

# Predictors set by the design (target_test > predictor_model "fixed").

test_that("Bayes factor for an R-squared increase, two of five predictors: agrees with lmBF() on simulated data", {
  skip_unless_full_validation()
  check_r2c_case("r2_increase", 200, 0.15, 0.08, 5L, 2L, seed = 95)
})

test_that("Bayes factor for an R-squared increase, the only predictors, a wider prior and threshold 3: agrees with lmBF() on simulated data", {
  skip_unless_full_validation()
  check_r2c_case("r2_increase", 80, 0.12, 0, 3L, 3L, scale = 0.707, threshold = 3, seed = 96)
})

test_that("Bayes factor for one coefficient among four predictors: agrees with lmBF() on simulated data", {
  skip_unless_full_validation()
  check_r2c_case("single_coefficient", 150, 0.25, 0.2, 4L, 1L, seed = 97)
})
