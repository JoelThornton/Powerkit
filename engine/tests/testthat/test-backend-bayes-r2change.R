# The Bayes factor for an R-squared increase or one coefficient
# (backend-bayesfactor-r2change.R).

r2c_spec <- function(template = "r2_increase", goal = list(type = "power", n = 150)) {
  spec <- if (identical(template, "single_coefficient")) example_spec("regression_coefficient") else example_spec("regression_r2_increase")
  spec$target_test$method <- "bayes_factor"
  spec$target_test$alpha <- NULL
  spec$target_test$evidence_threshold <- 10
  if (identical(template, "single_coefficient")) {
    spec$population$variance_ratio <- NULL
    spec$population$r2_reduced <- 0.1
  }
  spec$goal <- goal
  spec$options <- list(nrep = 200, seed = 5)
  spec
}

test_that("the Bayes factor from the two R-squared values is lmBF()'s full model over the reduced one", {
  skip_if_not_installed("BayesFactor")
  set.seed(11)
  n <- 70
  data <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n))
  data$y <- 0.3 * data$x1 + 0.2 * data$x2 + 0.25 * data$x3 + rnorm(n)
  r2 <- function(f) summary(lm(f, data = data))$r.squared
  inputs <- list(p = 3L, q = 2L, prior_scale = 0.354)
  ours <- bfr2c_study_log_bf(inputs, n, list(full = r2(y ~ x1 + x2 + x3), reduced = r2(y ~ x1)))
  bf <- function(f) BayesFactor::extractBF(BayesFactor::lmBF(f, data = data, rscaleCont = 0.354, progress = FALSE), logbf = TRUE)$bf
  expect_equal(ours, bf(y ~ x1 + x2 + x3) - bf(y ~ x1), tolerance = 1e-4)
})

test_that("the interpolated Bayes factors agree with linearReg.R2stat() for every study", {
  skip_if_not_installed("BayesFactor")
  set.seed(3)
  for (shape in list(c(3, 20), c(1, 30), c(5, 5), c(20, 2))) {
    r2 <- rbeta(500, shape[1], shape[2])
    exact <- vapply(r2, function(v) BayesFactor::linearReg.R2stat(N = 150, p = 5, R2 = v, rscale = 0.354, simple = FALSE)[["bf"]], numeric(1))
    expect_lt(max(abs(bfr2c_log_bf(r2, 150, 5L, 0.354) - exact)), 1e-3)
  }
  expect_equal(bfr2c_log_bf(c(.1, .2), 150, 0L, 0.354), c(0, 0))
})

test_that("both questions route to the simulation, pass their check run and report the no-effect side", {
  skip_if_not_installed("BayesFactor")
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (template in c("r2_increase", "single_coefficient")) {
    spec <- r2c_spec(template)
    expect_valid_spec(spec)
    backend <- route_spec(validate_spec(spec), 5)
    expect_identical(backend$name, "BayesFactor")
    expect_true(all(backend$check_run()$ok))
    result <- run_spec(spec)
    expect_identical(result$provenance$method, "simulation")
    expect_gt(result$curve$power, 0.3)
    expect_lt(result$bayes$misleading_evidence, 0.05)
    expect_gte(result$bayes$evidence_for_null, 0)
  }
})

test_that("one coefficient needs the R-squared without it, and no robust-test settings", {
  spec <- r2c_spec("single_coefficient")
  spec$population$r2_reduced <- NULL
  expect_spec_problem(spec, "r2_reduced")
  spec <- r2c_spec("single_coefficient")
  spec$population$variance_ratio <- 2
  expect_spec_problem(spec, "normal errors")
})

test_that("the R script replays the same simulated studies", {
  skip_if_not_installed("BayesFactor")
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- r2c_spec("r2_increase")
  result <- run_spec(spec)
  env <- new.env(parent = globalenv())
  suppressMessages(capture.output(eval(parse(text = export_script(spec, result)), env)))
  expect_equal(env$reproduced$power, result$curve$power)
})

test_that("the check run works when the tested predictors are the only ones", {
  inputs <- list(p = 3L, q = 3L, r2_full = 0.12, r2_reduced = 0, prior_scale = 0.707)
  check <- bfr2c_check_run(NULL, inputs, 1)
  expect_true(all(check$ok))
})
