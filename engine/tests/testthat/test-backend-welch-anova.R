# Welch's one-way ANOVA (unequal variances) via Spower's
# p_anova.test(var.equal = FALSE): translation, check run, refusals and the
# exported script. Few replications.

welch_spec <- function(n = 90, nrep = 200, sds = list(4, 6, 9)) {
  spec <- example_spec("anova_oneway_between")
  spec$target_test$method <- "welch_f"
  spec$population$sds <- sds
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("Welch's F runs on Spower by simulation and passes its check run", {
  result <- run_quietly(welch_spec())
  expect_equal(result$provenance$backend, "Spower")
  expect_equal(result$provenance$method, "simulation")
  expect_equal(result$provenance$backend_function, "Spower::Spower(Spower::p_anova.test(var.equal = FALSE))")
  expect_true(all(result$check_run$ok))
  expect_equal(nrow(result$check_run), 6)
})

test_that("on one core, Welch's F equals a direct Spower call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  set.seed(7)
  # Spower reads vector arguments by name.
  means <- c(10, 11, 13)
  sds <- c(4, 6, 9)
  direct <- Spower::Spower(
    Spower::p_anova.test(n = 30, k = 3, means = means, sds = sds, var.equal = FALSE),
    replications = 200, verbose = FALSE
  )
  expect_equal(run_quietly(welch_spec())$curve$power, direct$power)
})

test_that("without SDs per group, every group has the spec's SD", {
  spec <- welch_spec(sds = NULL)
  expect_equal(welch_sds(spec), c(6, 6, 6))
  expect_true(all(run_quietly(spec)$check_run$ok))
})

test_that("Welch's F has no formula, and the SDs per group belong to it alone", {
  spec <- welch_spec()
  spec$options$method <- "exact"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- welch_spec()
  spec$target_test$method <- "anova_f"
  expect_spec_problem(spec, "only used by Welch's F")
  expect_spec_problem(welch_spec(sds = list(4, 6, 9, 9)), "has 4 SDs, but there are 3 groups")
  spec <- welch_spec()
  spec$population$metric <- "standardised"
  expect_spec_problem(spec, "in the outcome's own units")
})

test_that("with one SD for every group, the means can be in SD units", {
  spec <- welch_spec(sds = NULL, nrep = 1000)
  spec$population$metric <- "standardised"
  spec$population$means <- list(0, 1 / 6, 0.5)
  spec$population$sd <- 1
  expect_s3_class(validate_spec(spec), "powerkit_spec")
  expect_equal(welch_sds(spec), c(1, 1, 1))
})

welch_sensitivity_spec <- function(sds = list(4, 6, 9), nrep = 300) {
  spec <- welch_spec(sds = sds, nrep = nrep)
  spec$goal <- list(type = "sensitivity", n = 90, power = 0.8)
  spec
}

test_that("Welch's F finds the smallest detectable effect by simulation, with an interval", {
  result <- run_quietly(welch_sensitivity_spec())
  s <- result$sensitivity
  expect_true(s$simulated)
  expect_equal(result$provenance$method, "simulation")
  expect_true(s$scale_lower < s$scale && s$scale < s$scale_upper)
  # The effect is the largest difference between two of the scaled means
  # (10, 11, 13 entered: a spread of 3).
  expect_equal(s$effect, 3 * s$scale)
  expect_equal(max(s$means) - min(s$means), s$effect)
  expect_equal(mean(s$means), mean(c(10, 11, 13)))
  expect_null(s$cohen_f)
  # Every simulated scale is recorded with its seed, for the script.
  sims <- result$provenance$simulations
  expect_true(all(c("scale", "seed", "fitted") %in% names(sims)))
  expect_true(all(sims$n == 90))
  expect_gte(sum(sims$fitted), 5)
})

test_that("with equal SDs, Welch's F's smallest detectable effect is close to the F test's", {
  # The two tests have almost the same power when the spreads are equal
  # and the groups are the same size.
  welch <- run_quietly(welch_sensitivity_spec(sds = NULL, nrep = 1000))$sensitivity
  f_test <- welch_sensitivity_spec(sds = NULL)
  f_test$target_test$method <- "anova_f"
  f_test$options <- list(seed = 7)
  exact <- run_quietly(f_test)$sensitivity
  expect_equal(welch$scale, exact$scale, tolerance = 0.05)
  # Welch's F loses a little power (it estimates each group's spread), so
  # its smallest detectable effect is not smaller by more than the noise.
  expect_gt(welch$scale_upper, exact$scale)
})

test_that("the exported script reproduces Welch's F's smallest detectable effect", {
  skip_unless_scripts_can_run()
  spec <- welch_sensitivity_spec(nrep = 100)
  result <- run_for_export(spec)
  run <- run_exported_script(spec, result)
  expect_equal(run$reproduced, run$powerkit, tolerance = 1e-10)
  expect_false(any(grepl("powerkit::|library\\(powerkit\\)", run$script)))
})

test_that("the exported script reproduces Welch's F", {
  skip_unless_scripts_can_run()
  spec <- welch_spec(n = 60, nrep = 100)
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_match(paste(run$script, collapse = "\n"), "var.equal = FALSE", fixed = TRUE)
})
