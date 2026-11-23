# Validation: the Bayes factor for R-squared in a linear regression
# (BayesFactor's linear-regression Bayes factor, JASP's default r scale of
# 0.354 for the JZS prior).
#   1. a published example (placeholder for the maintainer)
#   2. agreement with simulation: data sets drawn from a regression with
#      predictors measured on each person (the default, Departure 39: new
#      normal predictors in every data set) or set by the design (the same
#      predictor values in every data set, so the F statistic's
#      noncentrality is f^2 n, the convention of the F test), each one's
#      Bayes factor computed by lmBF() itself on the data, and the share
#      passing the threshold compared with powerkit's exact chance
#   3. the no-effect side, simulated the same way with every coefficient 0
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

reg_bf_validation_spec <- function(n, r2, predictors, threshold = 10, scale = 0.354, predictor_model = "fixed") {
  spec <- example_spec("regression_r2_zero")
  spec$population <- list(metric = "r_squared", r2 = r2, predictors = predictors)
  spec$target_test <- list(effect = "r_squared", method = "bayes_factor", evidence_threshold = threshold, prior_scale = scale,
    predictor_model = predictor_model)
  spec$options <- NULL
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("Bayes factor for R-squared: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer: a published power or sample
  #   size for the default JZS Bayes factor for R-squared (as BayesFactor's
  #   regressionBF() and JASP's Bayesian linear regression compute it).
  #   Transcribe R-squared, the number of predictors, the r scale, the
  #   threshold, the sample size and the published chance of reaching the
  #   threshold.
  r2 <- TODO_PUBLISHED_VALUE
  predictors <- TODO_PUBLISHED_VALUE
  scale <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(r2, predictors, scale, threshold, n, published_power)
  result <- engine_function("run_spec")(reg_bf_validation_spec(n, r2, predictors, threshold, scale))
  expect_equal(result$curve$power, published_power, tolerance = 0.005)
})

# Fixed predictors: orthogonal, centred columns with sum of squares n, and
# equal coefficients whose squares sum to f^2, so that with residual SD 1
# the population R-squared is r2 and the noncentrality is f^2 n.
# Measured predictors: independent standard normal predictors drawn
# afresh for every data set, with the same coefficients (population
# R-squared r2 either way).
simulate_reg_bf <- function(nsim, n, r2, predictors, scale, seed, measured = FALSE) {
  set.seed(seed)
  x <- qr.Q(qr(cbind(1, matrix(stats::rnorm(n * predictors), n))))[, -1, drop = FALSE] * sqrt(n)
  colnames(x) <- paste0("x", seq_len(predictors))
  beta <- rep(sqrt(r2 / (1 - r2) / predictors), predictors)
  mu <- drop(x %*% beta)
  formula <- stats::as.formula(paste("y ~", paste(colnames(x), collapse = " + ")))
  vapply(seq_len(nsim), function(i) {
    if (measured) {
      x[] <- stats::rnorm(n * predictors)
      mu <- drop(x %*% beta)
    }
    data <- data.frame(y = mu + stats::rnorm(n), x)
    BayesFactor::extractBF(BayesFactor::lmBF(formula, data = data, rscaleCont = scale, progress = FALSE))$bf
  }, numeric(1))
}

check_reg_bf_case <- function(n, r2, predictors, scale = 0.354, threshold = 10, nsim = validation_nrep(), seed, measured = FALSE) {
  result <- engine_function("run_spec")(reg_bf_validation_spec(n, r2, predictors, threshold, scale,
    predictor_model = if (measured) "random" else "fixed"))
  bf <- simulate_reg_bf(nsim, n, r2, predictors, scale, seed, measured)
  expect_power_near(result$curve[1, ], mean(bf >= threshold), reference_nrep = nsim)
  null_bf <- simulate_reg_bf(nsim, n, 0, predictors, scale, seed + 1, measured)
  for_null <- mean(1 / null_bf >= threshold)
  expect_lt(abs(result$bayes$evidence_for_null - for_null), 4 * sqrt(max(for_null * (1 - for_null), 1e-3) / nsim) + 2e-3)
  misleading <- mean(null_bf >= threshold)
  expect_lt(abs(result$bayes$misleading_evidence - misleading), 4 * sqrt(max(misleading, 1e-3) / nsim) + 2e-3)
}

test_that("Bayes factor for R-squared, measured predictors: agrees with lmBF() on data sets with new normal predictors (analytic)", {
  skip_unless_full_validation()
  check_reg_bf_case(120, 0.12, 3L, seed = 91, measured = TRUE)
  check_reg_bf_case(50, 0.25, 6L, scale = 0.707, threshold = 3, seed = 92, measured = TRUE)
})

# Predictors set by the design (target_test > predictor_model "fixed").

test_that("Bayes factor for R-squared, three predictors and JASP's default prior: agrees with lmBF() on simulated data (analytic)", {
  skip_unless_full_validation()
  check_reg_bf_case(120, 0.12, 3L, seed = 93)
})

test_that("Bayes factor for R-squared, six predictors, a wider prior and threshold 3: agrees with lmBF() on simulated data (analytic)", {
  skip_unless_full_validation()
  check_reg_bf_case(90, 0.15, 6L, scale = 0.707, threshold = 3, seed = 94)
})
