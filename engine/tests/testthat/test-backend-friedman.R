# Friedman's test (one-way repeated measures, rank-based) and the rank
# correlations on scores of a chosen shape, simulated with Spower. Few
# replications; accuracy is checked by test-validation-friedman.R.

friedman_spec <- function(shape = "skewed", n = 30, nrep = 200, r = 0.6) {
  spec <- example_spec("anova_oneway_within")
  spec$target_test$method <- "friedman"
  spec$population$score_shape <- shape
  spec$population$r <- r
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 4, nrep = nrep)
  spec
}

shaped_correlation_spec <- function(method = "spearman", shape = "heavy_tailed", n = 60, nrep = 200) {
  spec <- example_spec("correlation")
  spec$target_test$method <- method
  spec$population$score_shape <- shape
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 8, nrep = nrep)
  spec
}

test_that("Friedman's test runs on Spower, equals a direct call and recovers its population", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_quietly(friedman_spec())
  expect_identical(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "friedman.test", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  expect_equal(nrow(result$check_run), 3 + 3 + 1)
  set.seed(4)
  direct <- Spower::Spower(p_friedman(n = 30, means = c(6, 6.2, 6.5), r = 0.6, shape = "skewed"), replications = 200, verbose = FALSE)
  expect_equal(result$curve$power, direct$power)
})

test_that("Friedman's scores have SD 1, the stated correlation and a shift between conditions", {
  set.seed(1)
  y <- friedman_scores(1e5, c(0, 0.2, 0.4), 0.6, "heavy_tailed")
  expect_equal(unname(apply(y, 2, stats::sd)), rep(1, 3), tolerance = 0.02)
  expect_equal(stats::cor(y)[1, 2], 0.6, tolerance = 0.02)
  expect_equal(unname(colMeans(y)), c(0, 0.2, 0.4), tolerance = 0.02)
})

test_that("Friedman's test holds alpha when the conditions don't differ", {
  spec <- friedman_spec("heavy_tailed", nrep = 2000)
  spec$population$means <- list(600, 600, 600)
  expect_lt(abs(run_quietly(spec)$curve$power - 0.05), 0.02)
})

test_that("Friedman's specs are refused in plain English when they can't be run", {
  expect_spec_problem(friedman_spec(r = -0.2), "must be at least 0 and below 1")
  exact <- friedman_spec()
  exact$options$method <- "exact"
  expect_spec_problem(exact, "'options > method' 'exact' isn't available for this test")
  shaped_f <- example_spec("anova_oneway_within")
  shaped_f$population$score_shape <- "skewed"
  expect_spec_problem(shaped_f, "'population > score_shape' is only used by the rank tests")
})

test_that("a rank correlation on shaped scores equals a direct p_r() call with powerkit's generator", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_quietly(shaped_correlation_spec())
  expect_match(result$provenance$backend_function, "gen_fun = <heavy-tailed", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  # Spower reads its experiment unevaluated, so r is written out (the
  # example's -0.2).
  expect_equal(example_spec("correlation")$population$r, -0.2)
  set.seed(8)
  direct <- Spower::Spower(Spower::p_r(n = 60, r = -0.2, method = "spearman", gen_fun = shaped_pair_scores,
    shape = "heavy_tailed"), replications = 200, verbose = FALSE)
  expect_equal(result$curve$power, direct$power)
  # Normal scores keep Spower's own generator, as before.
  normal <- validate_quietly(shaped_correlation_spec(shape = "normal"))
  expect_null(spower_inputs(normal)$args(60)$gen_fun)
  pearson <- shaped_correlation_spec(method = "pearson")
  expect_spec_problem(pearson, "'population > score_shape' is only used by the rank tests")
})

test_that("shaped pairs have SD 1 and Pearson's correlation r", {
  set.seed(2)
  pair <- shaped_pair_scores(1e5, 0.4, "skewed")
  expect_equal(unname(sapply(pair, stats::sd)), c(1, 1), tolerance = 0.02)
  expect_equal(stats::cor(pair$x, pair$y), 0.4, tolerance = 0.02)
})

test_that("the exported script reproduces Friedman's test and a shaped rank correlation", {
  skip_unless_scripts_can_run()
  spec <- friedman_spec(nrep = 100)
  expect_script_reproduces_power(spec, run_for_export(spec))
  spec <- shaped_correlation_spec(method = "kendall", shape = "skewed", nrep = 100)
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("simulated data sets follow Friedman's and the shaped pair's populations", {
  data <- simulated_data(friedman_spec(), 3000, seed = 3)
  scores <- as.matrix(data[, -(1:2)])
  expect_equal(ncol(scores), 3)
  expect_lt(abs(stats::cor(scores)[1, 2] - 0.6), 0.06)
  pair <- simulated_data(shaped_correlation_spec(shape = "skewed"), 3000, seed = 3)
  expect_lt(abs(stats::cor(pair[[3]], pair[[4]]) - example_spec("correlation")$population$r), 0.06)
})
