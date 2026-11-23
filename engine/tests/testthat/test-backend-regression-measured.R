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

# The card's Bayes factors (backend-bayesfactor-regression.R,
# backend-bayesfactor-r2change.R).

bf_spec <- function(name, n, predictor_model = NULL, nrep = 2000) {
  spec <- example_spec(name)
  spec$target_test$method <- "bayes_factor"
  spec$target_test$alpha <- NULL
  spec$target_test$evidence_threshold <- 10
  spec$target_test$predictor_model <- predictor_model
  if (identical(name, "regression_coefficient")) {
    spec$population$variance_ratio <- NULL
    spec$population$r2_reduced <- 0.1
  }
  if (identical(name, "regression_r2_zero")) {
    spec$population <- list(metric = "r_squared", r2 = 0.1, predictors = 3L)
    spec$target_test$effect <- "r_squared"
  }
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 5)
  spec
}

test_that("Bayes factor for R-squared, measured predictors: the F's tail beyond the threshold's F, averaged over the predictors (Departure 39)", {
  measured <- run_spec(bf_spec("regression_r2_zero", 150))
  fixed <- run_spec(bf_spec("regression_r2_zero", 150, "fixed"))
  inputs <- bfreg_inputs(bf_spec("regression_r2_zero", 150))
  expect_true(inputs$measured)
  f_star <- bfreg_f_at(log(10), 150, inputs)
  expect_equal(measured$curve$power, regression_measured_tail(f_star, inputs$f2, 150, 3, 3))
  # By sampling the chi-square the noncentrality is f^2 times.
  set.seed(8)
  w <- stats::rchisq(2e5, 149)
  expect_equal(measured$curve$power, mean(stats::pf(f_star, 3, 146, ncp = inputs$f2 * w, lower.tail = FALSE)), tolerance = 2e-3)
  # R-squared .10 with three predictors at N = 150: 64.7% against 65.8%,
  # 193 people for a 0.8 chance against 189.
  expect_equal(measured$curve$power, 0.6474, tolerance = 1e-3)
  expect_equal(fixed$curve$power, 0.6578, tolerance = 1e-3)
  n_for <- function(spec) {
    spec$goal <- list(type = "sample_size", power = 0.8)
    run_spec(spec)$n_required$n
  }
  expect_equal(n_for(bf_spec("regression_r2_zero", 150)), 193)
  expect_equal(n_for(bf_spec("regression_r2_zero", 150, "fixed")), 189)
  # No effect does not depend on the predictors.
  expect_equal(measured$bayes$misleading_evidence, fixed$bayes$misleading_evidence)
  expect_match(measured$provenance$backend_function, "measured predictors", fixed = TRUE)
  expect_match(export_citations(measured), "Random Regression Models", fixed = TRUE)
  expect_no_match(export_citations(fixed), "Random Regression Models", fixed = TRUE)
})

test_that("Bayes factor for R-squared, measured predictors: the exported script reproduces the power", {
  skip_unless_scripts_can_run()
  spec <- bf_spec("regression_r2_zero", 150)
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_match(paste(run$script, collapse = "\n"), "dchisq", fixed = TRUE)
})

test_that("measured predictors: each study's two R-squared values are distributed as lm() gives them on new normal predictors", {
  n <- 40
  p <- 5
  q <- 2
  set.seed(21)
  by_lm <- t(replicate(4000, {
    xr <- matrix(stats::rnorm(n * (p - q)), n)
    xt <- matrix(stats::rnorm(n * q), n)
    y <- xr %*% rep(sqrt(0.2 / (p - q)), p - q) + xt %*% rep(sqrt(0.1 / q), q) + stats::rnorm(n, sd = sqrt(0.7))
    c(summary(stats::lm(y ~ xr + xt))$r.squared, summary(stats::lm(y ~ xr))$r.squared)
  }))
  drawn <- with_seed(22, regression_measured_draw(n, 4e4, p, q, 0.3, 0.2))
  drawn <- cbind(drawn$full, drawn$reduced)
  se <- apply(by_lm, 2, stats::sd) / sqrt(4000)
  expect_true(all(abs(colMeans(by_lm) - colMeans(drawn)) < 4 * se))
  for (j in 1:2) {
    expect_true(all(abs(stats::quantile(by_lm[, j], c(0.1, 0.5, 0.9)) - stats::quantile(drawn[, j], c(0.1, 0.5, 0.9))) < 0.015))
  }
  increase <- function(m) m[, 1] - m[, 2]
  expect_lt(abs(mean(increase(by_lm)) - mean(increase(drawn))), 4 * stats::sd(increase(by_lm)) / sqrt(4000))
  expect_lt(abs(stats::cor(by_lm)[1, 2] - stats::cor(drawn)[1, 2]), 0.03)
  # The tested set's noncentrality alone gives the F test's measured power.
  r2 <- with_seed(23, regression_measured_draw(150, 2e5, 5, 2, 0.15, 0.1))
  f <- ((r2$full - r2$reduced) / 2) / ((1 - r2$full) / 144)
  expect_equal(mean(f > stats::qf(0.95, 2, 144)), regression_measured_power(0.05 / 0.85, 150, 5, 2, 0.05), tolerance = 5e-3)
})

test_that("Bayes factor for an R-squared increase or one coefficient: measured predictors give less power than set ones", {
  for (name in c("regression_r2_increase", "regression_coefficient")) {
    measured <- run_spec(bf_spec(name, 150, nrep = 20000))
    fixed <- run_spec(bf_spec(name, 150, "fixed", nrep = 20000))
    expect_true(all(measured$check_run$ok))
    expect_match(measured$provenance$backend_function, "predictors measured on each person", fixed = TRUE)
    expect_lt(measured$curve$power, fixed$curve$power)
    expect_match(export_citations(measured), "Random Regression Models", fixed = TRUE)
  }
})

test_that("Bayes factor for an R-squared increase, set predictors: the R script replays the same simulated studies", {
  skip_if_not_installed("BayesFactor")
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- bf_spec("regression_r2_increase", 150, "fixed", nrep = 200)
  result <- run_spec(spec)
  env <- new.env(parent = globalenv())
  suppressMessages(capture.output(eval(parse(text = export_script(spec, result)), env)))
  expect_equal(env$reproduced$power, result$curve$power)
})

test_that("predictor_model is taken by the Bayes factors", {
  expect_no_error(validate_spec(bf_spec("regression_coefficient", 150, "fixed")))
})
