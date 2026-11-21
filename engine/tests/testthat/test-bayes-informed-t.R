# Bayes factor t-tests with an informed analysis prior: the exact
# calculation around bfpwr::tbf01() (bayes-informed-t.R). Agreement with
# simulated studies at many settings is in test-validation-bayes-informed.R.

informed_spec <- function(template = "one_sample_t", n = 40, location = 0.3, scale = 0.15, df = 1, ...) {
  spec <- example_spec(template)
  spec$target_test$method <- "bayes_factor"
  spec$target_test$alpha <- NULL
  spec$target_test$prior_location <- location
  spec$target_test$prior_scale <- scale
  spec$target_test$prior_df <- df
  spec$population$score_shape <- NULL
  spec$options <- list(seed = 7)
  spec$goal <- list(type = "power", n = n)
  changes <- list(...)
  for (path in names(changes)) {
    parts <- strsplit(path, ".", fixed = TRUE)[[1]]
    spec[[parts]] <- changes[[path]]
  }
  spec
}

informed_inputs <- function(type = "one.sample", location = 0.3, scale = 0.15, df = 1, alternative = "two.sided",
                            effect = 0.4, effect_sd = 0.1, threshold = 10) {
  list(
    type = type, alternative = alternative, threshold = threshold, prior_location = location,
    prior_scale = scale, prior_df = df, effect = effect, effect_sd = effect_sd,
    size = if (identical(type, "two.sample")) function(n) n / 2 else function(n) n
  )
}

# The chance from simulated t statistics, each given bfpwr's Bayes factor.
simulated_chance <- function(inputs, n, reps, seed, for_effect = TRUE, dpm = inputs$effect, dpsd = inputs$effect_sd) {
  m <- inputs$size(n)
  with_seed(seed, {
    d <- stats::rnorm(reps, dpm, dpsd)
    t <- stats::rt(reps, bft_df(inputs$type, m), ncp = d * bft_ncp_factor(inputs$type, m))
  })
  log_bf <- bft_log_bf01(t, m, inputs)
  if (for_effect) mean(log_bf <= log(1 / inputs$threshold)) else mean(log_bf >= log(inputs$threshold))
}

test_that("the default JZS prior still uses bfpwr's own power function", {
  expect_false(bft_informed(list(prior_location = 0, prior_df = 1)))
  expect_false(bft_informed(list()))
  expect_true(bft_informed(list(prior_location = 0.3, prior_df = 1)))
  expect_true(bft_informed(list(prior_location = 0, prior_df = 5)))
  plain <- run_quietly(informed_spec(location = 0, scale = 1 / sqrt(2), df = 1))
  expect_identical(plain$provenance$backend_function, "bfpwr::powertbf01")
})

test_that("BF01 has one peak in t over the range any threshold uses", {
  # tbf01()'s numerical integration wobbles only where log BF01 is below
  # about -10, far past any evidence threshold.
  for (inputs in list(informed_inputs(), informed_inputs("two.sample", 0.5, 0.2, 3), informed_inputs("paired", -0.4, 0.3, 1))) {
    t <- seq(-15, 15, by = 0.01)
    v <- bft_log_bf01(t, 20, inputs)
    keep <- v > -8
    steps <- sign(diff(v[keep]))
    expect_lte(sum(diff(steps[steps != 0]) != 0), 1)
  }
})

test_that("the chance matches simulated studies where bfpwr's powertbf01() does not", {
  # bfpwr question 2 (docs/upstream-questions.md): one sample, prior
  # t(location 0.3, scale 0.15, df 1), design prior N(0.4, 0.1), BF10 >= 10.
  inputs <- informed_inputs()
  for (n in c(5, 10, 30)) {
    exact <- bft_chance_exact(inputs, n)
    sim <- simulated_chance(inputs, n, reps = 4000, seed = 200 + n)
    expect_lt(abs(exact - sim), 4 * sqrt(max(sim * (1 - sim), 0.001) / 4000) + 0.002, label = paste("n =", n))
  }
  # The size of the difference from powertbf01() at n = 10: about 5% against 0.
  bfpwr_value <- bfpwr::powertbf01(n = 10, k = 1 / 10, plocation = 0.3, pscale = 0.15, pdf = 1,
    type = "one.sample", dpm = 0.4, dpsd = 0.1)$power
  expect_lt(bfpwr_value, 0.001)
  expect_gt(bft_chance_exact(inputs, 10), 0.04)
})

test_that("the no-effect side and a one-sided test are worked out the same way", {
  inputs <- informed_inputs("paired", 0.3, 0.2, alternative = "greater", effect_sd = 0)
  expect_lt(abs(bft_chance_exact(inputs, 20, FALSE, 0, 0) - simulated_chance(inputs, 20, 4000, 31, FALSE, 0, 0)), 0.015)
  expect_lt(abs(bft_chance_exact(inputs, 20, TRUE, 0, 0) - simulated_chance(inputs, 20, 4000, 32, TRUE, 0, 0)), 0.01)
})

test_that("a run with an informed prior is exact, recovers its settings, and finds the smallest n", {
  result <- run_quietly(informed_spec("independent_t", n = 80, location = 0.5, scale = 0.2, df = 3))
  expect_identical(result$provenance$backend, "bfpwr")
  expect_identical(result$provenance$backend_function, "bfpwr::tbf01")
  expect_true(all(result$check_run$ok))
  inputs <- bfpwr_inputs(validate_quietly(informed_spec("independent_t", location = 0.5, scale = 0.2, df = 3)))
  expect_equal(result$curve$power, bft_chance_exact(inputs, 80))
  spec <- informed_spec()
  spec$goal <- list(type = "sample_size", power = 0.8)
  found <- run_quietly(spec)
  n <- found$n_required$n
  inputs <- bfpwr_inputs(validate_quietly(spec))
  expect_gte(bft_chance_exact(inputs, n), 0.8)
  expect_lt(bft_chance_exact(inputs, n - 1), 0.8)
})

test_that("an informed prior belongs to the Bayes factor t-tests only", {
  spec <- example_spec("one_sample_t")
  spec$target_test$prior_location <- 0.3
  expect_error(validate_quietly(spec))
  spec <- example_spec("correlation")
  spec$target_test$method <- "bayes_factor"
  spec$target_test$alpha <- NULL
  spec$target_test$prior_location <- 0.3
  expect_spec_problem(spec, "informed prior for the Bayes factor t-tests only")
})

test_that("the R script reproduces a run with an informed prior", {
  skip_unless_scripts_can_run()
  spec <- informed_spec("paired_t", n = 30, location = -0.3, scale = 0.2, df = 1)
  spec$population$dz <- -0.4
  run <- expect_script_reproduces_power(spec, run_quietly(spec))
  expect_true(any(grepl("tbf01(", run$script, fixed = TRUE)))
})

test_that("'Does the prior matter?' compares an informed prior with the default prior's widths", {
  rob <- bayes_robustness(informed_spec("one_sample_t", n = 40, location = 0.3, scale = 0.15, df = 1), 40)
  expect_identical(rob$prior, c("Your prior", "Medium (the usual default)", "Wide", "Ultrawide"))
  inputs <- bfpwr_inputs(validate_quietly(informed_spec()))
  expect_equal(rob$for_effect[1], bft_chance_exact(inputs, 40))
  default <- run_quietly(informed_spec(n = 40, location = 0, scale = 1 / sqrt(2), df = 1))
  expect_equal(rob$for_effect[2], default$curve$power)
})
