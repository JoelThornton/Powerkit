# Validation: Poisson regression, the Wald z test of one predictor of a
# count outcome. Backend: pwrss's power.z.poisson() by formula (Demidenko's
# method with variance correction). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-formula-tests.R)
#      check powerkit against pwrss called directly
#   2. published examples: the G*Power 3.1 manual (below)
#   3. direct-call agreement with a simulation: not yet (no simulation
#      option)
#   4. Type I error: a rate ratio of 1 gives alpha by construction (unit
#      tests)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `x` is "normal" (a standardised score) or "binary" (a yes/no group with
# `x_prob` in its second level).
poisson_spec <- function(rate_ratio, base_rate, alpha, tails, seed, x = "normal",
                         x_prob = NULL, mean_exposure = 1, r2_other = 0,
                         n = NULL, target_power = NULL) {
  v <- validation_variable
  variables <- list(
    X = if (x == "binary") v("binary", "Group", levels = list("First", "Second")) else v("continuous", "Predictor"),
    Y = v("count", "Events")
  )
  population <- list(metric = "rate_ratio", rate_ratio = rate_ratio, base_rate = base_rate)
  if (mean_exposure != 1) population$mean_exposure <- mean_exposure
  if (!is.null(x_prob)) population$x_prob <- x_prob
  if (r2_other > 0) population$r2_other_predictors <- r2_other
  validation_spec(
    design = "poisson_regression",
    template = "single_predictor_count",
    variables = variables,
    population = population,
    target_test = list(
      effect = "rate_ratio", method = "wald_z", alpha = alpha,
      alternative = if (tails == 1) (if (rate_ratio > 1) "greater" else "less") else "two_sided"
    ),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 2. Published examples: G*Power 3.1 -------------------------------------------
#
# G*Power's inputs, confirmed against the manual (section 30, pp. 75-80):
#   "Exp(beta1)", "Base rate exp(beta0)", "Mean exposure", "R2 other X",
#   "X distribution" and its parameters.
#   * "Exp(beta1)" is powerkit's rate_ratio and "Base rate exp(beta0)" its
#     base_rate; "Mean exposure" is mean_exposure, the exposure time t in
#     the manual's equations (16) to (18), p. 77.
#   * "R2 other X" is powerkit's r2_other_predictors: the correction for
#     other covariates of Hsieh, Bloch and Larsen (1998), which is pwrss's
#     r.squared.predictor.
#   * powerkit takes a score X as standardised (mean 0, SD 1), which is
#     G*Power's "X distribution: Normal" with "X parm mu" 0 and "X parm
#     sigma" 1; a yes/no X is "X distribution: Binomial" with "X parm pi"
#     = x_prob (one trial). G*Power's other X distributions (uniform,
#     lognormal, exponential, Poisson) are not in powerkit.
# Procedure: G*Power offers the enumeration procedure of Lyles et al.
#   (2007), Demidenko (2007) with or without variance correction, and
#   Signorini (1991). The manual recommends Demidenko as the standard
#   procedure and says Signorini's "is problematic and should not be used;
#   it is only included to allow checks of published results" (30.2,
#   p. 76). powerkit uses Demidenko with variance correction (pwrss's
#   default), so set Options > Procedure to that before transcribing. The
#   manual's first worked example prints the Signorini output instead, and
#   gives the other procedures' sample sizes in the text (30.3, p. 77).
# "R2 other X" above 0: unlike logistic regression (Known difference 3 in
#   docs/conventions.md), powerkit reproduces the manual's Poisson figure
#   for R2 > 0 exactly, for the procedure the manual used there (30.3,
#   p. 77, gives 774 with Signorini's procedure for the swimmers example at
#   R2 = 0.1, and pwrss's "signorini" method also gives 774). So an example
#   with "R2 other X" above 0 is usable here.

test_that("Poisson regression, yes/no X: required N matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 30.3
  #   ("Z tests: Poisson Regression", Examples), pp. 76-77: the swimmers
  #   example from Signorini (1991), p. 449 (infections in swimmers against
  #   non-swimmers over one swimming season), a priori analysis.
  #   Transcribe the Input block, but take the sample size from the text
  #   after the Output block, which gives N for Demidenko (2007) with
  #   variance correction, the procedure powerkit uses. The printed Output
  #   block is Signorini's procedure, so neither its "Total sample size"
  #   nor its "Actual power" belongs here, and no actual power is published
  #   for the Demidenko sample size: this test checks the required N only.
  rate_ratio <- TODO_PUBLISHED_VALUE # Exp(beta1)
  base_rate <- TODO_PUBLISHED_VALUE # Base rate exp(beta0)
  mean_exposure <- TODO_PUBLISHED_VALUE # Mean exposure
  x_prob <- TODO_PUBLISHED_VALUE # X parm pi
  r2_other <- TODO_PUBLISHED_VALUE # R2 other X (0 if none)
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  target_power <- TODO_PUBLISHED_VALUE # Power (1-beta err prob)
  total_n <- TODO_PUBLISHED_VALUE # N for Demidenko (2007) with variance correction
  skip_if_todo(rate_ratio, base_rate, mean_exposure, x_prob, r2_other, alpha, tails, target_power, total_n)

  spec <- poisson_spec(
    rate_ratio, base_rate, alpha, tails, seed = 201, x = "binary", x_prob = x_prob,
    mean_exposure = mean_exposure, r2_other = r2_other, target_power = target_power
  )
  expect_n_near(engine_n_required(spec), total_n)
})

test_that("Poisson regression, normal X: power matches the G*Power 3.1 manual's comparison (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 30.4
  #   ("Z tests: Poisson Regression", Comparison between procedures),
  #   pp. 77-78: one row of Table 2 with "Dist. X" = N(0,1), where every
  #   scenario is a two-sided post hoc analysis with N = 200, beta0 = 0.5
  #   and alpha = 0.05 (so base_rate is exp(0.5) and rate_ratio is
  #   exp(beta1) for the row's beta1).
  # Transcribe the power from the "Demi(c)" column (Demidenko with variance
  #   correction), which is powerkit's procedure. Table 2 prints 3
  #   decimals, and expect_power_exact() allows half a unit in the last
  #   printed digit. The fuller output printed above the table (section
  #   30.4, p. 77: 0.444593 for the first row) is the uncorrected
  #   Demidenko procedure, not powerkit's; for a symmetric X the two agree
  #   to about 6 decimal places, but transcribe the "Demi(c)" column.
  n <- TODO_PUBLISHED_VALUE # Total sample size (the table's fixed N)
  base_rate <- TODO_PUBLISHED_VALUE # Base rate exp(beta0), as "=exp(0.5)" in G*Power
  rate_ratio <- TODO_PUBLISHED_VALUE # Exp(beta1) for the row's beta1, as "=exp(-0.1)"
  mean_exposure <- TODO_PUBLISHED_VALUE # Mean exposure
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  published_power <- TODO_PUBLISHED_VALUE # Table 2, "Demi(c)" column
  skip_if_todo(n, base_rate, rate_ratio, mean_exposure, alpha, tails, published_power)

  spec <- poisson_spec(
    rate_ratio, base_rate, alpha, tails, seed = 202,
    mean_exposure = mean_exposure, n = n
  )
  expect_power_exact(engine_power(spec), published_power)
})

test_that("Poisson regression, yes/no X: power matches the G*Power 3.1 manual's comparison (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 30.4,
  #   Table 2, pp. 77-78: one row with "Dist. X" = Bin(pi), transcribed as
  #   above (two-sided, N = 200, beta0 = 0.5, alpha = 0.05) with G*Power's
  #   "X parm pi" as x_prob. These rows matter because the X distribution
  #   is not symmetric about its mean, which is where the variance
  #   correction changes the answer (30.5.2, p. 77), so the row's "Demi"
  #   and "Demi(c)" columns differ: transcribe "Demi(c)".
  n <- TODO_PUBLISHED_VALUE # Total sample size (the table's fixed N)
  base_rate <- TODO_PUBLISHED_VALUE # Base rate exp(beta0)
  rate_ratio <- TODO_PUBLISHED_VALUE # Exp(beta1) for the row's beta1
  x_prob <- TODO_PUBLISHED_VALUE # X parm pi, the pi of the row's Bin(pi)
  mean_exposure <- TODO_PUBLISHED_VALUE # Mean exposure
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  published_power <- TODO_PUBLISHED_VALUE # Table 2, "Demi(c)" column
  skip_if_todo(n, base_rate, rate_ratio, x_prob, mean_exposure, alpha, tails, published_power)

  spec <- poisson_spec(
    rate_ratio, base_rate, alpha, tails, seed = 203, x = "binary", x_prob = x_prob,
    mean_exposure = mean_exposure, n = n
  )
  expect_power_exact(engine_power(spec), published_power)
})
