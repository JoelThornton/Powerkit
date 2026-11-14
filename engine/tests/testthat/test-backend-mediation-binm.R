# Mediation with a yes/no mediator (E39): regression-based causal mediation
# analysis by regmedint, simulated by Spower.

binm_spec <- function(n = 200, nrep = 100, x = "binary", y = "continuous") {
  spec <- read_spec(system.file("specs", "mediation_binary_mediator.json", package = "powerkit"))
  spec$goal <- list(type = "power", n = n)
  spec$options$nrep <- nrep
  if (identical(x, "continuous")) spec$variables$X <- list(type = "continuous", label = "Motivation")
  if (identical(y, "binary")) {
    spec$variables$Y <- list(type = "binary", label = "Screened", levels = list("No", "Yes"))
    spec$population <- list(metric = "odds_ratio", m_baseline = 0.3, m_odds_ratio = 2.5, y_baseline = 0.2,
      b_odds_ratio = 3, direct_odds_ratio = 1.2)
  }
  spec
}

test_that("the inputs read the paths on their model scales", {
  inputs <- binm_inputs(validate_quietly(binm_spec()))
  expect_true(inputs$x_binary)
  expect_false(inputs$y_binary)
  expect_equal(inputs$a, log(2.5))
  expect_identical(c(inputs$b, inputs$direct), c(0.5, 0.1))
  binary <- binm_inputs(validate_quietly(binm_spec(y = "binary")))
  expect_equal(c(binary$b, binary$direct), log(c(3, 1.2)))
  expect_identical(binary$y_baseline, 0.2)
})

test_that("the simulated data recover the models", {
  set.seed(2)
  data <- binm_data(40000, TRUE, TRUE, 0.3, log(2.5), 0.2, log(3), log(1.2))
  expect_identical(sum(data$X), 20000)
  m <- stats::coef(stats::glm(M ~ X, family = stats::binomial(), data = data))
  expect_lt(max(abs(unname(m) - c(stats::qlogis(0.3), log(2.5)))), 0.06)
  y <- stats::coef(stats::glm(Y ~ M + X, family = stats::binomial(), data = data))
  expect_lt(max(abs(unname(y) - c(stats::qlogis(0.2), log(3), log(1.2)))), 0.08)
})

test_that("regmedint's natural indirect effect is the published formula", {
  set.seed(3)
  data <- binm_data(2000, TRUE, FALSE, 0.3, log(2.5), 0.5, 0.5, 0.1)
  nie <- binm_nie(data, FALSE)
  beta <- stats::coef(stats::glm(M ~ X, family = stats::binomial(), data = data))
  b <- stats::coef(stats::lm(Y ~ M + X, data = data))[["M"]]
  expect_equal(nie[["est"]], b * (stats::plogis(sum(beta)) - stats::plogis(beta[[1]])), tolerance = 1e-8)
})

test_that("a run gives power with a check run that recovers the inputs, for each kind of X and Y", {
  for (args in list(list(), list(x = "continuous"), list(y = "binary"))) {
    result <- run_quietly(do.call(binm_spec, args))
    expect_identical(result$provenance$backend, "Spower")
    expect_true(result$curve$power > 0.3 && result$curve$power <= 1)
    expect_true(all(result$check_run$ok))
  }
})

test_that("a sample size search uses equal groups for a two-group X", {
  spec <- binm_spec()
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_identical(binm_backend(validate_quietly(spec))$n_step, 2L)
  spec$variables$X <- list(type = "continuous", label = "Motivation")
  expect_identical(binm_backend(validate_quietly(spec))$n_step, 1L)
})

test_that("problems are named in plain words", {
  spec <- binm_spec()
  spec$population$b <- NULL
  expect_spec_problem(spec, "'population' needs 'b'")
  spec <- binm_spec()
  spec$population$b_odds_ratio <- 2
  expect_error(validate_quietly(spec))
  spec <- binm_spec()
  spec$variables$M$reliability <- 0.8
  expect_spec_problem(spec, "Measurement error ('reliability') isn't modelled")
  spec <- binm_spec(y = "binary")
  spec$population$b <- 0.4
  expect_spec_problem(spec, "'population > b' is for a score")
})

test_that("a zero path is refused for a sample size", {
  spec <- binm_spec()
  spec$population$m_odds_ratio <- 1
  expect_identical(binm_tested_effect(spec), 0)
  expect_gt(binm_tested_effect(validate_quietly(binm_spec())), 0)
})

test_that("the simulated-data code draws the same model", {
  spec <- validate_quietly(binm_spec(y = "binary"))
  data <- simulated_data(spec, 40000, seed = 3)
  expect_identical(levels(data$Booked_an_appointment), c("No", "Yes"))
  by_group <- tapply(data$Booked_an_appointment == "Yes", data$Condition, mean)
  expect_equal(as.numeric(by_group), c(0.3, 2.5 * 0.3 / (1 - 0.3 + 2.5 * 0.3)), tolerance = 0.03)
})

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- binm_spec(n = 120, y = "binary")
  run <- expect_script_reproduces_power(spec, run_quietly(spec))
  expect_true(any(grepl("regmedint(", run$script, fixed = TRUE)))
})
