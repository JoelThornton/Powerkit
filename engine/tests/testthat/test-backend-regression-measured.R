# Multiple regression's F tests with measured predictors (Departure 39,
# regression-measured.R): the fixed-predictor power averaged over normal
# predictors, the default; predictors set by the design keep pwrss's
# fixed-model power.

regression_f_spec <- function(name, n, ...) {
  spec <- example_spec(name)
  spec$target_test$method <- "f_test"
  spec$population$variance_ratio <- NULL
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7)
  changes <- list(...)
  spec$target_test[names(changes)] <- changes
  spec
}

test_that("set predictors keep pwrss's fixed-model power", {
  spec <- regression_f_spec("regression_r2_increase", 150, predictor_model = "fixed")
  result <- run_spec(spec)
  expect_equal(result$provenance$backend, "pwrss")
  direct <- pwrss::power.f.regression(r.squared.change = 0.05 / 0.9, k.total = 5, k.tested = 2, n = 150, alpha = 0.05, verbose = 0)
  expect_equal(result$curve$power, direct$power)
})

test_that("measured predictors give less power than G*Power's fixed model (Departure 39)", {
  # Two predictors added to three (R-squared .10 to .15), N = 150.
  measured <- run_spec(regression_f_spec("regression_r2_increase", 150))
  fixed <- run_spec(regression_f_spec("regression_r2_increase", 150, predictor_model = "fixed"))
  expect_equal(measured$provenance$backend, "stats")
  expect_match(measured$provenance$backend_function, "measured predictors", fixed = TRUE)
  expect_equal(measured$curve$power, 0.7362, tolerance = 1e-4)
  expect_equal(fixed$curve$power, 0.7526, tolerance = 1e-4)
  # 173 people for 80% against 167.
  n_for <- function(spec) {
    spec$goal <- list(type = "sample_size", power = 0.8)
    run_spec(spec)$n_required$n
  }
  expect_equal(n_for(regression_f_spec("regression_r2_increase", 150)), 173)
  expect_equal(n_for(regression_f_spec("regression_r2_increase", 150, predictor_model = "fixed")), 167)
})

test_that("measured predictors: the formula equals the noncentral F mixed over a chi-square written out by sampling", {
  # The noncentrality is f^2 times a chi-square on N - 1 - (k - q) df:
  # averaging the conditional power over 200,000 draws of it agrees.
  f2 <- 0.04 / 0.96
  n <- 60
  set.seed(3)
  w <- stats::rchisq(2e5, n - 1 - 3)
  critical <- stats::qf(0.95, 1, n - 5)
  by_draws <- mean(stats::pf(critical, 1, n - 5, ncp = f2 * w, lower.tail = FALSE))
  expect_equal(regression_measured_power(f2, n, 4, 1, 0.05), by_draws, tolerance = 2e-3)
  # No effect gives alpha.
  expect_equal(regression_measured_power(0, n, 4, 1, 0.05), 0.05)
})

test_that("measured predictors agree with lm() on studies with new normal predictors", {
  # A quick version of the validation chunk's check (2,000 studies).
  n <- 40
  spec <- regression_f_spec("regression_r2_zero", n)
  power <- run_spec(spec)$curve$power
  set.seed(11)
  simulated <- mean(replicate(2000, {
    x <- matrix(stats::rnorm(n * 5), n)
    y <- drop(x %*% rep(sqrt(0.1 / 5), 5)) + stats::rnorm(n, sd = sqrt(0.9))
    f <- summary(stats::lm(y ~ x))$fstatistic
    stats::pf(f[1], f[2], f[3], lower.tail = FALSE) < 0.05
  }))
  expect_lt(abs(power - simulated), 4 * sqrt(power * (1 - power) / 2000))
})

test_that("measured predictors: sample size, smallest effect and the exported script agree", {
  spec <- regression_f_spec("regression_coefficient", 150)
  result <- run_spec(spec)
  expect_true(all(result$check_run$ok))
  script <- export_script(spec, result)
  expect_match(script, "dchisq", fixed = TRUE)
  env <- new.env()
  eval(parse(text = script), envir = env)
  expect_equal(env$power_at(150), result$curve$power, tolerance = 1e-8)
  spec$goal <- list(type = "sensitivity", n = 150, power = 0.8)
  found <- run_spec(spec)$sensitivity
  expect_equal(found$power, 0.8, tolerance = 1e-6)
  expect_equal(regression_measured_power(found$effect / (1 - found$effect), 150, 4, 1, 0.05), 0.8, tolerance = 1e-6)
})

test_that("measured predictors cite Shieh (2007)", {
  result <- run_spec(regression_f_spec("regression_r2_zero", 100))
  expect_match(export_citations(result), "Random Regression Models", fixed = TRUE)
})

test_that("predictor_model belongs to the F test only", {
  spec <- regression_f_spec("regression_coefficient", 150, predictor_model = "fixed")
  spec$target_test$method <- "ols_hc3"
  spec$population$variance_ratio <- 2
  expect_spec_problem(spec, "applies to the F test")
})
