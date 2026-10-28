# run_spec() end to end for the 2x2 designs (the other designs' backends are
# tested in test-backend-*.R). Simulation runs use few
# replications so the tests stay fast; accuracy is checked by the
# validation tests.

exact_power_direct <- function(design, n, mu, sd, r = 0, effect = "a:b") {
  d <- Superpower::ANOVA_design(design, n = n, mu = mu, sd = sd, r = r, plot = FALSE)
  e <- Superpower::ANOVA_exact(d, alpha_level = 0.05, verbose = FALSE)$main_results
  list(power = e[effect, "power"] / 100, cohen_f = e[effect, "cohen_f"])
}

# Exact (the default for 2x2 designs) ------------------------------------------

test_that("a fixed-n run returns the standard result object", {
  result <- run_spec(small_run_spec("anova_2x2_between", goal = list(type = "power", n = 80)))
  expect_s3_class(result, "powerkit_result")
  expect_named(result, c("goal_type", "curve", "n_required", "sensitivity", "effect_from_units", "safeguard", "recruitment", "clusters", "sem", "check_run", "provenance"))
  expect_identical(result$recruitment, NA) # no attrition given
  expect_equal(result$goal_type, "power")
  expect_equal(result$curve, data.frame(n = 80, power = result$curve$power, mcse = 0))
  expect_identical(result$n_required, NA)
  expect_identical(result$sensitivity, NA)
  expect_true(all(result$check_run$ok))
})

test_that("exact is the default for 2x2 designs and equals a direct ANOVA_exact call", {
  result <- run_spec(small_run_spec("anova_2x2_mixed"))
  expect_equal(result$provenance$method, "exact")
  expect_equal(result$provenance$backend_function, "Superpower::ANOVA_exact")
  direct <- exact_power_direct("2b*2w", n = 60, mu = c(0, 0, 0, -0.4), sd = 1, r = 0.6)
  expect_equal(result$curve$power, direct$power)
})

test_that("provenance records the spec hash, method, seed, backend and versions", {
  spec <- small_run_spec("anova_2x2_mixed")
  p <- run_spec(spec)$provenance
  expect_equal(p$spec_hash, spec_hash(validate_spec(spec)))
  expect_equal(p$seed, 7)
  expect_identical(p$nrep, NA_integer_)
  expect_equal(p$backend, "Superpower")
  expect_match(p$r_version, "^R version")
  expect_equal(p$packages[["Superpower"]], as.character(utils::packageVersion("Superpower")))
  expect_true(all(c("powerkit", "afex") %in% names(p$packages)))
  expect_gte(p$run_time_seconds, 0)
})

test_that("an exact sample-size run gives the smallest n reaching the target", {
  spec <- small_run_spec(
    "anova_2x2_between",
    population = list(metric = "standardised", means = list(list(-0.175, 0.175), list(0.175, -0.175)), sd = 1),
    goal = list(type = "sample_size", power = 0.8)
  )
  result <- run_spec(spec)
  n <- result$n_required$n
  expect_equal(result$n_required, list(n = n, lower = n, upper = n))
  mu <- c(-0.175, 0.175, 0.175, -0.175)
  expect_gte(exact_power_direct("2b*2b", n / 4, mu, 1)$power, 0.8)
  expect_lt(exact_power_direct("2b*2b", n / 4 - 1, mu, 1)$power, 0.8)
  expect_true(all(result$curve$mcse == 0))
  expect_true(n %in% result$curve$n)
  expect_output(print(result), sprintf("Required n: %s (exact)", n), fixed = TRUE)
})

test_that("exact power below its minimum n asks for simulation", {
  spec <- small_run_spec("anova_2x2_between", goal = list(type = "power", n = 16))
  expect_error(run_spec(spec), "set 'options > method' to 'simulation'", class = "powerkit_run_error")
  spec <- small_run_spec("anova_2x2_between", method = "simulation", goal = list(type = "power", n = 16))
  expect_s3_class(run_quietly(spec), "powerkit_result")
})

# Sensitivity ------------------------------------------------------------------

test_that("sensitivity scales the pattern of cell means to reach the target power", {
  spec <- small_run_spec("anova_2x2_between", goal = list(type = "sensitivity", n = 200, power = 0.9))
  result <- run_spec(spec)
  s <- result$sensitivity
  specified <- matrix(c(10, 10, 10, 13), nrow = 2, byrow = TRUE)
  grand_mean <- mean(specified)
  # Same grand mean, same shape, scaled deviations.
  expect_equal(mean(s$means), grand_mean)
  expect_equal(s$means - grand_mean, s$scale * (specified - grand_mean))
  expect_equal(s$power, 0.9, tolerance = 1e-6)
  expect_equal(result$curve$power, s$power)
  # The effect in the user's units, and Superpower's Cohen's f at that size.
  expect_equal(s$effect, (s$means[1, 1] - s$means[1, 2]) - (s$means[2, 1] - s$means[2, 2]))
  direct <- exact_power_direct("2b*2b", 50, as.vector(t(s$means)), 6)
  expect_equal(s$cohen_f, direct$cohen_f)
  expect_equal(direct$power, 0.9, tolerance = 1e-6)
  expect_match(s$effect_description, "Task difficulty effect (Easy minus Hard) between None and Praise", fixed = TRUE)
  expect_output(print(result), "Smallest detectable effect:")
})

test_that("sensitivity reports main effects as marginal mean differences", {
  spec <- small_run_spec(
    "anova_2x2_mixed",
    target_test = list(effect = "main_effect_A", method = "anova_f", alpha = 0.05),
    goal = list(type = "sensitivity", n = 100, power = 0.8)
  )
  s <- run_spec(spec)$sensitivity
  expect_equal(s$effect, mean(s$means[1, ]) - mean(s$means[2, ]))
  expect_equal(s$power, 0.8, tolerance = 1e-6)
})

test_that("sensitivity needs the exact method", {
  spec <- small_run_spec(
    "anova_2x2_between", method = "simulation",
    goal = list(type = "sensitivity", n = 200, power = 0.9)
  )
  expect_error(run_quietly(spec), "Sensitivity analysis uses the exact method", class = "powerkit_run_error")
})

test_that("sensitivity needs a non-zero target effect to scale", {
  spec <- small_run_spec(
    "anova_2x2_between",
    population = list(metric = "raw", means = list(list(10, 12), list(11, 13)), sd = 6),
    goal = list(type = "sensitivity", n = 200, power = 0.9)
  )
  expect_spec_problem(spec, "there is no effect pattern to scale")
})

# Simulation (on request) ---------------------------------------------------------

test_that("simulation is used on request, with Monte Carlo errors", {
  result <- run_quietly(small_run_spec("anova_2x2_mixed", method = "simulation"))
  p <- result$provenance
  expect_equal(p$method, "simulation")
  expect_equal(p$backend_function, "Superpower::ANOVA_power")
  expect_equal(p$nrep, 100)
  expect_identical(p$batch_size, NA_integer_)
  expect_equal(result$curve$mcse, sqrt(result$curve$power * (1 - result$curve$power) / 100))
})

test_that("provenance records the batch size and cores of a batched backend", {
  # A backend that simulates in batches (as power4mome does): the seed and
  # batch size determine the result, so the batch size is recorded; the
  # cores (which only change the speed) are recorded too. Skipped on CRAN,
  # which allows at most 2 cores.
  skip_on_cran()
  old <- options(powerkit.cores = 3)
  on.exit(options(old))
  local_mocked_bindings(route_spec = function(spec, seed) {
    list(
      name = "mock", packages = character(), methods = "simulation",
      default_method = "simulation", functions = c(simulation = "mock"),
      batch_size = 30L,
      simulate = function(n, nrep, seed, cores) {
        simulate_in_chunks(nrep, seed, cores, function(k, s) k %/% 2, batch_size = 30L)
      },
      check_run = function() data.frame(parameter = "x", specified = 0, recovered = 0, ok = TRUE)
    )
  })
  result <- run_quietly(small_run_spec("anova_2x2_mixed", method = "simulation"))
  expect_equal(result$provenance$batch_size, 30L)
  expect_equal(result$provenance$cores, 3L)
  # 100 replications in 4 batches of 25: 12 rejections each.
  expect_equal(result$curve$power, 48 / 100)
})

test_that("on one core, a simulation run equals a direct ANOVA_power call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  means <- matrix(c(10, 10, 10, 13), nrow = 2, byrow = TRUE)
  spec <- small_run_spec(
    "anova_2x2_between", method = "simulation", nrep = 100,
    population = list(metric = "raw", means = means, sd = 6),
    goal = list(type = "power", n = 120)
  )
  result <- run_quietly(spec)
  design <- Superpower::ANOVA_design("2b*2b", n = 30, mu = c(10, 10, 10, 13), sd = 6, plot = FALSE)
  direct <- Superpower::ANOVA_power(design, alpha_level = 0.05, nsims = 100, seed = 7, verbose = FALSE)
  expect_equal(result$curve$power, direct$main_results["anova_a:b", "power"] / 100)
})

test_that("simulation runs are reproducible, and draw a seed when none is given", {
  spec <- small_run_spec("anova_2x2_mixed", method = "simulation")
  expect_identical(run_quietly(spec)$curve, run_quietly(spec)$curve)
  spec$options$seed <- NULL
  seed <- run_quietly(spec)$provenance$seed
  expect_true(is.numeric(seed) && seed >= 1)
})

test_that("a simulation sample-size run returns a curve and an interval for n", {
  spec <- small_run_spec(
    "anova_2x2_between", method = "simulation", nrep = 100,
    population = list(metric = "standardised", means = list(list(0, 0), list(0, 1.2)), sd = 1),
    goal = list(type = "sample_size", power = 0.8)
  )
  result <- run_quietly(spec)
  expect_named(result$n_required, c("n", "lower", "upper"))
  expect_true(result$n_required$lower <= result$n_required$n)
  expect_true(result$n_required$n <= result$n_required$upper)
  expect_true(nrow(result$curve) >= 5)
  expect_output(print(result), "95% interval")
})

# Check run ------------------------------------------------------------------------

test_that("the check run compares every cell, and r for mixed designs", {
  between <- run_spec(small_run_spec("anova_2x2_between", goal = list(type = "power", n = 40)))
  expect_equal(nrow(between$check_run), 8)
  mixed <- run_spec(small_run_spec("anova_2x2_mixed", goal = list(type = "power", n = 40)))
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

# Errors ----------------------------------------------------------------------------

test_that("features without a backend yet give a plain-English error", {
  spec <- sim_spec("correlation", goal = list(type = "sensitivity", n = 100, power = 0.8))
  expect_error(run_quietly(spec), "isn't available yet", class = "powerkit_not_available")
  # The example PROCESS model 7 spec has a binary X and an unreliable W.
  expect_error(run_spec(example_spec("process_7")), "aren't available yet", class = "powerkit_not_available")
})

test_that("the exact method is refused for designs that don't support it", {
  spec <- example_spec("process_7")
  spec$options$method <- "exact"
  expect_spec_problem(spec, "'options > method' 'exact' is only available for 2x2 ANOVA designs")
})

test_that("invalid specs are rejected before anything runs", {
  spec <- small_run_spec("anova_2x2_between", goal = list(type = "power", n = 81))
  expect_error(run_spec(spec), class = "powerkit_spec_error")
})

test_that("exact results are reproducible bit for bit and leave the RNG alone", {
  spec <- small_run_spec("anova_2x2_between", goal = list(type = "power", n = 160))
  set.seed(99)
  before <- .Random.seed
  first <- run_spec(spec)$curve$power
  expect_identical(.Random.seed, before)
  expect_identical(run_spec(spec)$curve$power, first)
  design <- Superpower::ANOVA_design("2b*2b", n = 40, mu = c(10, 10, 10, 13), sd = 6, plot = FALSE)
  set.seed(7)
  direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)
  expect_identical(first, direct$main_results["a:b", "power"] / 100)
})
