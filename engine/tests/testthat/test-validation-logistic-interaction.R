# Validation: moderation with a yes/no outcome (logistic regression with
# X x W).
# Backend: Spower simulation of powerkit's experiment
# p_logistic_interaction(), which fits stats::glm().
#   1. agreement with the large-sample power of the Wald z test, from the
#      expected Fisher information of the logistic model (n times the mean of
#      p(1 - p) z z' over a million draws of X and W, z = (1, x, w, x w)),
#      computed without powerkit's code; allowance 0.02, as for the other
#      large-sample comparisons
#   2. agreement with a separately written simulation loop that fits glm()
#   3. Type I error with both main effects present
#   4. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

lint_validation_spec <- function(base_prob, or_x, or_w, or_xw, n, x_binary = FALSE, w_binary = FALSE, r = 0) {
  validation_spec(
    design = "logistic_regression",
    template = "interaction",
    variables = list(
      X = if (x_binary) validation_variable("binary", "X", levels = list("x0", "x1")) else validation_variable("continuous", "X"),
      W = if (w_binary) validation_variable("binary", "W", levels = list("w0", "w1")) else validation_variable("continuous", "W"),
      Y = validation_variable("binary", "Y", levels = list("No", "Yes"))
    ),
    population = c(list(metric = "odds_ratio", base_prob = base_prob, odds_ratio_x = or_x, odds_ratio_w = or_w, odds_ratio_xw = or_xw),
      if (!x_binary && !w_binary && r != 0) list(r_xw = r)),
    target_test = list(effect = "interaction", method = "wald_z", alpha = 0.05),
    seed = 6701,
    n = n
  )
}

lint_draw <- function(m, x_binary, w_binary, r) {
  if (!x_binary && !w_binary) {
    x <- stats::rnorm(m)
    return(cbind(x = x, w = r * x + sqrt(1 - r^2) * stats::rnorm(m)))
  }
  cbind(x = if (x_binary) stats::rbinom(m, 1, 0.5) else stats::rnorm(m), w = if (w_binary) stats::rbinom(m, 1, 0.5) else stats::rnorm(m))
}

lint_formula_power <- function(base_prob, or_x, or_w, or_xw, n, x_binary, w_binary, r) {
  d <- with_seed(91, lint_draw(1e6, x_binary, w_binary, r))
  z <- cbind(1, d[, "x"], d[, "w"], d[, "x"] * d[, "w"])
  beta <- c(stats::qlogis(base_prob), log(or_x), log(or_w), log(or_xw))
  p <- stats::plogis(z %*% beta)[, 1]
  information <- crossprod(z * sqrt(p * (1 - p))) / nrow(z)
  se <- sqrt(solve(information)[4, 4] / n)
  shift <- abs(beta[4]) / se
  stats::pnorm(shift - stats::qnorm(0.975)) + stats::pnorm(-shift - stats::qnorm(0.975))
}

lint_by_hand <- function(base_prob, or_x, or_w, or_xw, n, x_binary, w_binary, r, nrep, seed) {
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    d <- lint_draw(n, x_binary, w_binary, r)
    y <- stats::rbinom(n, 1, stats::plogis(stats::qlogis(base_prob) + log(or_x) * d[, 1] + log(or_w) * d[, 2] + log(or_xw) * d[, 1] * d[, 2]))
    fit <- suppressWarnings(stats::glm(y ~ d[, 1] * d[, 2], family = stats::binomial()))
    stats::coef(summary(fit))[4, 4] < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("moderation of a yes/no outcome: powerkit agrees with the Wald test's large-sample power (formula)", {
  skip_unless_full_validation()
  cases <- list(
    list(p = 0.25, ox = 1.4, ow = 1.1, oxw = 1.25, n = 800, xb = FALSE, wb = FALSE, r = -0.2),
    list(p = 0.3, ox = 1.5, ow = 1.2, oxw = 2, n = 600, xb = TRUE, wb = TRUE, r = 0)
  )
  for (case in cases) {
    spec <- lint_validation_spec(case$p, case$ox, case$ow, case$oxw, case$n, case$xb, case$wb, case$r)
    formula <- lint_formula_power(case$p, case$ox, case$ow, case$oxw, case$n, case$xb, case$wb, case$r)
    expect_power_agrees_within(engine_power(spec), exact_estimate(formula), allowance = 0.02)
  }
})

test_that("moderation of a yes/no outcome: powerkit agrees with a separately written simulation (simulation)", {
  skip_unless_full_validation()
  spec <- lint_validation_spec(0.3, 1.3, 1.2, 1.4, 300, x_binary = FALSE, w_binary = TRUE)
  reference <- lint_by_hand(0.3, 1.3, 1.2, 1.4, 300, FALSE, TRUE, 0, 4000L, 67)
  expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
})

test_that("moderation of a yes/no outcome: Type I error with both main effects present (simulation)", {
  skip_unless_full_validation()
  spec <- lint_validation_spec(0.3, 1.6, 1.4, 1, 400, r = 0.3)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("moderation of a yes/no outcome: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # an interaction in logistic regression; source, section, page).
  base_prob <- TODO_PUBLISHED_VALUE
  odds_ratio_xw <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(base_prob, odds_ratio_xw, n, published_power)
  spec <- lint_validation_spec(base_prob, 1, 1, odds_ratio_xw, n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
