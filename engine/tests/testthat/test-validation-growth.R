# Validation: growth curves (the difference between two groups' average
# rates of change over three or more occasions).
# Backend: longpower's diggle.linear.power() (Diggle, Heagerty, Liang and
# Zeger, 2002), the power solved from its sample size.
#   1. agreement with an independent simulation: people drawn with random
#      intercepts and slopes, fitted by lme4's lmer() with a random intercept
#      and slope for each person, and the group x time coefficient tested by
#      its Wald z test; the formula assumes the covariance known, so an
#      allowance of 0.03
#   2. published example: Diggle et al. (2002), the table that
#      diggle.linear.power()'s help reproduces; placeholder for the
#      maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

growth_validation_spec <- function(times, delta, s_i, s_s, r, s_e, n) {
  validation_spec(
    design = "mixed_model",
    template = "growth_curve",
    variables = list(G = validation_variable("binary", "Group", levels = list("g1", "g2")), Y = validation_variable("continuous", "Y")),
    population = list(metric = "raw", times = as.list(times), slope_difference = delta, sd_intercept = s_i, sd_slope = s_s,
      r_intercept_slope = r, sd_residual = s_e),
    target_test = list(effect = "slope_difference", method = "z_test", alpha = 0.05),
    seed = 6901,
    n = n
  )
}

growth_by_hand <- function(times, delta, s_i, s_s, r, s_e, n, nrep, seed) {
  m <- length(times)
  sigma <- matrix(c(s_i^2, r * s_i * s_s, r * s_i * s_s, s_s^2), 2)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    effects <- MASS::mvrnorm(n, c(0, 0), sigma)
    group <- rep(c(0, 1), each = n / 2)
    d <- data.frame(id = factor(rep(seq_len(n), each = m)), group = rep(group, each = m), time = rep(times, n))
    d$y <- rep(effects[, 1], each = m) + (rep(effects[, 2], each = m) + delta * d$group) * d$time + stats::rnorm(n * m, 0, s_e)
    fit <- suppressMessages(suppressWarnings(lme4::lmer(y ~ time * group + (time | id), data = d, REML = TRUE)))
    est <- summary(fit)$coefficients["time:group", ]
    abs(est[["t value"]]) > stats::qnorm(0.975)
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("growth curves: the formula agrees with mixed models fitted to simulated studies (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(times = 0:3, delta = -1, s_i = 6, s_s = 2, r = -0.2, s_e = 4, n = 200),
    list(times = c(0, 1, 2, 4, 6), delta = 0.3, s_i = 1, s_s = 0.4, r = 0.3, s_e = 1, n = 120)
  )
  for (case in cases) {
    spec <- growth_validation_spec(case$times, case$delta, case$s_i, case$s_s, case$r, case$s_e, case$n)
    reference <- growth_by_hand(case$times, case$delta, case$s_i, case$s_s, case$r, case$s_e, case$n, 1000L, 69)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0.03)
  }
})

test_that("growth curves: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: Diggle, Heagerty, Liang and Zeger, 2002,
  # Analysis of longitudinal data, 2nd edition, the sample-size table for a
  # difference in slopes (section 2.4); diggle.linear.power()'s help says
  # its example reproduces it).
  times <- TODO_PUBLISHED_VALUE
  delta <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(times, delta, n, published_power)
  spec <- growth_validation_spec(times, delta, 0, 1, 0, 1, n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
