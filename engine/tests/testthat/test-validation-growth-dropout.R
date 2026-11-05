# Validation: growth curves with drop-out over the occasions or unequal
# groups (E35), by longpower's hu.mackey.thomas.linear.power() (Hu, Mackey
# and Thomas, 2021).
#   1. agreement with an independent simulation: people drawn with random
#      intercepts and slopes and both groups starting at the same level (the
#      formula's model), each person's measurements kept up to the occasion
#      they leave after (monotone drop-out with the shares given), fitted by
#      lme4's lmer() with a common intercept, a slope and a group x time
#      term and a random intercept and slope for each person, the group x
#      time coefficient tested by its Wald z test; the formula takes the
#      covariance as known, so an allowance of 0.03, as for the complete-
#      data formula
#   2. published example: Hu, Mackey and Thomas (2021); placeholder for the
#      maintainer
# Skipped unless POWERKIT_FULL_VALIDATION=true.

dropout_spec <- function(times, delta, s_i, s_s, r, s_e, n, retention = NULL, ratio = 1) {
  spec <- validation_spec(
    design = "mixed_model",
    template = "growth_curve",
    variables = list(G = validation_variable("binary", "Group", levels = list("g1", "g2")), Y = validation_variable("continuous", "Y")),
    population = c(list(metric = "raw", times = as.list(times), slope_difference = delta, sd_intercept = s_i, sd_slope = s_s,
      r_intercept_slope = r, sd_residual = s_e), if (!is.null(retention)) list(retention = as.list(retention))),
    target_test = list(effect = "slope_difference", method = "z_test", alpha = 0.05),
    seed = 6911,
    n = n
  )
  if (!isTRUE(all.equal(ratio, 1))) spec$options$allocation_ratio <- ratio
  spec
}

dropout_by_hand <- function(times, delta, s_i, s_s, r, s_e, n, retention, ratio, nrep, seed) {
  m <- length(times)
  n1 <- round(n / (1 + ratio))
  sigma <- matrix(c(s_i^2, r * s_i * s_s, r * s_i * s_s, s_s^2), 2)
  # The share whose last occasion is each one.
  last_share <- c(-diff(retention), retention[m])
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    effects <- MASS::mvrnorm(n, c(0, 0), sigma)
    group <- c(rep(0, n1), rep(1, n - n1))
    last <- sample.int(m, n, replace = TRUE, prob = last_share)
    d <- data.frame(id = factor(rep(seq_len(n), each = m)), group = rep(group, each = m), time = rep(times, n),
      occasion = rep(seq_len(m), n), last = rep(last, each = m))
    d$y <- rep(effects[, 1], each = m) + (rep(effects[, 2], each = m) + delta * d$group) * d$time + stats::rnorm(n * m, 0, s_e)
    d <- d[d$occasion <= d$last, ]
    fit <- suppressMessages(suppressWarnings(lme4::lmer(y ~ time + time:group + (time | id), data = d, REML = TRUE)))
    est <- summary(fit)$coefficients["time:group", ]
    abs(est[["t value"]]) > stats::qnorm(0.975)
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("growth curves with drop-out or unequal groups: the formula agrees with mixed models fitted to simulated studies (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("lme4")
  cases <- list(
    list(times = 0:3, delta = -1, s_i = 6, s_s = 2, r = -0.2, s_e = 4, n = 240, retention = c(1, 0.9, 0.8, 0.7), ratio = 1),
    list(times = c(0, 1, 2, 4, 6), delta = 0.3, s_i = 1, s_s = 0.4, r = 0.3, s_e = 1, n = 120, retention = NULL, ratio = 2),
    list(times = c(0, 1, 2, 3, 4), delta = 0.25, s_i = 1, s_s = 0.5, r = 0, s_e = 1, n = 150, retention = c(1, 0.95, 0.85, 0.8, 0.75), ratio = 0.5)
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    retention <- case$retention %||% rep(1, length(case$times))
    spec <- dropout_spec(case$times, case$delta, case$s_i, case$s_s, case$r, case$s_e, case$n, case$retention, case$ratio)
    reference <- dropout_by_hand(case$times, case$delta, case$s_i, case$s_s, case$r, case$s_e, case$n, retention, case$ratio, 1000L, 6920L + i)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0.03)
  }
})

test_that("growth curves with drop-out: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: Hu, Mackey and Thomas, 2021, Biometrical
  # Journal 63(4), 806-824, a worked example with monotone drop-out; table,
  # page).
  times <- TODO_PUBLISHED_VALUE
  retention <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(times, retention, n, published_power)
  spec <- dropout_spec(times, 1, 0, 1, 0, 1, n, retention)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
