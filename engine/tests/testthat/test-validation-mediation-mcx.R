# Validation: mediation with X in three or more groups (E42; PROCESS
# model 4 with a multicategorical X, Hayes & Preacher 2014).
# Backend: Spower runs the studies; each is fitted by lavaan and every
# tested relative indirect effect (a_j * b, dummy coding against the first
# group) gets manymome's Monte Carlo percentile interval. Build guide
# section 6:
#   1. analytic agreement: an independent simulation. Each data set is
#      drawn in base R, fitted by OLS (lm(), one equation at a time), and
#      each relative indirect effect tested with a Monte Carlo interval
#      drawn by hand from the estimates and their standard errors (a_j and
#      b are uncorrelated across the two equations). OLS standard errors
#      are slightly larger than lavaan's maximum-likelihood ones
#      (Departure 6), so this reference is a little conservative.
#   2. published examples: placeholders below, for the maintainer
#   3. Type I error, when the tested group's a_j is 0 and b is large
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

mcx_validation_spec <- function(a, b, direct, group, seed, n) {
  validation_spec(
    design = "mediation",
    template = "multicategorical",
    variables = list(
      X = validation_variable("categorical", "Condition", levels = list("Control", "Treatment A", "Treatment B")),
      M = validation_variable("continuous", "Mediator"),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = list(metric = "standardised", m_differences = as.list(a), b = b, direct_differences = as.list(direct)),
    target_test = list(effect = "indirect_effect", path = "X->M->Y", method = "monte_carlo_ci", alpha = 0.05, group = group),
    seed = seed,
    n = n,
    options = list(ci_draws = validation_ci_draws())
  )
}

# The independent reference: the share of studies in which every tested
# relative indirect effect's 95% Monte Carlo interval excludes 0.
mcx_reference_power <- function(a, b, direct, tested, n, seed) {
  reps <- validation_nrep()
  draws <- validation_ci_draws()
  k <- length(a) + 1
  rejected <- with_seed(seed, vapply(seq_len(reps), function(i) {
    group <- factor(ceiling(seq_len(n) / (n / k)))
    m <- c(0, a)[group] + stats::rnorm(n)
    y <- b * m + c(0, direct)[group] + stats::rnorm(n, sd = sqrt(1 - b^2))
    fm <- summary(stats::lm(m ~ group))$coefficients
    fy <- summary(stats::lm(y ~ m + group))$coefficients
    b_draws <- stats::rnorm(draws, fy["m", 1], fy["m", 2])
    all(vapply(tested, function(j) {
      row <- paste0("group", j + 1)
      ab <- stats::rnorm(draws, fm[row, 1], fm[row, 2]) * b_draws
      ci <- stats::quantile(ab, c(0.025, 0.975))
      ci[1] > 0 || ci[2] < 0
    }, logical(1)))
  }, logical(1)))
  list(power = mean(rejected), mcse = sqrt(mean(rejected) * (1 - mean(rejected)) / reps))
}

# 1. Independent simulation ----------------------------------------------------------

test_that("mediation with X in three groups: agrees with an independent simulation, one group tested (analytic)", {
  skip_unless_full_validation()
  a <- c(0.3, 0.5)
  b <- 0.3
  direct <- c(0, 0.1)
  spec <- mcx_validation_spec(a, b, direct, "Treatment B", seed = 4201, n = 150)
  reference <- mcx_reference_power(a, b, direct, tested = 2, n = 150, seed = 4202)
  # OLS standard errors make the reference slightly low: allow it to sit up
  # to one percentage point below powerkit's estimate beyond Monte Carlo error.
  estimate <- engine_power(spec)
  expect_lt(abs(estimate$power - reference$power - 0.005), 3.29 * sqrt(estimate$mcse^2 + reference$mcse^2) + 0.005)
})

test_that("mediation with X in three groups: agrees with an independent simulation, every group tested (analytic)", {
  skip_unless_full_validation()
  a <- c(0.4, 0.6)
  b <- 0.3
  direct <- c(0.1, 0)
  spec <- mcx_validation_spec(a, b, direct, "all", seed = 4203, n = 210)
  reference <- mcx_reference_power(a, b, direct, tested = 1:2, n = 210, seed = 4204)
  estimate <- engine_power(spec)
  expect_lt(abs(estimate$power - reference$power - 0.005), 3.29 * sqrt(estimate$mcse^2 + reference$mcse^2) + 0.005)
})

# 2. Published example ------------------------------------------------------------

test_that("mediation with X in three groups: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for mediation with a multicategorical X).
  a <- TODO_PUBLISHED_VALUE # each later group's d against the first on M
  b <- TODO_PUBLISHED_VALUE # within-group standardised M -> Y
  direct <- TODO_PUBLISHED_VALUE
  group <- TODO_PUBLISHED_VALUE # "all", or the tested group
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(a, b, direct, group, n, published_power, reference_nrep)
  spec <- mcx_validation_spec(a, b, direct, group, seed = 4205, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Type I error ------------------------------------------------------------------

test_that("mediation with X in three groups: Type I error is at or below alpha when the tested a_j = 0 and b is large", {
  skip_unless_full_validation()
  # With b large the interval of a_j * b behaves like a test of a_j alone,
  # so the rejection rate should be near alpha.
  spec <- mcx_validation_spec(c(0.5, 0), 0.5, c(0, 0), "Treatment B", seed = 4206, n = 240)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
