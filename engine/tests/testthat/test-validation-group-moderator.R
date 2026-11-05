# Validation: moderation by a factor with three or more groups (the F test
# of the X x A terms in a linear regression).
# Backend: Spower simulation of powerkit's experiment p_group_moderator(),
# which fits stats::lm().
#   1. agreement with the F test's power by pwr's formula (pwr.f2.test()),
#      with Cohen's f^2 from the population: within group g, Y = m_g + r_g X
#      + e with var(e) = 1 - r_g^2, so the X x A terms explain sum w_g (r_g
#      - rbar)^2 over the pooled error variance sum w_g (1 - r_g^2), where
#      w_g are the groups' shares and rbar = sum w_g r_g; a fixed-predictor
#      formula, so allowance 0.02
#   2. agreement with a separately written simulation loop that fits lm()
#   3. Type I error with different group means and a common slope
#   4. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

gm_validation_spec <- function(r, n, means = NULL, ratio = NULL) {
  k <- length(r)
  validation_spec(
    design = "regression_interaction",
    template = "group_moderator",
    variables = list(
      X = validation_variable("continuous", "X"),
      A = list(type = "between_factor", label = "Group", levels = as.list(paste0("g", seq_len(k)))),
      Y = validation_variable("continuous", "Y")
    ),
    population = c(list(metric = "correlation", r_xy = as.list(r)), if (!is.null(means)) list(means = as.list(means))),
    target_test = list(effect = "interaction", method = "f_test", alpha = 0.05),
    seed = 6801,
    n = n,
    options = if (!is.null(ratio)) list(group_ratio = as.list(ratio)) else list()
  )
}

gm_formula_power <- function(r, n, ratio = rep(1, length(r))) {
  w <- ratio / sum(ratio)
  rbar <- sum(w * r)
  f2 <- sum(w * (r - rbar)^2) / sum(w * (1 - r^2))
  k <- length(r)
  pwr::pwr.f2.test(u = k - 1, v = n - 2 * k, f2 = f2, sig.level = 0.05)$power
}

gm_by_hand <- function(r, n, nrep, seed) {
  k <- length(r)
  a <- factor(rep(seq_len(k), each = n / k))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    x <- stats::rnorm(n)
    y <- r[as.integer(a)] * x + sqrt(1 - r[as.integer(a)]^2) * stats::rnorm(n)
    stats::anova(stats::lm(y ~ x + a), stats::lm(y ~ x * a))[2, "Pr(>F)"] < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("moderation by groups: powerkit agrees with the F test's power by pwr's formula (formula)", {
  skip_unless_full_validation()
  cases <- list(
    list(r = c(-0.1, -0.2, -0.35), n = 600, ratio = c(1, 1, 1)),
    list(r = c(0.3, 0.1, 0.1, -0.1), n = 400, ratio = c(1, 1, 2, 1))
  )
  for (case in cases) {
    spec <- gm_validation_spec(case$r, case$n, ratio = case$ratio)
    expect_power_agrees_within(engine_power(spec), exact_estimate(gm_formula_power(case$r, case$n, case$ratio)), allowance = 0.02)
  }
})

test_that("moderation by groups: powerkit agrees with a separately written simulation (simulation)", {
  skip_unless_full_validation()
  r <- c(0, 0.2, 0.4)
  spec <- gm_validation_spec(r, 300)
  expect_power_agrees_within(engine_power(spec), gm_by_hand(r, 300, 4000L, 68), allowance = 0)
})

test_that("moderation by groups: Type I error with different means and a common slope (simulation)", {
  skip_unless_full_validation()
  spec <- gm_validation_spec(c(0.3, 0.3, 0.3), 150, means = c(0, 0.5, 1))
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("moderation by groups: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for a
  # continuous by categorical interaction with three or more groups;
  # source, section, page).
  correlations <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(correlations, n, published_power)
  spec <- gm_validation_spec(correlations, n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
