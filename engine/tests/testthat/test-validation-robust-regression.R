# Validation: the test of one regression coefficient with robust (HC3 or
# HC4) standard errors, or by quantile regression.
# Backend: Spower simulation of powerkit's experiment p_coefficient(),
# which tests with car's linearHypothesis() and hccm(), or fits
# quantreg's rq().
#   1. with normal errors of constant spread, HC3 and HC4 have the usual
#      test's power, by pwrss's formula (power.f.regression(k.tested = 1))
#   2. agreement with an independent simulation of quantile regression:
#      the outcome drawn by its quantile function (inverse transform)
#      rather than by adding an error, and tested by rq() directly
#   3. Type I error of HC3 and HC4 when the spread changes with the
#      predictor, and of quantile regression with normal errors; with
#      skewed errors whose spread changes, quantile regression's test
#      rejects too often, and the size of that is recorded
#   4. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

coef_validation_spec <- function(partial_r2, k, n, method, ratio = 1, shape = "normal", quantile = NULL) {
  validation_spec(
    design = "multiple_regression",
    template = "single_coefficient",
    variables = list(X = validation_variable("continuous", "Predictor"), Y = validation_variable("continuous", "Outcome")),
    population = c(list(metric = "r_squared", partial_r2 = partial_r2, predictors_total = k, variance_ratio = ratio, error_shape = shape),
      if (!is.null(quantile)) list(quantile = quantile)),
    target_test = list(effect = "coefficient", method = method, alpha = 0.05),
    seed = 6402,
    n = n
  )
}

# Quantile regression, by hand: with heavy-tailed (t, 3 df) errors and a
# spread that changes with x, y is drawn as its conditional quantile
# function at a uniform draw, Q(u | x) = f x + s(x) (F^-1(u) - F^-1(tau)),
# which has the same distribution as powerkit's slope plus error.
quantile_by_hand <- function(partial_r2, n, ratio, tau, nrep, seed) {
  f <- sqrt(partial_r2 / (1 - partial_r2))
  g <- log(ratio) / 2
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    x <- stats::rnorm(n)
    u <- stats::runif(n)
    y <- f * x + exp((g * x - g^2 / 2) / 2) * (stats::qt(u, 3) - stats::qt(tau, 3)) / sqrt(3)
    fit <- quantreg::rq(y ~ x, tau = tau)
    # summary.rq() warns when its sparsity estimate is not positive at a
    # few points ("non-positive fis"); powerkit's experiment sees the same.
    suppressWarnings(stats::coef(summary(fit, se = "nid"))["x", "Pr(>|t|)"]) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("robust standard errors: with normal errors of constant spread, the usual test's power (pwrss)", {
  skip_unless_full_validation()
  # HC3 and HC4 standard errors are a little larger than the usual ones in
  # small samples: allow 0.02 besides the Monte Carlo error.
  formula <- pwrss::power.f.regression(r.squared.change = 0.06, k.total = 3, k.tested = 1, n = 120, alpha = 0.05, verbose = 0)$power
  for (method in c("ols_hc3", "ols_hc4")) {
    spec <- coef_validation_spec(0.06, 3, 120, method)
    expect_power_agrees_within(engine_power(spec), exact_estimate(formula), allowance = 0.02)
  }
})

test_that("quantile regression: powerkit agrees with an independent simulation (simulation)", {
  skip_unless_full_validation()
  spec <- coef_validation_spec(0.08, 1, 150, "quantile_regression", ratio = 3, shape = "heavy_tailed", quantile = 0.5)
  reference <- quantile_by_hand(0.08, 150, 3, 0.5, 4000L, 64)
  expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  spec <- coef_validation_spec(0.08, 1, 150, "quantile_regression", ratio = 3, shape = "heavy_tailed", quantile = 0.25)
  reference <- quantile_by_hand(0.08, 150, 3, 0.25, 4000L, 65)
  expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
})

test_that("robust standard errors and quantile regression: Type I error when the spread changes (simulation)", {
  skip_unless_full_validation()
  for (method in c("ols_hc3", "ols_hc4")) {
    expect_type1_near(engine_power(coef_validation_spec(0, 3, 150, method, ratio = 4)), alpha = 0.05)
  }
  expect_type1_near(engine_power(coef_validation_spec(0, 3, 150, "quantile_regression", quantile = 0.5)), alpha = 0.05)
})

test_that("quantile regression: the 'nid' test rejects too often with skewed errors whose spread changes (simulation)", {
  skip_unless_full_validation()
  # Measured when the test was added (2 November 2026): 0.094 at alpha
  # 0.05 with n = 150, three predictors, skewed errors and a variance
  # ratio of 4 (quantreg's se = "ker" gave 0.007 in the same case). This
  # records the size of the problem shown on the card (docs/decisions.md,
  # 2 November 2026); if it changes, the card's warning needs revisiting.
  rate <- engine_power(coef_validation_spec(0, 3, 150, "quantile_regression", ratio = 4, shape = "skewed", quantile = 0.5))$power
  expect_gt(rate, 0.07)
  expect_lt(rate, 0.12)
})

test_that("robust regression: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # a regression coefficient tested with heteroscedasticity-consistent
  # standard errors or by quantile regression; source, section, page).
  partial_r2 <- TODO_PUBLISHED_VALUE
  predictors <- TODO_PUBLISHED_VALUE
  variance_ratio <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(partial_r2, predictors, variance_ratio, n, published_power)
  spec <- coef_validation_spec(partial_r2, predictors, n, "ols_hc3", ratio = variance_ratio)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
