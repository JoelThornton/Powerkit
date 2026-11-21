# Reliability and agreement: the ICC by the F test's exact power (or
# ICC.Sample.Size's approximation on request), Cronbach's alpha
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

test_that("the ICC runs on calculateIccPower(), exactly, when the approximation is chosen", {
  spec <- reliability_spec("reliability_icc", list(type = "power", n = 30))
  spec$target_test$method <- "icc_walter"
  result <- run_spec(spec)
  expect_equal(result$provenance$backend, "ICC.Sample.Size")
  expect_equal(result$provenance$method, "exact")
  expect_true(all(result$check_run$ok))
  direct <- ICC.Sample.Size::calculateIccPower(p = 0.8, p0 = 0.6, k = 3, alpha = 0.05, tails = 1, N = 30)[[1]]$power
  expect_equal(result$curve$power, direct, tolerance = 1e-12)
  # The required n is the package's own sample size.
  sized <- example_spec("reliability_icc")
  sized$target_test$method <- "icc_walter"
  expect_equal(run_spec(sized)$n_required$n,
    ICC.Sample.Size::calculateIccSampleSize(p = 0.8, p0 = 0.6, k = 3, tails = 1, power = 0.8)[[1]]$N)
})

test_that("by default the ICC uses the F test's exact power, a person fewer than the approximation (Departure 29)", {
  result <- run_spec(reliability_spec("reliability_icc", list(type = "power", n = 27)))
  expect_equal(result$provenance$backend, "stats")
  expect_match(result$provenance$backend_function, "Donner & Eliasziw", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  # ICC 0.8 against 0.6, 3 raters, one-sided: MSB / MSW is F1 times a
  # central F(26, 54); the test rejects above F0 times its 95th percentile.
  f <- function(rho) (1 + 2 * rho) / (1 - rho)
  expect_equal(result$curve$power, stats::pf(f(0.6) / f(0.8) * stats::qf(0.95, 26, 54), 26, 54, lower.tail = FALSE))
  # The size of the difference: 26 people by the exact power (80.5%), 27
  # by the approximation.
  exact_n <- run_spec(example_spec("reliability_icc"))$n_required$n
  walter <- example_spec("reliability_icc")
  walter$target_test$method <- "icc_walter"
  expect_identical(exact_n, 26)
  expect_identical(run_spec(walter)$n_required$n, 27)
  expect_equal(icc_exact_power(reliability_inputs(example_spec("reliability_icc")), 26), 0.805, tolerance = 0.002)
  # Two-sided: both tails of the same F.
  two <- example_spec("reliability_icc")
  two$target_test$alternative <- "two_sided"
  two$goal <- list(type = "power", n = 40)
  upper <- stats::pf(f(0.6) / f(0.8) * stats::qf(0.975, 39, 80), 39, 80, lower.tail = FALSE)
  lower <- stats::pf(f(0.6) / f(0.8) * stats::qf(0.025, 39, 80), 39, 80)
  expect_equal(run_spec(two)$curve$power, upper + lower)
})

test_that("the ICC's exact power agrees with simulated one-way ANOVAs", {
  inputs <- reliability_inputs(example_spec("reliability_icc"))
  set.seed(29)
  n <- 26
  k <- 3
  f0 <- (1 + 2 * 0.6) / 0.4
  hits <- replicate(4000, {
    x <- matrix(stats::rnorm(n, sd = sqrt(0.8)), n, k) + matrix(stats::rnorm(n * k, sd = sqrt(0.2)), n, k)
    m <- rowMeans(x)
    msb <- k * sum((m - mean(x))^2) / (n - 1)
    msw <- sum((x - m)^2) / (n * (k - 1))
    msb / msw > f0 * stats::qf(0.95, n - 1, n * (k - 1))
  })
  expect_lt(abs(mean(hits) - icc_exact_power(inputs, n)), 3 * sqrt(0.8 * 0.2 / 4000))
})

test_that("the ICC's exported script reproduces the exact power with base R alone", {
  skip_unless_scripts_can_run()
  spec <- reliability_spec("reliability_icc", list(type = "power", n = 30))
  result <- run_for_export(spec)
  expect_no_match(paste(export_script(spec, result), collapse = "\n"), "library(", fixed = TRUE)
  expect_script_reproduces_power(spec, result)
  expect_match(export_citations(result), "Donner", fixed = TRUE)
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

test_that("Departure 34: a two-sided test of alpha counts both tails, by this much", {
  # At the null value the formula's one tail gives alpha / 2; both tails
  # give alpha, the two-sided test's level.
  spec <- reliability_spec("reliability_cronbach_alpha", list(type = "power", n = 100), reliability = 0.7)
  expect_equal(run_spec(spec)$curve$power, 0.05, tolerance = 1e-12)
  inputs <- reliability_inputs(spec)
  inputs$one_sided <- TRUE
  inputs$alpha <- 0.025
  expect_equal(cronbach_power(inputs, 100), 0.025, tolerance = 1e-12)
  # With an effect worth planning for, the other tail adds almost nothing:
  # alpha 0.8 against 0.7 over 5 items at n = 139 (statpsych's n for 85%).
  spec <- reliability_spec("reliability_cronbach_alpha", list(type = "power", n = 139))
  inputs <- reliability_inputs(spec)
  d <- sqrt(137 * 4 / 10) * abs(log(0.2 / 0.3))
  expect_equal(run_spec(spec)$curve$power - stats::pnorm(d - stats::qnorm(0.975)), stats::pnorm(-d - stats::qnorm(0.975)))
  expect_lt(stats::pnorm(-d - stats::qnorm(0.975)), 1e-6)
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

test_that("the kappa check run simulates raters from kappaSize's own models (queue item 30)", {
  # kappaSize's cell probabilities (its source, version 1.2): for two
  # categories, PowerBinary()'s P0 to P3 for 3 raters; for three, Power3Cats()'s
  # P1, the chance that all 3 raters give category 1. A model with only the
  # same pairwise kappa (the check run's before 21 November 2026) gave a
  # different chance that all agree, so the check tested less than it seemed.
  n <- 200000
  set.seed(30)
  p <- 0.2
  k <- 0.3
  binary <- reliability_kappa_ratings(n, 3, c(1 - p, p), k)
  positives <- rowSums(binary == 2)
  expected <- c((1 - p)^3 + p * k * ((1 - p)^2 + (1 - p)), 3 * p * (1 - k) * (1 - p)^2,
    3 * p^2 * (1 - p) * (1 - k), p^3 + k * p * (1 - p^2))
  observed <- tabulate(positives + 1, 4) / n
  expect_true(all(abs(observed - expected) < 4 * sqrt(expected * (1 - expected) / n)), label = "two categories, 3 raters")
  props <- c(p, 0.4, 0.4)
  three <- reliability_kappa_ratings(n, 3, props, k)
  all_first <- mean(rowSums(three == 1) == 3)
  expected <- p^3 * ((p^2 + 3 * k * p - 2 * k * p^2 + 2 * k^2 - 3 * k^2 * p + k^2 * p^2) / p^2) / (1 + k)
  expect_lt(abs(all_first - expected), 4 * sqrt(expected * (1 - expected) / n))
  # Any two raters' agreement beyond chance is kappa in both.
  pair_kappa <- function(r) {
    po <- mean(r[, 1] == r[, 2])
    pe <- sum((tabulate(r[, 1], max(r)) / n)^2)
    (po - pe) / (1 - pe)
  }
  expect_equal(pair_kappa(binary), k, tolerance = 0.02)
  expect_equal(pair_kappa(three), k, tolerance = 0.02)
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
