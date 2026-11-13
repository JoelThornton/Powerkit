# Welch's one-way ANOVA by Levy's noncentral F approximation
# (backend-welch-anova.R), as Jan and Shieh (2014) recommend and program it
# (their Appendices C and D). Checked against the paper's published sample
# sizes and powers, against Spower's simulation of the same test, and by the
# exported script. The simulation on request is tested in
# test-backend-welch-anova.R.

levy_spec <- function(goal = list(type = "power", n = 90), sds = NULL, means = c(10, 11, 13), ...) {
  spec <- example_spec("anova_oneway_between")
  spec$target_test$method <- "welch_f"
  spec$population$means <- means
  if (!is.null(sds)) {
    spec$population$sd <- NULL
    spec$population$sds <- sds
  }
  spec$goal <- goal
  spec$options <- list(seed = 7, ...)
  spec
}

# Jan and Shieh's (2014) model: means and variances given directly.
js_inputs <- function(mu, variances) {
  list(alpha = 0.05, groups = length(mu), means = mu, sds = sqrt(variances))
}

test_that("Welch's F is computed by Levy's approximation by default, and simulated on request", {
  result <- run_spec(levy_spec())
  expect_identical(result$provenance$backend, "stats")
  expect_identical(result$provenance$method, "exact")
  expect_match(result$provenance$backend_function, "Levy", fixed = TRUE)
  expect_identical(route_spec(levy_spec(method = "simulation"))$name, "Spower")
  # 90 people, 30 per group, SD 6: omega = 30 / 36 in every group, so the
  # weighted mean is the plain one and Lambda = (30 / 36) x sum of squared
  # deviations; tau = 3 x (2 / 3)^2 / 29, nu = 8 / (3 tau).
  lambda <- 30 / 36 * sum((c(10, 11, 13) - mean(c(10, 11, 13)))^2)
  nu <- 8 / (3 * 3 * (2 / 3)^2 / 29)
  expect_equal(result$details$df, c(2, nu))
  expect_equal(result$details$ncp, lambda)
  expect_equal(result$curve$power, stats::pf(stats::qf(0.95, 2, nu), 2, nu, ncp = lambda, lower.tail = FALSE))
})

test_that("the approximation gives Jan and Shieh's (2014) published powers (Tables 1 and 2, Levy columns)", {
  # Minimum-variability means; equal and unequal variances and group sizes.
  cases <- list(
    list(mu = c(-1, 0, 0, 1), v = c(1, 1, 1, 1), n = c(7, 7, 7, 7), power = 0.7796),
    list(mu = c(-1, 0, 0, 1), v = c(1, 4, 9, 16), n = c(10, 20, 30, 40), power = 0.7129),
    list(mu = c(-1, 0, 0, 0, 0, 1), v = rep(1, 6), n = rep(8, 6), power = 0.7752),
    list(mu = c(-1, 0, 0, 0, 0, 1), v = c(1, 1, 4, 4, 9, 9), n = c(10, 10, 20, 20, 30, 30), power = 0.7152),
    list(mu = c(-1, 0, 0, 1), v = c(1, 1, 1, 1), n = c(8, 8, 8, 8), power = 0.8529),
    list(mu = c(-1, 0, 0, 1), v = c(1, 4, 9, 16), n = c(12, 24, 36, 48), power = 0.8035),
    list(mu = c(-1, 0, 0, 0, 0, 1), v = rep(1, 6), n = rep(9, 6), power = 0.8426),
    list(mu = c(-1, 0, 0, 0, 0, 1), v = c(1, 1, 4, 4, 9, 9), n = c(12, 12, 24, 24, 36, 36), power = 0.8127)
  )
  for (case in cases) {
    inputs <- js_inputs(case$mu, case$v)
    expect_equal(welch_levy_power(inputs, sum(case$n), sizes = case$n), case$power, tolerance = 5e-5 / case$power)
  }
  # Their equal-size cases are the sample sizes powerkit finds too: 7 per
  # group for power .70 and 8 for .80 (four groups); 8 and 9 for six groups.
  for (case in list(list(g = 4, power = 0.7, n = 28), list(g = 4, power = 0.8, n = 32),
                    list(g = 6, power = 0.7, n = 48), list(g = 6, power = 0.8, n = 54))) {
    mu <- c(-1, rep(0, case$g - 2), 1)
    spec <- example_spec("anova_oneway_between")
    spec$variables$A$levels <- paste("Group", seq_len(case$g))
    spec$population <- list(metric = "raw", means = mu, sd = 1)
    spec$target_test$method <- "welch_f"
    spec$goal <- list(type = "sample_size", power = case$power)
    expect_identical(run_spec(spec)$n_required$n, case$n)
  }
})

test_that("the sample size is the smallest n reaching the target power, and the smallest effect solves back", {
  spec <- levy_spec(goal = list(type = "sample_size", power = 0.8), sds = c(4, 6, 9))
  result <- run_spec(spec)
  inputs <- welch_levy_inputs(spec)
  n <- result$n_required$n
  expect_identical(n %% 3, 0)
  expect_gte(welch_levy_power(inputs, n), 0.8)
  expect_lt(welch_levy_power(inputs, n - 3), 0.8)
  found <- run_spec(levy_spec(goal = list(type = "sensitivity", n = n, power = 0.8), sds = c(4, 6, 9)))$sensitivity
  expect_equal(welch_levy_power(inputs, n, found$means), 0.8, tolerance = 1e-6)
  expect_lte(found$effect, 3)
  expect_false(isTRUE(found$simulated))
})

test_that("the formula agrees with Spower's simulation of Welch's F, with equal and unequal SDs", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  nrep <- 4000
  cases <- list(
    list(sds = NULL, n = 150),
    list(sds = c(3, 6, 12), n = 120),
    list(sds = c(12, 6, 3), n = 240)
  )
  for (case in cases) {
    formula <- run_spec(levy_spec(goal = list(type = "power", n = case$n), sds = case$sds))$curve$power
    simulated <- run_quietly(levy_spec(goal = list(type = "power", n = case$n), sds = case$sds,
      method = "simulation", nrep = nrep))$curve$power
    # Monte Carlo error plus Jan and Shieh's largest approximation error (.01).
    expect_lt(abs(simulated - formula), 3 * sqrt(formula * (1 - formula) / nrep) + 0.01)
  }
})

test_that("the exported script reproduces the formula with base R alone", {
  skip_unless_scripts_can_run()
  spec <- levy_spec(sds = c(4, 6, 9))
  result <- run_for_export(spec)
  expect_no_match(export_script(spec, result), "library(", fixed = TRUE)
  expect_script_reproduces_power(spec, result)
  sample_size <- levy_spec(goal = list(type = "sample_size", power = 0.8), sds = c(4, 6, 9))
  sized <- run_for_export(sample_size)
  run <- run_exported_script(sample_size, sized)
  expect_equal(run$reproduced, run$powerkit, tolerance = 1e-10)
  expect_equal(run$powerkit$n, sized$n_required$n)
})

test_that("a Welch's F result cites Jan and Shieh (2014) as its formula", {
  text <- export_citations(run_spec(levy_spec()))
  expect_match(text, "The published formula powerkit computed power from", fixed = TRUE)
  expect_match(text, "Jan", fixed = TRUE)
  expect_no_match(text, "stats_method", fixed = TRUE)
})
