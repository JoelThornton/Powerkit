# Validation: an ordinal outcome compared between two groups, under
# proportional odds. Backend: powertools::propodds() by formula (Whitehead's
# method, as its help cites). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-ordinal.R) check
#      powerkit against propodds() called directly; below, against Hmisc's
#      popower(), an independent implementation of the same method
#   2. published examples: placeholders below, for the maintainer
#   3. direct-call agreement with a simulation: not yet (no simulation
#      option)
#   4. Type I error: not applicable to the formula (an odds ratio of 1 is
#      refused as no effect)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

ordinal_validation_spec <- function(probabilities, odds_ratio, n = NULL, target_power = NULL,
                                    alpha = 0.05, allocation_ratio = 1) {
  v <- validation_variable
  validation_spec(
    design = "ordinal_regression",
    template = "ordinal_two_groups",
    variables = list(
      X = v("binary", "Group", levels = list("First", "Second")),
      Y = v("categorical", "Outcome", levels = as.list(paste("Category", seq_along(probabilities))))
    ),
    population = list(metric = "proportion", probabilities = as.list(probabilities), odds_ratio = odds_ratio),
    target_test = list(effect = "odds_ratio", method = "proportional_odds", alpha = alpha),
    seed = 1,
    n = n,
    target_power = target_power,
    options = list(allocation_ratio = allocation_ratio)
  )
}

# 1. Published example -----------------------------------------------------------

test_that("ordinal outcome, two groups: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (for example the method paper powertools'
  #   help for propodds() cites, Whitehead (1993); the maintainer adds it to
  #   refs.bib and records the section, table and page here).
  probabilities <- TODO_PUBLISHED_VALUE # group 1's share in each category, in order
  odds_ratio <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  target_power <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE # the published total sample size
  skip_if_todo(probabilities, odds_ratio, alpha, target_power, published_n)
  spec <- ordinal_validation_spec(probabilities, odds_ratio, target_power = target_power, alpha = alpha)
  expect_equal(run_spec(spec)$n_required$n, published_n)
})

# 2. Independent implementation ------------------------------------------------------

test_that("ordinal outcome, two groups: equals Hmisc's popower(), with equal and unequal groups", {
  skip_unless_full_validation()
  p_control <- c(0.2, 0.5, 0.2, 0.1)
  for (ratio in c(1, 2)) {
    n1 <- 60
    spec <- ordinal_validation_spec(p_control, 2.5, n = n1 * (1 + ratio), allocation_ratio = ratio)
    # popower() takes the average of the two groups' shares; Hmisc's
    # pomodm() gives group 2's shares under proportional odds.
    p_average <- (p_control + Hmisc::pomodm(p = p_control, odds.ratio = 1 / 2.5)) / 2
    direct <- Hmisc::popower(p = p_average, odds.ratio = 2.5, n1 = n1, n2 = n1 * ratio)$power
    expect_equal(run_spec(spec)$curve$power, direct, tolerance = 1e-8, label = paste("ratio", ratio))
  }
})
