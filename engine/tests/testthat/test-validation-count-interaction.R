# Validation: moderation of a count outcome (Poisson or negative binomial
# regression with X x W).
# Backend: Spower simulation of powerkit's experiment
# p_count_interaction(), which fits stats::glm(family = poisson()) or
# MASS::glm.nb().
#   1. agreement with the large-sample power of the Wald z test, from the
#      expected Fisher information of the log-linear model (n times the mean
#      of mu / (1 + k mu) z z' over a million draws of X and W,
#      z = (1, x, w, x w); k = 0 for Poisson counts), computed without
#      powerkit's code; allowance 0.02, as for the other large-sample
#      comparisons
#   2. agreement with a separately written simulation loop that fits glm()
#      or glm.nb()
#   3. Type I error with both main effects present
#   4. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

cint_validation_spec <- function(base_rate, rr_x, rr_w, rr_xw, n, x_binary = FALSE, w_binary = FALSE, r = 0, k = 0) {
  validation_spec(
    design = "poisson_regression",
    template = "interaction",
    variables = list(
      X = if (x_binary) validation_variable("binary", "X", levels = list("x0", "x1")) else validation_variable("continuous", "X"),
      W = if (w_binary) validation_variable("binary", "W", levels = list("w0", "w1")) else validation_variable("continuous", "W"),
      Y = validation_variable("count", "Y")
    ),
    population = c(list(metric = "rate_ratio", base_rate = base_rate, rate_ratio_x = rr_x, rate_ratio_w = rr_w, rate_ratio_xw = rr_xw),
      if (!x_binary && !w_binary && r != 0) list(r_xw = r), if (k > 0) list(dispersion = k)),
    target_test = list(effect = "interaction", method = if (k > 0) "negative_binomial" else "wald_z", alpha = 0.05),
    seed = 3201,
    n = n
  )
}

cint_draw <- function(m, x_binary, w_binary, r) {
  if (!x_binary && !w_binary) {
    x <- stats::rnorm(m)
    return(cbind(x = x, w = r * x + sqrt(1 - r^2) * stats::rnorm(m)))
  }
  cbind(x = if (x_binary) stats::rbinom(m, 1, 0.5) else stats::rnorm(m), w = if (w_binary) stats::rbinom(m, 1, 0.5) else stats::rnorm(m))
}

cint_formula_power <- function(base_rate, rr_x, rr_w, rr_xw, n, x_binary, w_binary, r, k) {
  d <- with_seed(91, cint_draw(1e6, x_binary, w_binary, r))
  z <- cbind(1, d[, "x"], d[, "w"], d[, "x"] * d[, "w"])
  beta <- log(c(base_rate, rr_x, rr_w, rr_xw))
  mu <- exp(z %*% beta)[, 1]
  information <- crossprod(z * sqrt(mu / (1 + k * mu))) / nrow(z)
  se <- sqrt(solve(information)[4, 4] / n)
  shift <- abs(beta[4]) / se
  stats::pnorm(shift - stats::qnorm(0.975)) + stats::pnorm(-shift - stats::qnorm(0.975))
}

cint_by_hand <- function(base_rate, rr_x, rr_w, rr_xw, n, x_binary, w_binary, r, k, nrep, seed) {
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    d <- cint_draw(n, x_binary, w_binary, r)
    mu <- base_rate * rr_x^d[, 1] * rr_w^d[, 2] * rr_xw^(d[, 1] * d[, 2])
    y <- if (k > 0) stats::rnbinom(n, size = 1 / k, mu = mu) else stats::rpois(n, mu)
    x <- d[, 1]
    w <- d[, 2]
    fit <- tryCatch(suppressWarnings(if (k > 0) MASS::glm.nb(y ~ x * w) else stats::glm(y ~ x * w, family = stats::poisson())),
      error = function(e) NULL)
    !is.null(fit) && stats::coef(summary(fit))[4, 4] < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("moderation of a count: powerkit agrees with the Wald test's large-sample power (formula)", {
  skip_unless_full_validation()
  cases <- list(
    list(b = 2, rx = 1.2, rw = 1.1, rxw = 1.15, n = 500, xb = FALSE, wb = FALSE, r = -0.2, k = 0),
    list(b = 4, rx = 0.8, rw = 1.2, rxw = 0.75, n = 600, xb = TRUE, wb = TRUE, r = 0, k = 0.5),
    list(b = 6, rx = 0.8, rw = 1.2, rxw = 0.85, n = 700, xb = TRUE, wb = FALSE, r = 0, k = 0.5)
  )
  for (case in cases) {
    spec <- cint_validation_spec(case$b, case$rx, case$rw, case$rxw, case$n, case$xb, case$wb, case$r, case$k)
    formula <- cint_formula_power(case$b, case$rx, case$rw, case$rxw, case$n, case$xb, case$wb, case$r, case$k)
    expect_power_agrees_within(engine_power(spec), exact_estimate(formula), allowance = 0.02)
  }
})

test_that("moderation of a count: powerkit agrees with a separately written simulation (simulation)", {
  skip_unless_full_validation()
  spec <- cint_validation_spec(3, 1.2, 0.9, 1.3, 250, x_binary = FALSE, w_binary = TRUE, k = 0.8)
  reference <- cint_by_hand(3, 1.2, 0.9, 1.3, 250, FALSE, TRUE, 0, 0.8, 4000L, 32)
  expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
})

test_that("moderation of a count: Type I error with both main effects present (simulation)", {
  skip_unless_full_validation()
  spec <- cint_validation_spec(3, 1.5, 1.3, 1, 300, r = 0.3, k = 0.5)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("moderation of a count: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # an interaction in Poisson or negative binomial regression; source,
  # section, page).
  base_rate <- TODO_PUBLISHED_VALUE
  rate_ratio_xw <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(base_rate, rate_ratio_xw, n, published_power)
  spec <- cint_validation_spec(base_rate, 1, 1, rate_ratio_xw, n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
