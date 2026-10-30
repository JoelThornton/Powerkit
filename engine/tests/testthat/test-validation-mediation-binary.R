# Validation: simple mediation with a yes/no X (E16; PROCESS model 4).
# Backend: power4mome, with X drawn by rbinary_rs() (rescaled to SD 1, so
# the paths are per SD of X). Build guide section 6:
#   1. analytic agreement: an independent simulation. X is drawn as two
#      groups and rescaled, M and Y from the standardised paths with
#      residual variances that give each SD 1; each data set is fitted by
#      OLS and the indirect effect tested with a Monte Carlo confidence
#      interval from the two estimates and their standard errors. OLS
#      standard errors are slightly larger than power4mome's lavaan ones
#      (Departure 6), so this reference is a little conservative.
#   2. published examples: placeholders below, for the maintainer
#   3. direct-call agreement with power4mome
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

binary_mediation_spec <- function(paths, seed, n, x_prob = NULL) {
  spec_args <- list(
    design = "mediation",
    template = "process_4",
    variables = list(
      X = validation_variable("binary", "Condition", levels = list("Control", "Treatment")),
      M = validation_variable("continuous", "Mediator"),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = c(list(metric = "standardised", paths = paths), if (!is.null(x_prob)) list(x_prob = x_prob)),
    target_test = list(effect = "indirect_effect", path = "X->M->Y", method = "monte_carlo_ci", alpha = 0.05),
    seed = seed,
    n = n,
    options = list(ci_draws = validation_ci_draws())
  )
  do.call(validation_spec, spec_args)
}

# 1. Independent simulation ----------------------------------------------------------

test_that("mediation with a yes/no X: agrees with an independent simulation (analytic)", {
  skip_unless_full_validation()
  a <- 0.3
  b <- 0.3
  c_prime <- 0.1
  p <- 0.3
  n <- 150
  spec <- binary_mediation_spec(list("X->M" = a, "M->Y" = b, "X->Y" = c_prime), seed = 1601, n = n, x_prob = p)
  reps <- validation_nrep()
  draws <- validation_ci_draws()
  rejected <- with_seed(1602, vapply(seq_len(reps), function(i) {
    x <- (stats::rbinom(n, 1, p) - p) / sqrt(p * (1 - p))
    m <- a * x + stats::rnorm(n, sd = sqrt(1 - a^2))
    y <- b * m + c_prime * x + stats::rnorm(n, sd = sqrt(1 - (b^2 + c_prime^2 + 2 * a * b * c_prime)))
    fm <- summary(stats::lm(m ~ x))$coefficients
    fy <- summary(stats::lm(y ~ m + x))$coefficients
    ab <- stats::rnorm(draws, fm["x", 1], fm["x", 2]) * stats::rnorm(draws, fy["m", 1], fy["m", 2])
    ci <- stats::quantile(ab, c(0.025, 0.975))
    ci[1] > 0 || ci[2] < 0
  }, logical(1)))
  reference <- list(power = mean(rejected), mcse = sqrt(mean(rejected) * (1 - mean(rejected)) / reps))
  # OLS standard errors make the reference slightly low: allow it to sit up
  # to one percentage point below powerkit's estimate beyond Monte Carlo error.
  estimate <- engine_power(spec)
  expect_lt(abs(estimate$power - reference$power - 0.005), 3.29 * sqrt(estimate$mcse^2 + reference$mcse^2) + 0.005)
})

# 2. Published example ------------------------------------------------------------

test_that("mediation with a yes/no X: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for simple mediation with a two-group X).
  paths <- TODO_PUBLISHED_VALUE # list("X->M" = , "M->Y" = , "X->Y" = ), standardised
  x_prob <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(paths, x_prob, n, published_power, reference_nrep)
  spec <- binary_mediation_spec(paths, seed = 1603, n = n, x_prob = x_prob)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct call -------------------------------------------------------------------

test_that("mediation with a yes/no X: powerkit matches a direct power4mome call", {
  skip_unless_full_validation()
  spec <- binary_mediation_spec(list("X->M" = 0.3, "M->Y" = 0.3, "X->Y" = 0.1), seed = 1604, n = 120)
  direct <- direct_power4mome(
    model = "M ~ X\nY ~ M + X",
    pop_es = "M ~ X: 0.3\nY ~ M: 0.3\nY ~ X: 0.1",
    n = 120, test = "indirect", x = "X", m = "M", y = "Y",
    ci_draws = validation_ci_draws(), nrep = validation_nrep(), seed = 1604,
    x_fun = list(X = list(power4mome::rbinary_rs, p1 = 0.5))
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("mediation with a yes/no X: Type I error is near alpha when a = 0 and b is large", {
  skip_unless_full_validation()
  spec <- binary_mediation_spec(list("X->M" = 0, "M->Y" = 0.5, "X->Y" = 0), seed = 1605, n = 200)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
