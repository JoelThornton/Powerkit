# The Brunner-Munzel test (two groups that may differ in spread), simulated
# with Spower by powerkit's experiment p_brunner_munzel(), which calls
# brunnermunzel's brunnermunzel.test(). Translation, direction, check run,
# refusals and the exported script; accuracy is checked by
# test-validation-brunner-munzel.R.

bm_spec <- function(n = 120, nrep = 100, sd_ratio = 2, shape = "skewed", ratio = NULL, alternative = NULL) {
  spec <- example_spec("independent_t")
  spec$target_test$method <- "brunner_munzel"
  spec$target_test$alternative <- alternative
  spec$population$score_shape <- shape
  spec$population$sd_ratio <- sd_ratio
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  if (!is.null(ratio)) spec$options$allocation_ratio <- ratio
  spec
}

test_that("the Brunner-Munzel test runs on Spower with brunnermunzel, and passes its check run", {
  result <- run_quietly(bm_spec())
  expect_equal(result$provenance$backend, "Spower")
  expect_equal(result$provenance$method, "simulation")
  expect_match(result$provenance$backend_function, "p_brunner_munzel", fixed = TRUE)
  expect_true("brunnermunzel" %in% names(result$provenance$packages))
  expect_true(all(result$check_run$ok))
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- bm_spec(n = 90, nrep = 200, ratio = 2)
  set.seed(7)
  direct <- Spower::Spower(p_brunner_munzel(n = 30, n2_n1 = 2, d = 0.4, sd_ratio = 2, shape = "skewed"),
    replications = 200, verbose = FALSE)
  expect_equal(run_quietly(spec)$curve$power, direct$power)
})

test_that("the groups have the spec's d and SD ratio, and one-sided tests point the right way", {
  g <- with_seed(1, brunner_munzel_scores(2e5, 1, 0.5, 2, "normal"))
  expect_equal((mean(g$second) - mean(g$first)) / sqrt((stats::var(g$first) + stats::var(g$second)) / 2), 0.5, tolerance = 0.02)
  expect_equal(stats::sd(g$second) / stats::sd(g$first), 2, tolerance = 0.02)
  # Group 2 higher: brunnermunzel.test()'s "less" (its help: it estimates
  # P(X < Y)), which is spower_alternative()'s translation of "greater".
  set.seed(2)
  x <- stats::rnorm(50)
  y <- stats::rnorm(50, 1)
  expect_lt(brunnermunzel::brunnermunzel.test(x, y, alternative = "less")$p.value, 0.01)
  expect_gt(brunnermunzel::brunnermunzel.test(x, y, alternative = "greater")$p.value, 0.99)
  spec <- validate_quietly(bm_spec(alternative = "greater"))
  expect_match(spower_inputs(spec)$description, "alternative = \"less\"", fixed = TRUE)
  greater <- run_quietly(bm_spec(n = 80, nrep = 200, alternative = "greater"))$curve$power
  less <- run_quietly(bm_spec(n = 80, nrep = 200, alternative = "less"))$curve$power
  expect_gt(greater, 0.3)
  expect_lt(less, 0.05)
})

test_that("unequal SDs need a method that supports them", {
  spec <- bm_spec()
  spec$target_test$method <- "mann_whitney"
  expect_spec_problem(spec, "'population > sd_ratio' is only used by the Brunner-Munzel, Yuen or Welch test")
  spec <- bm_spec()
  spec$options$method <- "exact"
  expect_spec_problem(spec, "'options > method' 'exact' isn't available for this test")
})

test_that("the R script reproduces the run", {
  spec <- bm_spec(n = 60, nrep = 100, ratio = 2, alternative = "greater")
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
})
