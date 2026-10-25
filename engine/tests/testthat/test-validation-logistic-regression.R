# Validation: logistic regression, the Wald z test of one predictor.
# Backend: pwrss's power.z.logistic() by formula (Demidenko, 2007, with
# variance correction). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-formula-tests.R)
#      check powerkit against pwrss called directly
#   2. published examples: the G*Power 3.1 manual (below)
#   3. direct-call agreement with a simulation: not yet (no simulation
#      option)
#   4. Type I error: an odds ratio of 1 gives alpha by construction (unit
#      tests)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `x` is "normal" (a standardised score) or "binary" (a yes/no group with
# `x_prob` in its second level).
logistic_spec <- function(odds_ratio, base_prob, alpha, tails, seed, x = "normal",
                          x_prob = NULL, r2_other = 0, n = NULL, target_power = NULL) {
  v <- validation_variable
  variables <- list(
    X = if (x == "binary") v("binary", "Group", levels = list("First", "Second")) else v("continuous", "Predictor"),
    Y = v("binary", "Outcome", levels = list("No", "Yes"))
  )
  population <- list(metric = "odds_ratio", odds_ratio = odds_ratio, base_prob = base_prob)
  if (!is.null(x_prob)) population$x_prob <- x_prob
  if (r2_other > 0) population$r2_other_predictors <- r2_other
  validation_spec(
    design = "logistic_regression",
    template = "single_predictor",
    variables = variables,
    population = population,
    target_test = list(
      effect = "odds_ratio", method = "wald_z", alpha = alpha,
      alternative = if (tails == 1) (if (odds_ratio > 1) "greater" else "less") else "two_sided"
    ),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 2. Published examples: G*Power 3.1 -------------------------------------------
#
# Each test runs powerkit's required N for the published target power and
# compares it with the published total sample size, then compares the power
# at that N with the published "actual power".
#
# G*Power's inputs (to confirm against the manual): "Odds ratio",
#   "Pr(Y=1|X=1) H0", "R² other X", "X distribution" and its parameters.
#   Under H0 the probability of Y = 1 doesn't depend on X, so
#   "Pr(Y=1|X=1) H0" is believed to be powerkit's base_prob (the probability
#   at X = 0). powerkit takes a score X as standardised (mean 0, SD 1); if
#   the example's X has another mean or SD, note it here instead of
#   transcribing.

test_that("logistic regression, normal X: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), the chapter
  #   "z test: Logistic regression", its example with a normally
  #   distributed X: a priori analysis with the large-sample z test
  #   (Demidenko, 2007, with variance correction). Joel: add the section
  #   and page, and the options shown.
  odds_ratio <- TODO_PUBLISHED_VALUE # Odds ratio
  base_prob <- TODO_PUBLISHED_VALUE # Pr(Y=1|X=1) H0
  r2_other <- TODO_PUBLISHED_VALUE # R² other X (0 if none)
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  target_power <- TODO_PUBLISHED_VALUE # Power (1-beta err prob)
  total_n <- TODO_PUBLISHED_VALUE # Output: Total sample size
  actual_power <- TODO_PUBLISHED_VALUE # Output: Actual power
  skip_if_todo(odds_ratio, base_prob, r2_other, alpha, tails, target_power, total_n, actual_power)

  spec <- logistic_spec(odds_ratio, base_prob, alpha, tails, seed = 201, r2_other = r2_other, target_power = target_power)
  expect_n_near(engine_n_required(spec), total_n)
  spec <- logistic_spec(odds_ratio, base_prob, alpha, tails, seed = 201, r2_other = r2_other, n = total_n)
  expect_power_exact(engine_power(spec), actual_power)
})

test_that("logistic regression, yes/no X: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), the chapter
  #   "z test: Logistic regression", its example with a binomial X (one
  #   trial: a yes/no group): a priori analysis. Joel: add the section and
  #   page. G*Power's "X parm π" is powerkit's x_prob (the proportion in
  #   X's second level).
  odds_ratio <- TODO_PUBLISHED_VALUE # Odds ratio
  base_prob <- TODO_PUBLISHED_VALUE # Pr(Y=1|X=1) H0
  x_prob <- TODO_PUBLISHED_VALUE # X parm π
  r2_other <- TODO_PUBLISHED_VALUE # R² other X (0 if none)
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  target_power <- TODO_PUBLISHED_VALUE # Power (1-beta err prob)
  total_n <- TODO_PUBLISHED_VALUE # Output: Total sample size
  actual_power <- TODO_PUBLISHED_VALUE # Output: Actual power
  skip_if_todo(odds_ratio, base_prob, x_prob, r2_other, alpha, tails, target_power, total_n, actual_power)

  spec <- logistic_spec(
    odds_ratio, base_prob, alpha, tails, seed = 202, x = "binary", x_prob = x_prob,
    r2_other = r2_other, target_power = target_power
  )
  expect_n_near(engine_n_required(spec), total_n)
  spec <- logistic_spec(
    odds_ratio, base_prob, alpha, tails, seed = 202, x = "binary", x_prob = x_prob,
    r2_other = r2_other, n = total_n
  )
  expect_power_exact(engine_power(spec), actual_power)
})
