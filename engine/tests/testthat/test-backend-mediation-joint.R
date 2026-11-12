# Simple mediation's quick estimate: the joint-significance test
# (target_test > method "joint_significance"), by pwrss's
# power.z.mediation(method = "joint") formula.

joint_spec <- function(a = 0.3, b = 0.3, cp = 0, goal = list(type = "power", n = 100), x = "continuous") {
  spec <- example_spec("mediation_simple")
  spec$variables$X <- if (x == "binary") spec$variables$X else list(type = "continuous", label = "Exposure")
  spec$population$paths <- list("X->M" = a, "M->Y" = b, "X->Y" = cp)
  spec$target_test$method <- "joint_significance"
  spec$goal <- goal
  spec$options <- list(seed = 1)
  spec
}

test_that("power is pwrss's joint-significance formula, with R-squared of Y including the X-M covariance", {
  result <- run_spec(joint_spec(cp = 0.2))
  expect_identical(result$provenance$backend, "pwrss")
  expect_true(all(result$check_run$ok))
  direct <- pwrss::power.z.mediation(beta.a = 0.3, beta.b = 0.3, beta.cp = 0.2,
    r.squared.mediator = 0.09, r.squared.outcome = 0.09 + 0.04 + 2 * 0.3 * 0.3 * 0.2,
    n = 100, method = "joint", verbose = 0)$power
  expect_equal(result$curve$power, direct)
  # The product of the two paths' z-test powers, written out with base R.
  se_a <- sqrt((1 - 0.09) / 100)
  se_b <- sqrt((1 - (0.09 + 0.04 + 0.036)) / (100 * (1 - 0.09)))
  z_power <- function(z) stats::pnorm(z - stats::qnorm(0.975)) + stats::pnorm(-z - stats::qnorm(0.975))
  expect_equal(result$curve$power, z_power(0.3 / se_a) * z_power(0.3 / se_b), tolerance = 1e-10)
  # pwrss's own default R-squared of Y leaves out 2 a b c', which matters
  # only when the direct path is not 0.
  default <- pwrss::power.z.mediation(beta.a = 0.3, beta.b = 0.3, beta.cp = 0.2, n = 100, method = "joint", verbose = 0)$power
  expect_gt(abs(default - direct), 0.001)
  no_direct <- pwrss::power.z.mediation(beta.a = 0.3, beta.b = 0.3, beta.cp = 0, n = 100, method = "joint", verbose = 0)$power
  expect_equal(run_spec(joint_spec())$curve$power, no_direct)
})

test_that("the sample size is found by searching n, and is instant", {
  result <- run_spec(joint_spec(goal = list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  power_at <- function(n) run_spec(joint_spec(goal = list(type = "power", n = n)))$curve$power
  expect_gte(power_at(n), 0.8)
  expect_lt(power_at(n - 1), 0.8)
  expect_equal(n, 110)
})

test_that("a simulation of the joint-significance test agrees within a few points (the formula's z tests are a little optimistic)", {
  set.seed(818)
  n <- 120
  both <- replicate(3000, {
    x <- stats::rnorm(n)
    m <- 0.3 * x + stats::rnorm(n, sd = sqrt(0.91))
    y <- 0.3 * m + stats::rnorm(n, sd = sqrt(0.91))
    summary(stats::lm(m ~ x))$coefficients[2, 4] < 0.05 && summary(stats::lm(y ~ x + m))$coefficients[3, 4] < 0.05
  })
  formula <- run_spec(joint_spec(goal = list(type = "power", n = n)))$curve$power
  expect_gt(formula, mean(both) - 0.01)
  expect_lt(formula - mean(both), 0.04)
})

test_that("a yes/no X uses the same paths per SD of X", {
  expect_equal(run_spec(joint_spec(x = "binary"))$curve$power, run_spec(joint_spec())$curve$power)
})

test_that("the estimate is refused, in plain English, beyond simple mediation or with simulation settings", {
  parallel <- example_spec("mediation_parallel")
  parallel$target_test$method <- "joint_significance"
  parallel$options$ci_draws <- NULL
  expect_spec_problem(parallel, "simple mediation with one mediator")
  draws <- joint_spec()
  draws$options$ci_draws <- 1000
  expect_spec_problem(draws, "remove 'options > ci_draws'")
})

test_that("the exported script reproduces the estimate", {
  for (goal in list(list(type = "power", n = 100), list(type = "sample_size", power = 0.8))) {
    spec <- joint_spec(cp = 0.1, goal = goal)
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
  }
})
