# Reliability and agreement: the ICC by ICC.Sample.Size, Cronbach's alpha
# by Bonett and Wright's test (statpsych's sample size), kappa by
# kappaSize. The translation is checked against the packages called
# directly, and against their help examples.

reliability_spec <- function(name, goal, ...) {
  spec <- example_spec(name)
  spec$goal <- goal
  changes <- list(...)
  for (field in names(changes)) spec$population[[field]] <- changes[[field]]
  spec
}

test_that("the ICC runs on calculateIccPower(), exactly, and passes its check run", {
  result <- run_spec(reliability_spec("reliability_icc", list(type = "power", n = 30)))
  expect_equal(result$provenance$backend, "ICC.Sample.Size")
  expect_equal(result$provenance$method, "exact")
  expect_true(all(result$check_run$ok))
  direct <- ICC.Sample.Size::calculateIccPower(p = 0.8, p0 = 0.6, k = 3, alpha = 0.05, tails = 1, N = 30)[[1]]$power
  expect_equal(result$curve$power, direct, tolerance = 1e-12)
  # The required n is the package's own sample size.
  n <- run_spec(example_spec("reliability_icc"))$n_required$n
  expect_equal(n, ICC.Sample.Size::calculateIccSampleSize(p = 0.8, p0 = 0.6, k = 3, tails = 1, power = 0.8)[[1]]$N)
})

test_that("Cronbach's alpha: the required n is statpsych's, and its help example", {
  result <- run_spec(example_spec("reliability_cronbach_alpha"))
  expect_equal(result$provenance$backend, "statpsych")
  expect_true(all(result$check_run$ok))
  # size.test.cronbach(.05, .85, .80, 5, .7) "Should return: 139" (its help).
  expect_equal(result$n_required$n, 139)
  # Power solved from the same formula gives statpsych's n for every
  # combination: the smallest n whose power reaches the target.
  for (a in c(0.75, 0.8, 0.9)) for (r in c(3, 8, 20)) for (pow in c(0.8, 0.9)) {
    spec <- reliability_spec("reliability_cronbach_alpha", list(type = "sample_size", power = pow), reliability = a, items = r)
    expected <- statpsych::size.test.cronbach(0.05, pow, a, r, 0.7)[1, 1]
    expect_equal(run_spec(spec)$n_required$n, unname(expected), label = paste(a, r, pow))
  }
  # One-sided: statpsych's two-sided formula at twice alpha.
  spec <- reliability_spec("reliability_cronbach_alpha", list(type = "sample_size", power = 0.85))
  spec$target_test$alternative <- "greater"
  expect_equal(run_spec(spec)$n_required$n, unname(statpsych::size.test.cronbach(0.1, 0.85, 0.8, 5, 0.7)[1, 1]))
})

test_that("kappa: the required n is kappaSize's, rounded up, and power inverts it", {
  result <- run_spec(example_spec("reliability_kappa"))
  expect_equal(result$provenance$backend, "kappaSize")
  expect_true(all(result$check_run$ok))
  n_package <- kappaSize::PowerBinary(kappa0 = 0.4, kappa1 = 0.6, props = 0.3, alpha = 0.05, power = 0.8)$N
  expect_equal(result$n_required$n, ceiling(n_package))
  # At kappaSize's own n for 90%, the power is 90%.
  n90 <- kappaSize::PowerBinary(0.4, 0.6, 0.3, power = 0.9)$N
  inputs <- reliability_inputs(example_spec("reliability_kappa"))
  # (kappaSize finds its noncentrality to within 1e-5 in probability.)
  expect_equal(kappa_power(inputs, n90), 0.9, tolerance = 1e-4)
  # Three categories and three raters go to Power3Cats().
  spec <- reliability_spec("reliability_kappa", list(type = "sample_size", power = 0.8), proportions = list(0.3, 0.3, 0.4), raters = 3)
  spec$variables$Y <- list(type = "categorical", label = "Diagnosis", levels = list("A", "B", "C"))
  result <- run_spec(spec)
  expect_equal(result$provenance$backend_function, "kappaSize::Power3Cats")
  expect_equal(result$n_required$n, ceiling(kappaSize::Power3Cats(0.4, 0.6, c(0.3, 0.3, 0.4), raters = 3)$N))
})

test_that("the R scripts reproduce the runs", {
  for (name in c("reliability_icc", "reliability_cronbach_alpha", "reliability_kappa")) {
    spec <- example_spec(name)
    out <- run_exported_script(spec, run_spec(spec))
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-6, label = name)
  }
})

test_that("the spec checks refuse what the formulas can't do", {
  ss <- list(type = "sample_size", power = 0.8)
  expect_spec_problem(reliability_spec("reliability_icc", ss, icc = 0.6), "zero in this population")
  expect_spec_problem(reliability_spec("reliability_icc", ss, icc = 0.5), "can't be below it")
  expect_spec_problem(reliability_spec("reliability_kappa", ss, proportions = list(0.6, 0.3)), "add up to 1")
  spec <- reliability_spec("reliability_kappa", ss)
  spec$target_test$alternative <- "greater"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- reliability_spec("reliability_kappa", ss, raters = 7)
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})
