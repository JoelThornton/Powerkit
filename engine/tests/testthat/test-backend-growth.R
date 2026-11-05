# Growth curves (two groups measured three or more times; the difference in
# average rates of change), by Diggle and colleagues' formula in longpower.
# Translation, the power found by solving the formula for n the other way,
# the check run, refusals and the exported script; accuracy is checked by
# test-validation-growth.R.

growth_spec <- function(n = 200, alternative = NULL) {
  spec <- example_spec("growth_curve")
  spec$target_test$alternative <- alternative
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("growth curves run on longpower and pass their check run", {
  result <- run_quietly(growth_spec())
  expect_equal(result$provenance$backend, "longpower")
  expect_true("longpower" %in% names(result$provenance$packages))
  expect_true(all(result$check_run$ok))
})

test_that("the power is diggle.linear.power()'s, where its own power calculation works, and solves its sample size", {
  inputs <- growth_inputs(validate_spec(growth_spec()))
  direct <- longpower::diggle.linear.power(n = 100, delta = 1, t = inputs$t, sigma2 = 1, R = inputs$R, sig.level = 0.05)$power
  expect_equal(growth_power(inputs, 200), direct, tolerance = 1e-6)
  n80 <- longpower::diggle.linear.power(delta = 1, t = inputs$t, sigma2 = 1, R = inputs$R, sig.level = 0.05, power = 0.8)$n[1]
  expect_equal(growth_power(inputs, 2 * n80), 0.8, tolerance = 1e-6)
  # Where its own power calculation fails (small groups) or returns about
  # 0 (large ones), powerkit's stays between alpha and 1 and rises with n.
  powers <- vapply(c(4, 20, 100, 1000, 4000), function(n) growth_power(inputs, n), numeric(1))
  expect_true(all(diff(powers) >= 0))
  expect_true(powers[5] > 0.999)
})

test_that("the covariance comes from the random effects as in longpower's help example", {
  inputs <- growth_inputs(validate_spec(growth_spec()))
  t <- c(0, 1, 2, 3)
  cov_is <- -0.2 * 6 * 2
  expected <- outer(t, t, function(a, b) 36 + a * b * 4 + (a + b) * cov_is) + diag(16, 4)
  expect_equal(inputs$R, expected)
})

test_that("one-sided tests point the right way, and the refusals are in plain English", {
  expect_gt(run_quietly(growth_spec(alternative = "less"))$curve$power, run_quietly(growth_spec())$curve$power)
  expect_spec_problem(growth_spec(alternative = "greater"), "one-sided")
  spec <- growth_spec()
  spec$population$times <- list(0, 2, 1)
  expect_spec_problem(spec, "increasing order")
  spec <- growth_spec()
  spec$options$allocation_ratio <- 2
  expect_spec_problem(spec, "equal groups")
})

test_that("the R script reproduces the run, and the simulated data are in long format", {
  skip_unless_scripts_can_run()
  spec <- growth_spec()
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-8)
  data <- simulated_data(spec, 100)
  expect_equal(nrow(data), 400)
  expect_true(all(c("Participant", "Time") %in% names(data)))
})
