# Validation: d' in two conditions or groups (signal detection), powerkit's
# Spower experiment p_dprime().
#   1. agreement with a simulation written separately: every trial drawn
#      as an evidence value (normal with mean d / 2 on signal trials and
#      -d / 2 on noise trials, SD 1) against the person's criterion, rather
#      than powerkit's binomial counts from the model's yes-probabilities;
#      d' estimated with the log-linear correction (Hautus, 1995) and the
#      conditions compared with t.test(); a paired design two-sided, two
#      groups one-sided, and a paired design near ceiling (high d', few
#      trials), where the correction matters most
#   2. published example: a placeholder for the maintainer
# Both are simulations, so no allowance beyond their Monte Carlo error.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

sdt_spec <- function(within, d, trials, sd_d, r_d, criterion, sd_c, n, alternative, seed) {
  validation_spec(
    design = "signal_detection",
    template = "dprime",
    variables = list(G = validation_variable(if (within) "within_factor" else "binary", "Condition", levels = list("A", "B")),
      Y = validation_variable("continuous", "Task")),
    population = c(list(metric = "dprime", dprime = as.list(d), trials_signal = trials, trials_noise = trials,
      sd_dprime = sd_d, criterion = criterion, sd_criterion = sd_c), if (within) list(r_dprime = r_d)),
    target_test = list(effect = "dprime_difference", method = "t_test", alpha = 0.05, alternative = alternative),
    seed = seed,
    n = n
  )
}

sdt_by_hand <- function(within, d, trials, sd_d, r_d, criterion, sd_c, n, alternative, nrep, seed) {
  side <- switch(alternative, two_sided = "two.sided", greater = "greater", less = "less")
  one_person <- function(true_d, crit) {
    # Each trial's evidence against the criterion: yes when it is above c.
    hits <- sum(stats::rnorm(trials, true_d / 2) > crit)
    fas <- sum(stats::rnorm(trials, -true_d / 2) > crit)
    stats::qnorm((hits + 0.5) / (trials + 1)) - stats::qnorm((fas + 0.5) / (trials + 1))
  }
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    if (within) {
      sigma <- sd_d^2 * matrix(c(1, r_d, r_d, 1), 2)
      true <- MASS::mvrnorm(n, d, sigma + diag(1e-12, 2))
      crit <- stats::rnorm(n, criterion, sd_c)
      a <- vapply(seq_len(n), function(p) one_person(true[p, 1], crit[p]), numeric(1))
      b <- vapply(seq_len(n), function(p) one_person(true[p, 2], crit[p]), numeric(1))
      stats::t.test(b, a, paired = TRUE, alternative = side)$p.value < 0.05
    } else {
      g <- rep(1:2, each = n / 2)
      true <- stats::rnorm(n, d[g], sd_d)
      crit <- stats::rnorm(n, criterion, sd_c)
      e <- vapply(seq_len(n), function(p) one_person(true[p], crit[p]), numeric(1))
      stats::t.test(e[g == 2], e[g == 1], var.equal = TRUE, alternative = side)$p.value < 0.05
    }
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("d' in two conditions or groups: a simulation written separately (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("MASS")
  cases <- list(
    list(within = TRUE, d = c(1, 1.4), trials = 40, sd_d = 0.5, r_d = 0.5, criterion = 0.2, sd_c = 0.3, n = 30, alternative = "two_sided"),
    list(within = FALSE, d = c(1.5, 1.1), trials = 30, sd_d = 0.4, r_d = NULL, criterion = 0, sd_c = 0.2, n = 60, alternative = "less"),
    list(within = TRUE, d = c(2.5, 3), trials = 12, sd_d = 0.3, r_d = 0.6, criterion = -0.3, sd_c = 0.3, n = 25, alternative = "two_sided")
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    spec <- sdt_spec(case$within, case$d, case$trials, case$sd_d, case$r_d, case$criterion, case$sd_c, case$n, case$alternative, 7300L + i)
    reference <- sdt_by_hand(case$within, case$d, case$trials, case$sd_d, case$r_d %||% 0, case$criterion, case$sd_c, case$n,
      case$alternative, 2000L, 7310L + i)
    expect_power_agrees(engine_power(spec), reference)
  }
})

test_that("d' in two conditions: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power analysis for a difference
  # in d' between conditions; section, page).
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(n, published_power)
  spec <- sdt_spec(TRUE, c(1, 1.4), 40, 0.5, 0.5, 0, 0, n, "two_sided", 7320L)
  expect_power_near(engine_power(spec), published_power)
})
