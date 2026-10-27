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
# G*Power's inputs, confirmed against the manual (section 29, pp. 70-74):
#   "Odds ratio", "Pr(Y=1|X=1) H0", "R² other X", "X distribution" and its
#   parameters.
#   * "Pr(Y=1|X=1) H0" is powerkit's base_prob: the manual (29.1, p. 70)
#     defines it as p1, the probability of an event under H0, where
#     beta1 = 0 and so Y doesn't depend on X.
#   * "R² other X" is powerkit's r2_other_predictors: the correction
#     N' = N / (1 - R²) of Hsieh, Bloch and Larsen (1998) (29.1, p. 70),
#     which is pwrss's r.squared.predictor. See the caution below.
#   * powerkit takes a score X as standardised (mean 0, SD 1), which is
#     G*Power's "X distribution: Normal" with "X parm µ" 0 and "X parm σ"
#     1; if the example's X has another mean or SD, note it here instead
#     of transcribing.
# Procedure: G*Power offers an enumeration procedure (Lyles et al., 2007)
#   and two large-sample approximations, Demidenko (2007) with or without
#   variance correction and Hsieh et al. (1998); the manual recommends
#   Demidenko as the standard procedure, and its simulations found
#   Demidenko with variance correction the most accurate (29.2, p. 70;
#   Table 1, p. 74). powerkit uses Demidenko with variance correction
#   (pwrss's default), so set Options > Procedure to that before
#   transcribing. The manual's own worked examples select Hsieh et al.
#   (1998) instead, so their printed N is not powerkit's: for the
#   normal-X example the manual reports 317 for Hsieh against 337 for
#   Demidenko with variance correction (29.4, p. 71).
# Caution, "R² other X" above 0: with R² = 0 powerkit reproduces all three
#   of the manual's procedures exactly (337, 355 and 317 for its normal-X
#   example). With R² = 0.1 the manual reports 395 where powerkit gives
#   375, and 395 is exactly powerkit's answer with the variance correction
#   switched off (355 / 0.9), so the two may differ in whether that
#   correction still applies once R² is above 0 (docs/decisions.md,
#   25 October 2026; the manual's own validation notes, 29.7, p. 73,
#   record a deviation from PASS in this case too). Prefer an example with
#   "R² other X" = 0 until that is settled.

test_that("logistic regression, normal X: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 29.4
  #   ("Z test: Multiple Logistic Regression", Examples), p. 71: the first
  #   example, a single predictor X that is normally distributed, a priori
  #   analysis. Transcribe the Input and Output blocks, with Options >
  #   Procedure set to Demidenko (2007) with variance correction (see the
  #   note above: the manual's printed output selects Hsieh et al., 1998).
  odds_ratio <- 1.5 # Odds ratio
  base_prob <- 0.5 # Pr(Y=1|X=1) H0
  r2_other <- 0 # R² other X (0 if none)
  alpha <- 0.05 # alpha err prob
  tails <- 2 # Tail(s): 1 or 2
  target_power <- 0.95 # Power (1-beta err prob)
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
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 29.4
  #   ("Z test: Multiple Logistic Regression", Examples), p. 72: the
  #   example with a binary covariate (G*Power's "X Distribution:
  #   Binomial", one trial), taken from Table I of Hsieh et al. (1998),
  #   a priori analysis. Transcribe the Input and Output blocks, with
  #   Options > Procedure set to Demidenko (2007) with variance correction
  #   (see the note above).
  # G*Power's "X parm π" is powerkit's x_prob (the proportion in X's second
  #   level). Its effect size input mode there is "Two probabilities"
  #   (Pr(Y=1|X=1) H1 and H0); powerkit takes the odds ratio, which is
  #   [p2/(1 - p2)] / [p1/(1 - p1)] (29.1, p. 70).
  odds_ratio <- (0.1 / 0.9) / (0.05 / 0.95) # Odds ratio
  base_prob <- 0.05 # Pr(Y=1|X=1) H0
  x_prob <- 0.5 # X parm π
  r2_other <- 0 # R² other X (0 if none)
  alpha <- 0.05 # alpha err prob
  tails <- 2 # Tail(s): 1 or 2
  target_power <- 0.95 # Power (1-beta err prob)
  total_n <- 1437 # Output: Total sample size
  actual_power <- 0.950068 # Output: Actual power
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
