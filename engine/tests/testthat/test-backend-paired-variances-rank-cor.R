# Spearman's rho and Kendall's tau (Spower's p_r(method =)) and the
# Pitman-Morgan test of two paired variances (p_r() on the sum and the
# difference of the paired scores), both by simulation. Few replications.

rank_cor_spec <- function(method, n = 80, nrep = 200, r = 0.3) {
  spec <- example_spec("correlation")
  spec$target_test$method <- method
  spec$population$r <- r
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

pm_spec <- function(n = 80, nrep = 200, ...) {
  spec <- example_spec("paired_variances")
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec$population <- utils::modifyList(spec$population, list(...))
  spec
}

test_that("Spearman's rho and Kendall's tau are simulated with Spower's p_r(method =), equal to a direct call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (method in c("spearman", "kendall")) {
    result <- run_quietly(rank_cor_spec(method))
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, sprintf("method = \"%s\"", method), fixed = TRUE)
    expect_true(all(result$check_run$ok))
    set.seed(7)
    direct <- Spower::Spower(Spower::p_r(n = 80, r = 0.3, method = method), replications = 200, verbose = FALSE)
    expect_equal(result$curve$power, direct$power, info = method)
  }
  # Pearson keeps the formula by default.
  spec <- rank_cor_spec("pearson")
  spec$options$nrep <- NULL
  expect_equal(run_spec(spec)$provenance$backend, "pwr")
})

test_that("the rank correlations have no formula", {
  spec <- rank_cor_spec("spearman")
  spec$options$method <- "exact"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("the Pitman-Morgan test recovers the paired variances and holds alpha when they are equal", {
  result <- run_quietly(pm_spec())
  expect_match(result$provenance$backend_function, "Pitman-Morgan", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  expect_equal(nrow(result$check_run), 3)
  null_power <- run_quietly(pm_spec(n = 60, nrep = 2000, var2 = 2500))$curve$power
  expect_lt(abs(null_power - 0.05), 0.02)
})

test_that("the Pitman-Morgan generator gives the sum and difference whose correlation is var1 - var2 over their SDs", {
  set.seed(1)
  d <- pitman_morgan_scores(200000, 0, var1 = 4, var2 = 1, rho12 = 0.5)
  # cov(sum, difference) = var1 - var2; var(sum) = 4 + 1 + 2 * 0.5 * 2; var(difference) = 4 + 1 - 2.
  expected <- 3 / sqrt(7 * 3)
  expect_equal(stats::cor(d$x, d$y), expected, tolerance = 0.01)
})

test_that("the exported scripts reproduce the rank correlations and the Pitman-Morgan test", {
  skip_unless_scripts_can_run()
  for (spec in list(rank_cor_spec("spearman", n = 60, nrep = 100), pm_spec(n = 60, nrep = 100))) {
    expect_script_reproduces_power(spec, run_for_export(spec))
  }
})
