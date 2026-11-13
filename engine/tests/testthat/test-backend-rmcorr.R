# The repeated-measures (within-person) correlation (backend-rmcorr.R):
# pwrss's exact distribution of r at the effective sample size N(k - 1) + 1.

rmcorr_spec <- function(r = 0.2, measurements = 3, goal = list(type = "sample_size", power = 0.8),
                        alternative = "two_sided") {
  spec <- read_spec(system.file("specs", "repeated_measures_correlation.json", package = "powerkit"))
  spec$population$r <- r
  spec$population$measurements <- measurements
  spec$goal <- goal
  spec$target_test$alternative <- alternative
  validate_spec(spec)
}

test_that("power is a Pearson correlation's at the effective sample size N(k - 1) + 1", {
  result <- run_spec(rmcorr_spec(goal = list(type = "power", n = 100L)))
  direct <- pwrss::power.exact.onecor(rho = 0.2, null.rho = 0, n = 100 * 2 + 1, alpha = 0.05,
    alternative = "two.sided", verbose = 0)$power
  expect_equal(result$curve$power, direct, tolerance = 1e-12)
  expect_identical(result$provenance$backend, "pwrss")
  # rmcorr's documentation gives 0.8157 for this example by Fisher's z; the
  # exact distribution differs only in the fourth decimal place.
  expect_equal(result$curve$power, 0.8157, tolerance = 0.002)
  expect_identical(result$details$df, 199)
})

test_that("more measurements per person need fewer people", {
  n3 <- run_spec(rmcorr_spec(measurements = 3))$n_required$n
  n6 <- run_spec(rmcorr_spec(measurements = 6))$n_required$n
  expect_identical(n3, 96)
  expect_lt(n6, n3)
  # The required N is the smallest whose effective n reaches 80%.
  inputs <- rmcorr_inputs(rmcorr_spec())
  expect_gte(rmcorr_power(inputs, n3), 0.8)
  expect_lt(rmcorr_power(inputs, n3 - 1), 0.8)
})

test_that("the smallest detectable correlation is found, in the direction asked", {
  s <- run_spec(rmcorr_spec(goal = list(type = "sensitivity", n = 100L, power = 0.8)))$sensitivity
  expect_equal(s$power, 0.8, tolerance = 1e-6)
  expect_gt(s$effect, 0.19)
  expect_lt(s$effect, 0.2)
  neg <- run_spec(rmcorr_spec(r = -0.2, goal = list(type = "sensitivity", n = 100L, power = 0.8), alternative = "less"))$sensitivity
  expect_lt(neg$effect, 0)
})

test_that("the check run recovers the correlation from simulated people", {
  check <- run_spec(rmcorr_spec())$check_run
  expect_true(all(check$ok))
  data <- rmcorr_simulated_data(3000, 4, 0.3)
  # The within-person estimate equals the t test of X in lm(Y ~ person + X)
  # turned into a partial correlation.
  fit <- summary(stats::lm(y ~ participant + x, data = data))$coefficients["x", ]
  df <- nrow(data) - 3000 - 1
  partial <- fit[["t value"]] / sqrt(fit[["t value"]]^2 + df)
  expect_equal(rmcorr_estimate(data), partial, tolerance = 1e-10)
})

test_that("plain refusals: one measurement, or a one-sided test against the effect", {
  spec <- rmcorr_spec()
  spec$population$measurements <- 1
  expect_error(validate_spec(spec), "measurements")
  expect_error(rmcorr_spec(r = 0.2, alternative = "less"), "other way")
})

test_that("the R script reproduces each goal with pwrss alone", {
  for (goal in list(list(type = "power", n = 100L), list(type = "sample_size", power = 0.8),
                    list(type = "sensitivity", n = 100L, power = 0.8))) {
    spec <- rmcorr_spec(goal = goal)
    result <- run_spec(spec)
    text <- export_script(spec, result)
    out <- suppressMessages(utils::capture.output(eval(parse(text = text), envir = new.env())))
    expect_true(any(grepl("Reproduced powerkit's result.", out, fixed = TRUE)), info = goal$type)
  }
})

test_that("the citations name Bakdash and Marusich's method", {
  result <- run_spec(rmcorr_spec())
  expect_match(export_citations(result), "Repeated Measures Correlation", fixed = TRUE)
})
