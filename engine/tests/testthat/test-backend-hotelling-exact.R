# Hotelling's T-squared by its noncentral F distribution
# (backend-hotelling.R; Anderson, 2003, sections 5.3.4 and 5.4), for one
# group against fixed values and for a MANOVA of two groups: the default
# route, against pwrss and Spower's simulation of the same tests, and the
# R script reproducing the result.

exact_hotelling_spec <- function(goal = list(type = "power", n = 40), ...) {
  spec <- example_spec("hotelling_one")
  spec$goal <- goal
  spec$options <- list(seed = 7, ...)
  spec
}

test_that("one-sample Hotelling's T-squared is computed by formula by default", {
  result <- run_spec(exact_hotelling_spec())
  expect_identical(result$provenance$backend, "stats")
  expect_identical(result$provenance$method, "exact")
  expect_match(result$provenance$backend_function, "Anderson, 2003", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  # F with p and n - p df; noncentrality n times the Mahalanobis distance.
  sigma <- diag(c(6, 5, 7)) %*% (matrix(0.5, 3, 3) + diag(0.5, 3)) %*% diag(c(6, 5, 7))
  ncp <- 40 * stats::mahalanobis(c(22, 19, 24), c(20, 18, 21), sigma)
  expect_equal(result$details$df, c(3, 37))
  expect_equal(result$details$ncp, ncp)
  expect_equal(result$details$critical, stats::qf(0.95, 3, 37))
  # pwrss's generic F test from the same noncentrality gives the same power.
  pwrss_power <- pwrss::power.f.test(ncp = ncp, df1 = 3, df2 = 37, alpha = 0.05, plot = FALSE, verbose = FALSE)$power
  expect_equal(result$curve$power, pwrss_power, tolerance = 1e-8)
})

test_that("the sample size is the smallest n reaching the target power", {
  result <- run_spec(exact_hotelling_spec(goal = list(type = "sample_size", power = 0.8)))
  inputs <- hotelling_inputs(exact_hotelling_spec())
  n <- result$n_required$n
  expect_gte(hotelling_power(inputs, n), 0.8)
  expect_lt(hotelling_power(inputs, n - 1), 0.8)
})

test_that("the formula agrees with Spower's simulation of the same test", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (n in c(20, 40)) {
    exact <- run_spec(exact_hotelling_spec(goal = list(type = "power", n = n)))$curve$power
    simulated <- run_quietly(exact_hotelling_spec(goal = list(type = "power", n = n), nrep = 4000, method = "simulation"))$curve$power
    expect_lt(abs(simulated - exact), 3 * sqrt(exact * (1 - exact) / 4000))
  }
})

test_that("the exact route gives alpha when the means equal the fixed values", {
  spec <- exact_hotelling_spec(goal = list(type = "power", n = 30))
  spec$population$means <- spec$population$mu0
  expect_equal(hotelling_power(hotelling_inputs(spec), 30), 0.05)
})

test_that("the exported script reproduces the formula with base R alone", {
  skip_unless_scripts_can_run()
  spec <- exact_hotelling_spec()
  result <- run_for_export(spec)
  expect_no_match(export_script(spec, result), "library(", fixed = TRUE)
  expect_script_reproduces_power(spec, result)
})

two_group_exact_spec <- function(goal = list(type = "power", n = 160), ...) {
  spec <- example_spec("manova")
  spec$variables$A$levels <- c("Control", "Treatment")
  spec$population$means <- list(c(0, 0, 0, 0), c(0.3, 0.3, 0.1, 0))
  spec$population$sds <- c(1, 1, 1, 1)
  spec$population$r <- 0.3
  spec$variables$Y4 <- list(type = "continuous", label = "Wellbeing")
  spec$goal <- goal
  spec$options <- list(seed = 7, ...)
  spec
}

test_that("a MANOVA of two groups is two-sample Hotelling's T-squared, computed by formula", {
  result <- run_spec(two_group_exact_spec())
  expect_identical(result$provenance$backend, "stats")
  expect_identical(result$provenance$method, "exact")
  expect_match(result$provenance$backend_function, "two-sample", fixed = TRUE)
  expect_equal(result$details$df, c(4, 155))
  # pwrss's F test of R-squared (regressing the group on the outcomes) is
  # the same test: Cohen's f-squared = D^2 n1 n2 / N^2.
  correlation <- matrix(0.3, 4, 4)
  diag(correlation) <- 1
  d <- c(0.3, 0.3, 0.1, 0)
  f2 <- drop(t(d) %*% solve(correlation) %*% d) / 4
  pwrss_power <- pwrss::power.f.regression(r.squared = f2 / (1 + f2), k.total = 4, n = 160, alpha = 0.05, verbose = FALSE)$power
  expect_equal(result$curve$power, pwrss_power, tolerance = 1e-6)
  # Three groups stay simulated.
  expect_true(runs_simulation(example_spec("manova")))
})

test_that("the two-group formula agrees with Spower's simulation", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  exact <- run_spec(two_group_exact_spec())$curve$power
  simulated <- run_quietly(two_group_exact_spec(nrep = 4000, method = "simulation"))$curve$power
  expect_lt(abs(simulated - exact), 3 * sqrt(exact * (1 - exact) / 4000))
})

test_that("the exported script reproduces the two-group formula with base R alone", {
  skip_unless_scripts_can_run()
  spec <- two_group_exact_spec()
  result <- run_for_export(spec)
  expect_no_match(export_script(spec, result), "library(", fixed = TRUE)
  expect_script_reproduces_power(spec, result)
})
