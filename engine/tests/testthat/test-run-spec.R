# run_spec() end to end for the 2x2 designs, with few replications so the
# tests stay fast. Accuracy is checked by the validation tests.

# Run without the "fewer than 1,000 replications" advice, which these
# deliberately small runs would otherwise trigger every time.
run_quietly <- function(spec) {
  withCallingHandlers(
    run_spec(spec),
    powerkit_spec_warning = function(w) invokeRestart("muffleWarning")
  )
}

# An example spec with few replications; fields given in ... replace the
# example's fields whole.
small_run_spec <- function(name, nrep = 100, ...) {
  spec <- example_spec(name)
  spec$options <- list(nrep = nrep, seed = 7)
  changes <- list(...)
  spec[names(changes)] <- changes
  spec
}

test_that("a fixed-n run returns the standard result object", {
  spec <- small_run_spec("anova_2x2_between", goal = list(type = "power", n = 80))
  result <- run_quietly(spec)
  expect_s3_class(result, "powerkit_result")
  expect_named(result, c("goal_type", "curve", "n_required", "sensitivity", "check_run", "provenance"))
  expect_equal(result$goal_type, "power")
  expect_equal(nrow(result$curve), 1)
  expect_equal(result$curve$n, 80)
  expect_equal(result$curve$mcse, sqrt(result$curve$power * (1 - result$curve$power) / 100))
  expect_identical(result$n_required, NA)
  expect_identical(result$sensitivity, NA)
  expect_true(all(result$check_run$ok))
})

test_that("provenance records the spec hash, seed, backend and versions", {
  spec <- small_run_spec("anova_2x2_mixed")
  result <- run_quietly(spec)
  p <- result$provenance
  expect_equal(p$spec_hash, spec_hash(suppressWarnings(validate_spec(spec), classes = "powerkit_spec_warning")))
  expect_equal(p$seed, 7)
  expect_equal(p$nrep, 100)
  expect_equal(p$backend, "Superpower")
  expect_equal(p$simulation_function, "Superpower::ANOVA_power")
  expect_match(p$r_version, "^R version")
  expect_equal(p$packages[["Superpower"]], as.character(utils::packageVersion("Superpower")))
  expect_true(all(c("powerkit", "afex") %in% names(p$packages)))
  expect_gte(p$run_time_seconds, 0)
})

test_that("a seed is drawn and recorded when the spec has none", {
  spec <- small_run_spec("anova_2x2_mixed")
  spec$options$seed <- NULL
  result <- run_quietly(spec)
  expect_true(is.numeric(result$provenance$seed) && result$provenance$seed >= 1)
})

test_that("on one core, powerkit's run equals a direct Superpower call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  means <- matrix(c(10, 10, 10, 13), nrow = 2, byrow = TRUE)
  spec <- small_run_spec(
    "anova_2x2_between", nrep = 200,
    population = list(metric = "raw", means = means, sd = 6),
    goal = list(type = "power", n = 120)
  )
  result <- run_quietly(spec)
  design <- Superpower::ANOVA_design("2b*2b", n = 30, mu = c(10, 10, 10, 13), sd = 6, plot = FALSE)
  direct <- Superpower::ANOVA_power(design, alpha_level = 0.05, nsims = 200, seed = 7, verbose = FALSE)
  expect_equal(result$curve$power, direct$main_results["anova_a:b", "power"] / 100)
})

test_that("runs are reproducible for a given seed", {
  spec <- small_run_spec("anova_2x2_mixed")
  expect_identical(run_quietly(spec)$curve, run_quietly(spec)$curve)
})

test_that("the check run compares every cell, and r for mixed designs", {
  between <- run_quietly(small_run_spec("anova_2x2_between", goal = list(type = "power", n = 40)))
  expect_equal(nrow(between$check_run), 8)
  mixed <- run_quietly(small_run_spec("anova_2x2_mixed", goal = list(type = "power", n = 40)))
  expect_equal(nrow(mixed$check_run), 10)
  expect_true(any(grepl("^r between B1 and B2", mixed$check_run$parameter)))
})

test_that("the check run catches cells put in the wrong place", {
  spec <- validate_spec(example_spec("anova_2x2_between"))
  spec$population$means <- list(list(10, 11), list(12, 13))
  inputs <- superpower_inputs(spec)
  # Means read column by column instead of row by row: A1B2 and A2B1 swap.
  wrong <- Superpower::ANOVA_design(
    "2b*2b", n = 50, mu = as.vector(matrix(inputs$mu, 2, byrow = TRUE)),
    sd = inputs$sd, plot = FALSE
  )
  check <- superpower_check_run(spec, wrong)
  expect_false(all(check$ok))
  expect_setequal(check$parameter[!check$ok], c("mean, A1 B2", "mean, A2 B1"))
})

test_that("a sample-size run returns a curve and an interval for n", {
  spec <- small_run_spec(
    "anova_2x2_between", nrep = 200,
    population = list(metric = "standardised", means = list(list(0, 0), list(0, 1.2)), sd = 1),
    goal = list(type = "sample_size", power = 0.8)
  )
  result <- run_quietly(spec)
  expect_equal(result$goal_type, "sample_size")
  expect_named(result$n_required, c("n", "lower", "upper"))
  expect_true(result$n_required$lower <= result$n_required$n)
  expect_true(result$n_required$n <= result$n_required$upper)
  expect_true(nrow(result$curve) >= 5)
  expect_output(print(result), "Required n:")
})

test_that("designs without a backend yet give a plain-English error", {
  expect_error(
    run_spec(example_spec("process_7")),
    "isn't available yet",
    class = "powerkit_run_error"
  )
})

test_that("sensitivity goals give a plain-English error for now", {
  spec <- small_run_spec("anova_2x2_between", goal = list(type = "sensitivity", n = 80, power = 0.8))
  expect_error(run_quietly(spec), "Sensitivity analysis", class = "powerkit_run_error")
})

test_that("invalid specs are rejected before anything runs", {
  spec <- small_run_spec("anova_2x2_between", goal = list(type = "power", n = 81))
  expect_error(run_quietly(spec), class = "powerkit_spec_error")
})
