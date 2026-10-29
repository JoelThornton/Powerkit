# The test's details (df, critical value, noncentrality) are read from the
# backend package's output; each set must reproduce the power reported.

spec_at <- function(file, goal) {
  spec <- read_spec(system.file("specs", file, package = "powerkit"))
  spec$options$method <- NULL
  spec$goal <- goal
  spec
}

test_that("a paired t-test's details are pwrss's for the same test and give pwr's power", {
  result <- run_spec(spec_at("paired_t.json", list(type = "power", n = 40)))
  d <- result$details
  expect_identical(d$statistic, "t")
  expect_identical(d$source, "pwrss::power.t.student")
  expect_equal(d$df, 39)
  expect_equal(d$critical, stats::qt(c(0.025, 0.975), 39))
  power <- stats::pt(d$critical[2], d$df, d$ncp, lower.tail = FALSE) + stats::pt(d$critical[1], d$df, d$ncp)
  expect_equal(power, result$curve$power, tolerance = 1e-8)
})

test_that("an F test's details reproduce the power (pwrss and Superpower)", {
  for (file in c("regression_r2_increase.json", "anova_oneway_between.json", "anova_2x2_mixed.json")) {
    result <- suppressWarnings(run_spec(spec_at(file, list(type = "power", n = 120))))
    d <- result$details
    expect_identical(d$statistic, "F", label = file)
    expect_length(d$df, 2)
    power <- stats::pf(d$critical, d$df[1], d$df[2], d$ncp, lower.tail = FALSE)
    expect_equal(power, result$curve$power, tolerance = 1e-4, label = file)
  }
})

test_that("an exact test of one proportion gives its critical counts and actual alpha", {
  result <- run_spec(spec_at("one_proportion.json", list(type = "power", n = 100)))
  d <- result$details
  expect_identical(d$statistic, "count")
  expect_length(d$critical, 2)
  expect_lte(d$actual_alpha, 0.05)
})

test_that("details are left out where no package reports them", {
  # pwr's correlation test has no identical pwrss version.
  expect_null(run_spec(spec_at("correlation.json", list(type = "power", n = 80)))$details)
  # A sensitivity analysis: the effect is the answer.
  expect_null(run_spec(spec_at("paired_t.json", list(type = "sensitivity", n = 40, power = 0.8)))$details)
  # A simulated result.
  spec <- spec_at("paired_t.json", list(type = "power", n = 40))
  spec$options$method <- "simulation"
  spec$options$nrep <- 200
  expect_null(suppressWarnings(run_spec(spec))$details)
})

test_that("a simulated sample size reports the power reached there, with its interval", {
  spec <- spec_at("paired_t.json", list(type = "sample_size", power = 0.8))
  spec$options$method <- "simulation"
  spec$options$nrep <- 500
  spec$options$seed <- 11
  est <- suppressWarnings(run_spec(spec))$n_required
  expect_gte(est$power, 0.8)
  expect_lt(est$power_lower, est$power)
  expect_gt(est$power_upper, est$power)
  # The exact power at that n lies inside the interval.
  exact <- pwr::pwr.t.test(n = est$n, d = spec$population$dz, type = "paired")$power
  expect_gt(exact, est$power_lower)
  expect_lt(exact, est$power_upper)
})
