# Mediation with a yes/no or count outcome (E32): regression-based causal
# mediation analysis by regmedint, simulated by Spower.

yglm_spec <- function(n = 300, nrep = 100, x = "binary", y = "negbin") {
  spec <- read_spec(system.file("specs", "mediation_binary_or_count_outcome.json", package = "powerkit"))
  spec$goal <- list(type = "power", n = n)
  spec$options$nrep <- nrep
  if (identical(x, "continuous")) spec$variables$X <- list(type = "continuous", label = "Motivation")
  if (identical(y, "poisson")) {
    spec$population$count_model <- NULL
    spec$population$dispersion <- NULL
  }
  if (identical(y, "binary")) {
    spec$variables$Y <- list(type = "binary", label = "Relapsed", levels = list("No", "Yes"))
    spec$population <- list(metric = "odds_ratio", a = 0.4, y_baseline = 0.3, b_odds_ratio = 0.6, direct_odds_ratio = 0.9)
  }
  spec
}

test_that("the inputs read the paths on their model scales", {
  inputs <- yglm_inputs(validate_quietly(yglm_spec()))
  expect_true(inputs$x_binary)
  expect_identical(inputs$outcome, "negbin")
  expect_identical(c(inputs$a, inputs$dispersion), c(0.4, 0.5))
  expect_equal(c(inputs$y0, inputs$b, inputs$direct), log(c(5, 0.8, 0.95)))
  expect_identical(yglm_inputs(validate_quietly(yglm_spec(y = "poisson")))[c("outcome", "dispersion")], list(outcome = "poisson", dispersion = 0))
  binary <- yglm_inputs(validate_quietly(yglm_spec(y = "binary")))
  expect_identical(binary$outcome, "binary")
  expect_equal(c(binary$y0, binary$b, binary$direct), c(stats::qlogis(0.3), log(0.6), log(0.9)))
})

test_that("the simulated data recover the models", {
  set.seed(2)
  data <- yglm_data(40000, TRUE, "negbin", 0.4, log(5), log(0.8), log(0.95), 0.5)
  expect_identical(sum(data$X), 20000)
  expect_lt(abs(stats::coef(stats::lm(M ~ X, data = data))[["X"]] - 0.4), 0.03)
  fit <- MASS::glm.nb(Y ~ M + X, data = data)
  expect_lt(max(abs(unname(stats::coef(fit)) - log(c(5, 0.8, 0.95)))), 0.04)
  expect_lt(abs(1 / fit$theta - 0.5), 0.05)
})

test_that("regmedint's natural indirect effect is a * b for these models", {
  set.seed(3)
  data <- yglm_data(2000, FALSE, "poisson", 0.4, log(3), log(0.8), 0, 0)
  nie <- yglm_nie(data, "poisson")
  a <- stats::coef(stats::lm(M ~ X, data = data))[["X"]]
  b <- stats::coef(stats::glm(Y ~ M + X, family = stats::poisson(), data = data))[["M"]]
  expect_equal(nie[["est"]], a * b, tolerance = 1e-6)
})

test_that("a run gives power with a check run that recovers the inputs, for each kind of X and Y", {
  for (args in list(list(), list(x = "continuous", y = "poisson"), list(y = "binary"))) {
    result <- run_quietly(do.call(yglm_spec, args))
    expect_identical(result$provenance$backend, "Spower")
    expect_true(result$curve$power > 0.2 && result$curve$power <= 1)
    expect_true(all(result$check_run$ok))
  }
})

test_that("a sample size search uses equal groups for a two-group X", {
  spec <- yglm_spec()
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_identical(yglm_backend(validate_quietly(spec))$n_step, 2L)
  spec$variables$X <- list(type = "continuous", label = "Motivation")
  expect_identical(yglm_backend(validate_quietly(spec))$n_step, 1L)
})

test_that("problems are named in plain words", {
  spec <- yglm_spec()
  spec$population$dispersion <- NULL
  expect_spec_problem(spec, "'population' needs 'dispersion'")
  spec <- yglm_spec(y = "poisson")
  spec$population$dispersion <- 0.5
  expect_spec_problem(spec, "'population > dispersion' isn't used for a Poisson count")
  spec <- yglm_spec(y = "binary")
  spec$population$b_rate_ratio <- 0.8
  expect_error(validate_quietly(spec))
  spec <- yglm_spec()
  spec$variables$M$reliability <- 0.8
  expect_spec_problem(spec, "Measurement error ('reliability') isn't modelled")
})

test_that("a zero path is refused for a sample size", {
  spec <- yglm_spec()
  spec$population$a <- 0
  expect_identical(yglm_tested_effect(spec), 0)
  expect_true(yglm_tested_effect(validate_quietly(yglm_spec())) != 0)
})

test_that("the simulated-data code draws the same model", {
  spec <- validate_quietly(yglm_spec())
  data <- simulated_data(spec, 40000, seed = 3)
  by_group <- tapply(data$Coping_self_efficacy, data$Condition, mean)
  expect_lt(abs(unname(diff(by_group)) - 0.4), 0.05)
  expect_equal(mean(data$Heavy_drinking_days_in_a_month[data$Condition == "Waiting list"]), 5 * exp(log(0.8)^2 / 2), tolerance = 0.05)
})

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- yglm_spec(n = 200, y = "binary")
  run <- expect_script_reproduces_power(spec, run_quietly(spec))
  expect_true(any(grepl("regmedint(", run$script, fixed = TRUE)))
})
