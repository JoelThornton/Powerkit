# Validation: a justified alpha (goal > type "justified_alpha"). Backend:
# JustifyAlpha's optimal_alpha() on pwr's power, by formula. Build guide
# section 6:
#   1. analytic agreement: the unit tests (test-backend-justify-alpha.R)
#      check powerkit against optimal_alpha() called directly
#   2. published examples: below, for the maintainer to choose and
#      transcribe (a compromise power analysis in G*Power, or a worked
#      example from JustifyAlpha's documentation)
#   3. an independent search: below; a fine grid over alpha with pwr's
#      power finds the same minimum and the same balance point
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

ja_validation_spec <- function(d, n, goal = list()) {
  spec <- example_spec("independent_t")
  spec$target_test$method <- "student_t"
  spec$target_test$alternative <- "two_sided"
  spec$population$d <- d
  spec$options <- NULL
  spec$goal <- modifyList(list(type = "justified_alpha", n = n), goal)
  spec
}

test_that("justified alpha, two groups: matches a published compromise power analysis (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE. A published compromise power analysis
  # (G*Power, beta/alpha ratio q) for two independent groups, for the
  # maintainer to choose. A ratio q is error_rule "balance" with
  # cost_ratio q and prior_odds 1.
  d <- TODO_PUBLISHED_VALUE # Cohen's d
  n_total <- TODO_PUBLISHED_VALUE # total sample size
  q <- TODO_PUBLISHED_VALUE # beta/alpha ratio
  alpha <- TODO_PUBLISHED_VALUE # Output: the alpha reported
  skip_if_todo(d, n_total, q, alpha)

  j <- run_spec(ja_validation_spec(d, n_total, list(error_rule = "balance", cost_ratio = q)))$justified_alpha
  expect_lt(abs(j$alpha - alpha), 0.002)
})

test_that("justified alpha: a grid search over alpha finds the same minimum and balance point", {
  skip_unless_full_validation()
  alphas <- seq(0.0005, 0.5, by = 0.0005)
  for (setting in list(list(d = 0.5, n = 64, cost = 1, prior = 1), list(d = 0.3, n = 200, cost = 4, prior = 0.5))) {
    beta <- 1 - pwr::pwr.t.test(n = setting$n / 2, d = setting$d, sig.level = alphas)$power
    weighted <- (setting$cost * alphas + setting$prior * beta) / (setting$cost + setting$prior)
    goal <- list(cost_ratio = setting$cost, prior_odds = setting$prior)
    minimum <- run_spec(ja_validation_spec(setting$d, setting$n, goal))$justified_alpha
    expect_lt(abs(minimum$alpha - alphas[which.min(weighted)]), 0.002)
    balance <- run_spec(ja_validation_spec(setting$d, setting$n, c(goal, error_rule = "balance")))$justified_alpha
    expect_lt(abs(balance$alpha - alphas[which.min(abs(setting$cost * alphas - setting$prior * beta))]), 0.002)
  }
})
