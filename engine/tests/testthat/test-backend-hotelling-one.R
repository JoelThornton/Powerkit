# One-sample Hotelling's T-squared (one group's several outcomes against
# fixed values), simulated with Spower and powerkit's p_hotelling_one()
# experiment (options > method = "simulation"; the default is the exact
# formula, test-backend-hotelling-exact.R). Few replications.

hotelling_spec <- function(n = 40, nrep = 200, ...) {
  spec <- example_spec("hotelling_one")
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep, method = "simulation")
  for (name in names(list(...))) spec$population[[name]] <- list(...)[[name]]
  spec
}

test_that("one-sample Hotelling's T-squared is simulated with Spower, equal to a direct call, and recovers its population", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_quietly(hotelling_spec())
  expect_equal(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "Hotelling", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  expect_equal(nrow(result$check_run), 3 + 3 + 1)
  set.seed(7)
  direct <- Spower::Spower(p_hotelling_one(n = 40, means = c(22, 19, 24), mu0 = c(20, 18, 21), sds = c(6, 5, 7), r = 0.5),
    replications = 200, verbose = FALSE)
  expect_equal(result$curve$power, direct$power)
})

test_that("the experiment's test is Hotelling's one-sample T-squared, and its power the exact F test's", {
  # On one data set: the multivariate test of the intercept equals the
  # T-squared statistic's F with p and n - p df.
  set.seed(1)
  y <- as.matrix(hotelling_one_scores(25, c(0.3, 0.1, 0.2), c(0, 0, 0), c(1, 1, 1), 0.5))
  t2 <- 25 * drop(colMeans(y) %*% solve(stats::cov(y)) %*% colMeans(y))
  f <- (25 - 3) / (3 * 24) * t2
  expect_equal(stats::anova(stats::lm(y ~ 1), test = "Pillai")[1, "Pr(>F)"], stats::pf(f, 3, 22, lower.tail = FALSE))
  # Power: the noncentral F with noncentrality n times the Mahalanobis
  # distance between the means and the fixed values.
  result <- run_quietly(hotelling_spec(nrep = 2000))
  sigma <- diag(c(6, 5, 7)) %*% (matrix(0.5, 3, 3) + diag(0.5, 3)) %*% diag(c(6, 5, 7))
  ncp <- 40 * stats::mahalanobis(c(22, 19, 24), c(20, 18, 21), sigma)
  exact <- pwrss::power.f.test(ncp = ncp, df1 = 3, df2 = 37, alpha = 0.05, plot = FALSE, verbose = FALSE)$power
  expect_equal(result$curve$power, exact, tolerance = 0.03)
})

test_that("one-sample Hotelling's T-squared holds alpha when the means equal the fixed values", {
  null_power <- run_quietly(hotelling_spec(n = 30, nrep = 2000, means = c(20, 18, 21)))$curve$power
  expect_lt(abs(null_power - 0.05), 0.02)
})

test_that("one-sample Hotelling's T-squared specs are refused in plain English when they can't be run", {
  expect_error(validate_spec(hotelling_spec(mu0 = c(20, 18))), "'population > mu0' should have one value per outcome", class = "powerkit_spec_error")
  expect_error(validate_spec(hotelling_spec(sds = c(6, 5))), "'population > sds' should have one value per outcome", class = "powerkit_spec_error")
  expect_error(validate_spec(hotelling_spec(r = -0.6)), "must be above -0.5", class = "powerkit_spec_error")
  expect_error(validate_spec(hotelling_spec(n = 4)), class = "powerkit_spec_error")
})

test_that("the exported script reproduces one-sample Hotelling's T-squared", {
  skip_unless_scripts_can_run()
  spec <- hotelling_spec(nrep = 100)
  expect_script_reproduces_power(spec, run_for_export(spec))
})
