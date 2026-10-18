# Generic tests (design generic_test): power from a noncentrality
# parameter and degrees of freedom, as G*Power's "Generic" tests, each one
# pwrss call. Checked against pwrss called directly, and against the
# noncentral distributions in base R's stats package.

generic_spec <- function(name, goal = list(type = "power"), ...) {
  spec <- example_spec(name)
  spec$options <- list(seed = 7)
  spec$goal <- goal
  changes <- list(...)
  spec[names(changes)] <- changes
  spec
}

test_that("each generic test gives pwrss's power for the noncentrality given", {
  t <- run_spec(generic_spec("generic_t"))
  expect_equal(t$provenance$backend_function, "pwrss::power.t.test")
  expect_equal(t$curve$power, pwrss::power.t.test(ncp = 2.5, df = 30, alpha = 0.05, plot = FALSE, verbose = 0)$power)
  f <- run_spec(generic_spec("generic_f"))
  expect_equal(f$curve$power, pwrss::power.f.test(ncp = 10, df1 = 2, df2 = 60, alpha = 0.05, plot = FALSE, verbose = 0)$power)
  chi <- run_spec(generic_spec("generic_chi_square"))
  expect_equal(chi$curve$power, pwrss::power.chisq.test(ncp = 10, df = 2, alpha = 0.05, plot = FALSE, verbose = 0)$power)
  z <- run_spec(generic_spec("generic_z"))
  expect_equal(z$curve$power, pwrss::power.z.test(mean = 2.5, alpha = 0.05, plot = FALSE, verbose = 0)$power)
  for (r in list(t, f, chi, z)) {
    expect_true(is.na(r$curve$n))
    expect_equal(r$provenance$method, "exact")
  }
})

test_that("generic power agrees with the noncentral distributions in base R", {
  crit_t <- stats::qt(0.975, 30)
  base_t <- stats::pt(crit_t, 30, ncp = 2.5, lower.tail = FALSE) + stats::pt(-crit_t, 30, ncp = 2.5)
  expect_equal(run_spec(generic_spec("generic_t"))$curve$power, base_t, tolerance = 1e-6)
  base_f <- stats::pf(stats::qf(0.95, 2, 60), 2, 60, ncp = 10, lower.tail = FALSE)
  expect_equal(run_spec(generic_spec("generic_f"))$curve$power, base_f, tolerance = 1e-6)
  base_chi <- stats::pchisq(stats::qchisq(0.95, 2), 2, ncp = 10, lower.tail = FALSE)
  expect_equal(run_spec(generic_spec("generic_chi_square"))$curve$power, base_chi, tolerance = 1e-6)
  crit_z <- stats::qnorm(0.975)
  base_z <- stats::pnorm(crit_z, 2.5, lower.tail = FALSE) + stats::pnorm(-crit_z, 2.5)
  expect_equal(run_spec(generic_spec("generic_z"))$curve$power, base_z, tolerance = 1e-6)
})

test_that("the noncentrality needed for a target power gives that power", {
  for (name in c("generic_t", "generic_f", "generic_chi_square", "generic_z")) {
    found <- run_spec(generic_spec(name, list(type = "sensitivity", power = 0.8)))$sensitivity
    expect_equal(found$power, 0.8, info = name)
    spec <- generic_spec(name)
    spec$population$ncp <- found$effect
    expect_equal(run_spec(spec)$curve$power, 0.8, tolerance = 1e-4, info = name)
  }
})

test_that("generic tests take no sample size, and their direction must fit the noncentrality", {
  expect_error(validate_spec(generic_spec("generic_t", list(type = "sample_size", power = 0.8))), class = "powerkit_spec_error")
  expect_error(validate_spec(generic_spec("generic_t", list(type = "power", n = 50))), class = "powerkit_spec_error")
  spec <- generic_spec("generic_t")
  spec$target_test$alternative <- "less"
  expect_spec_problem(spec, "goes the other way")
  spec$population$ncp <- -2.5
  expect_equal(run_spec(spec)$curve$power, pwrss::power.t.test(ncp = 2.5, df = 30, alternative = "one.sided", plot = FALSE, verbose = 0)$power)
  spec <- generic_spec("generic_f")
  spec$target_test$alternative <- "greater"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  # Other designs still need n for power.
  other <- example_spec("independent_t")
  other$goal <- list(type = "power")
  expect_error(validate_spec(other), class = "powerkit_spec_error")
})

test_that("exported scripts for the generic tests reproduce powerkit's results", {
  skip_on_cran()
  for (name in c("generic_t", "generic_f", "generic_chi_square", "generic_z")) {
    for (goal in list(list(type = "power"), list(type = "sensitivity", power = 0.8))) {
      spec <- generic_spec(name, goal)
      result <- run_spec(spec)
      out <- run_exported_script(spec, result)
      expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = paste(name, goal$type))
    }
  }
})
