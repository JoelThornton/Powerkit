# Validation: simple mediation's quick estimate (target_test > method
# "joint_significance"). Backend: pwrss's power.z.mediation(method =
# "joint") formula. Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-mediation-joint.R)
#      check powerkit against pwrss called directly and against the product
#      of the two z-test powers written out in base R
#   2. published examples: below, for the maintainer to choose and
#      transcribe
#   3. simulation: below; the formula against simulated regressions tested
#      by the joint-significance test
#   4. Type I error: below; with one path 0 the test rejects at most alpha
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

joint_validation_spec <- function(a, b, cp, n) {
  spec <- example_spec("mediation_simple")
  spec$variables$X <- list(type = "continuous", label = "X")
  spec$population$paths <- list("X->M" = a, "M->Y" = b, "X->Y" = cp)
  spec$target_test$method <- "joint_significance"
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 1)
  spec
}

simulated_joint_power <- function(a, b, cp, n, nrep, seed) {
  set.seed(seed)
  residual_y <- 1 - (b^2 + cp^2 + 2 * a * b * cp)
  mean(replicate(nrep, {
    x <- stats::rnorm(n)
    m <- a * x + stats::rnorm(n, sd = sqrt(1 - a^2))
    y <- b * m + cp * x + stats::rnorm(n, sd = sqrt(residual_y))
    summary(stats::lm(m ~ x))$coefficients[2, 4] < 0.05 && summary(stats::lm(y ~ x + m))$coefficients[3, 4] < 0.05
  }))
}

test_that("joint-significance estimate: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE. A published power or sample size for
  # the joint-significance test of a simple indirect effect, with
  # standardised paths, for the maintainer to choose.
  a <- TODO_PUBLISHED_VALUE # path X -> M
  b <- TODO_PUBLISHED_VALUE # path M -> Y
  cp <- TODO_PUBLISHED_VALUE # path X -> Y
  n <- TODO_PUBLISHED_VALUE # sample size
  power <- TODO_PUBLISHED_VALUE # Output: power
  skip_if_todo(a, b, cp, n, power)
  expect_equal(run_spec(joint_validation_spec(a, b, cp, n))$curve$power, power, tolerance = 0.01)
})

test_that("joint-significance estimate: simulated regressions agree within the formula's known optimism", {
  skip_unless_full_validation()
  for (cfg in list(c(0.3, 0.3, 0, 100), c(-0.25, -0.3, 0.1, 200), c(0.2, 0.4, 0.2, 150))) {
    formula <- run_spec(joint_validation_spec(cfg[1], cfg[2], cfg[3], cfg[4]))$curve$power
    simulated <- simulated_joint_power(cfg[1], cfg[2], cfg[3], cfg[4], nrep = 5000, seed = 601)
    margin <- 4 * sqrt(simulated * (1 - simulated) / 5000)
    # The large-sample z tests make the formula a little optimistic, never
    # pessimistic beyond simulation error.
    expect_gt(formula, simulated - margin)
    expect_lt(formula - simulated, 0.04 + margin)
  }
})

test_that("joint-significance estimate: with the X -> M path at 0 the rejection rate is at most alpha (Type I error)", {
  skip_unless_full_validation()
  rate <- simulated_joint_power(0, 0.5, 0, 200, nrep = 5000, seed = 602)
  expect_lt(rate, 0.05 + 4 * sqrt(0.05 * 0.95 / 5000))
  expect_lte(run_spec(joint_validation_spec(1e-9, 0.5, 0, 200))$curve$power, 0.05 + 1e-6)
})
