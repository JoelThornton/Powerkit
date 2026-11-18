# Levene's test and the Brown-Forsythe test of two variances (E53), simulated
# with Spower by powerkit's experiment p_levene(), which calls
# car::leveneTest(). Routing, the direct Spower call, the score shapes,
# refusals, sensitivity, the check run and the exported script; accuracy is
# checked by test-validation-variance-tests.R.

levene_spec <- function(method = "levene", n = 120L, nrep = 100L, shape = NULL, ratio = NULL,
                        alternative = "two_sided", goal = NULL) {
  spec <- example_spec("two_variances")
  spec$population$var1 <- 1.5
  spec$population$var2 <- 1
  spec$population$score_shape <- shape
  spec$target_test$method <- method
  spec$target_test$alternative <- alternative
  spec$goal <- goal %||% list(type = "power", n = n)
  spec$options <- list(seed = 7L, nrep = nrep)
  if (!is.null(ratio)) spec$options$allocation_ratio <- ratio
  spec
}

test_that("Levene's and the Brown-Forsythe test run on Spower with car, and pass their check run", {
  for (method in c("levene", "brown_forsythe")) {
    result <- run_quietly(levene_spec(method))
    expect_equal(result$provenance$backend, "Spower")
    expect_equal(result$provenance$method, "simulation")
    expect_match(result$provenance$backend_function, "p_levene", fixed = TRUE)
    expect_match(result$provenance$backend_function, if (method == "levene") "center = mean" else "center = median", fixed = TRUE)
    expect_true("car" %in% names(result$provenance$packages))
    expect_true(all(result$check_run$ok))
  }
  heavy <- run_quietly(levene_spec("brown_forsythe", shape = "heavy_tailed", ratio = 2, n = 120L))
  expect_true(all(heavy$check_run$ok))
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  set.seed(7)
  direct <- Spower::Spower(p_levene(n = 90, var1 = 1.5, var2 = 1, ratio = 2, shape = "skewed", center = "median"),
    replications = 200, verbose = FALSE)
  spec <- levene_spec("brown_forsythe", n = 90L, nrep = 200L, shape = "skewed", ratio = 2)
  expect_equal(run_quietly(spec)$curve$power, direct$power)
})

test_that("the groups are split and scaled as the spec says", {
  g <- with_seed(1, levene_scores(3e5, 4, 1, 2, "heavy_tailed"))
  expect_equal(c(length(g$first), length(g$second)), c(1e5, 2e5))
  expect_equal(stats::var(g$first), 4, tolerance = 0.05)
  expect_equal(stats::var(g$second), 1, tolerance = 0.05)
  # Equal variances: the false-positive rate is near alpha.
  null <- levene_spec("levene", n = 60L, nrep = 1000L)
  null$population$var1 <- 1
  expect_lt(abs(run_quietly(null)$curve$power - 0.05), 0.025)
})

test_that("one-sided tests, score shapes for the F test and the exact method are refused in plain words", {
  expect_spec_problem(levene_spec(alternative = "greater"), "For a one-sided test of which group's variance is larger, choose the F test")
  shaped <- levene_spec("f_var", shape = "skewed")
  expect_spec_problem(shaped, "score_shape")
  exact <- levene_spec()
  exact$options$method <- "exact"
  expect_spec_problem(exact, "'options > method' 'exact' isn't available for this test")
  # Unequal groups are simulated here, unlike the simulated F test.
  expect_silent(validate_quietly(levene_spec(ratio = 2)))
})

test_that("the smallest detectable variance ratio is found by simulation", {
  spec <- levene_spec(nrep = 200L, goal = list(type = "sensitivity", n = 200L, power = 0.8))
  result <- run_quietly(spec)
  expect_true(is.finite(result$sensitivity$effect))
  expect_gt(result$sensitivity$effect, 1)
})

test_that("the R script reproduces the run", {
  spec <- levene_spec("brown_forsythe", n = 90L, nrep = 100L, shape = "heavy_tailed", ratio = 2)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
})

test_that("Departure 32's size: with normal scores the Brown-Forsythe test has a little less power than the F test", {
  # Variances 1.5 and 1, 200 people: the F test's exact power 0.518 against
  # the Brown-Forsythe test's 0.466 (10,000 simulated studies, validation
  # chunk variances); here 2,000.
  bf <- run_quietly(levene_spec("brown_forsythe", n = 200L, nrep = 2000L, shape = "normal"))
  f_test <- levene_spec("f_var", n = 200L)
  f_test$population$score_shape <- NULL
  f_test$options$nrep <- NULL
  f_power <- run_quietly(f_test)$curve$power
  expect_equal(f_power, 0.518, tolerance = 0.002)
  expect_lt(abs(bf$curve$power - 0.466), 4 * bf$curve$mcse)
  expect_gt(f_power - bf$curve$power, 0)
})
