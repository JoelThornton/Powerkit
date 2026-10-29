# Validation: a two-way interaction in regression with a yes/no X or W
# (E15). Backend: InteractionPoweR's power_interaction() with k.x1 or
# k.x2 = 2 (a 50/50 split, coded -1 and 1). Build guide section 6:
#   1. analytic agreement: an independent simulation. With X yes/no and
#      uncorrelated with W, X, W and XW are uncorrelated with unit
#      variance, so each standardised coefficient equals that predictor's
#      correlation with Y; Y is drawn from those coefficients and lm()
#      tests XW.
#   2. published examples: placeholders below, for the maintainer
#   3. direct-call agreement with InteractionPoweR::power_interaction()
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

binary_interaction_spec <- function(r_x_y, r_w_y, r_xw_y, r_x_w, seed, n = NULL, binary = "X", alpha = 0.05) {
  v <- validation_variable
  roles <- list(
    X = if (binary == "X") v("binary", "Condition", levels = list("Control", "Treatment")) else v("continuous", "Predictor"),
    W = if (binary == "W") v("binary", "Group", levels = list("First", "Second")) else v("continuous", "Moderator")
  )
  validation_spec(
    design = "regression_interaction",
    template = "two_way",
    variables = c(roles, list(Y = v("continuous", "Outcome"))),
    population = list(metric = "correlation", r_X_Y = r_x_y, r_W_Y = r_w_y, r_XW_Y = r_xw_y, r_X_W = r_x_w),
    target_test = list(effect = "interaction", method = "ols_t", alpha = alpha),
    seed = seed,
    n = n
  )
}

# 1. Independent simulation ----------------------------------------------------------

test_that("binary interaction: agrees with an independent simulation (analytic)", {
  skip_unless_full_validation()
  r <- c(x = 0.2, w = -0.3, xw = 0.15)
  n <- 250
  spec <- binary_interaction_spec(r[["x"]], r[["w"]], r[["xw"]], 0, seed = 1501, n = n)
  reps <- validation_nrep()
  rejected <- with_seed(1502, vapply(seq_len(reps), function(i) {
    x <- sample(rep(c(-1, 1), n / 2))
    w <- stats::rnorm(n)
    y <- r[["x"]] * x + r[["w"]] * w + r[["xw"]] * x * w + stats::rnorm(n, sd = sqrt(1 - sum(r^2)))
    summary(stats::lm(y ~ x * w))$coefficients["x:w", 4] < 0.05
  }, logical(1)))
  expect_power_near(engine_power(spec), mean(rejected), reference_nrep = reps)
})

# 2. Published example ------------------------------------------------------------

test_that("binary interaction: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for a moderated regression with a yes/no X or W).
  correlations <- TODO_PUBLISHED_VALUE # list(r_X_Y, r_W_Y, r_XW_Y, r_X_W)
  binary <- TODO_PUBLISHED_VALUE # "X" or "W"
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(correlations, binary, n, published_power, reference_nrep)
  spec <- binary_interaction_spec(correlations[[1]], correlations[[2]], correlations[[3]], correlations[[4]],
    seed = 1503, n = n, binary = binary)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct call -------------------------------------------------------------------

test_that("binary interaction: powerkit matches InteractionPoweR called directly (yes/no W)", {
  skip_unless_full_validation()
  spec <- binary_interaction_spec(0.3, 0.2, 0.12, 0.1, seed = 1504, n = 300, binary = "W")
  reps <- validation_nrep()
  direct <- with_seed(1505, suppressMessages(InteractionPoweR::power_interaction(
    n.iter = reps, N = 300, r.x1.y = 0.3, r.x2.y = 0.2, r.x1x2.y = 0.12, r.x1.x2 = 0.1, k.x2 = 2
  )))$pwr[1]
  expect_power_near(engine_power(spec), direct, reference_nrep = reps)
})

# 4. Type I error ------------------------------------------------------------------

test_that("binary interaction: Type I error is alpha when the interaction is zero", {
  skip_unless_full_validation()
  spec <- binary_interaction_spec(0.25, -0.2, 0, 0, seed = 1506, n = 200)
  expect_power_near(engine_power(spec), 0.05)
})
