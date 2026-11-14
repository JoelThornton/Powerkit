# Mediation with X in three or more groups (E42): dummy-coded relative
# indirect effects, simulated by Spower, fitted by lavaan, with manymome's
# Monte Carlo intervals.

mcx_spec <- function(n = 120, nrep = 100, draws = 200, group = "all") {
  spec <- read_spec(system.file("specs", "mediation_multicategorical.json", package = "powerkit"))
  spec$goal <- list(type = "power", n = n)
  spec$options$nrep <- nrep
  spec$options$ci_draws <- draws
  spec$target_test$group <- group
  spec
}

test_that("the inputs read the groups, paths and tested effect", {
  inputs <- mcx_inputs(validate_quietly(mcx_spec(group = "Loss framed")))
  expect_identical(inputs$levels, c("No message", "Gain framed", "Loss framed"))
  expect_equal(inputs$a, c(0.4, 0.6))
  expect_equal(inputs$direct, c(0, 0.1))
  expect_identical(inputs$tested, 2L)
  expect_identical(mcx_inputs(validate_quietly(mcx_spec()))$tested, 1:2)
  expect_identical(mcx_model(3), "M ~ D2 + D3\nY ~ M + D2 + D3")
})

test_that("the simulated data have equal groups and recover the paths", {
  set.seed(1)
  data <- mcx_data(30000, c(0.4, 0.6), 0.3, c(0, 0.1))
  expect_identical(colnames(data), c("D2", "D3", "M", "Y"))
  expect_equal(colSums(data[c("D2", "D3")]), c(D2 = 10000, D3 = 10000))
  fit <- stats::lm(Y ~ M + D2 + D3, data = data)
  expect_lt(max(abs(unname(stats::coef(fit)) - c(0, 0.3, 0, 0.1))), 0.03)
  fit_m <- stats::lm(M ~ D2 + D3, data = data)
  expect_lt(max(abs(unname(stats::coef(fit_m))[2:3] - c(0.4, 0.6))), 0.05)
  expect_equal(stats::sd(stats::residuals(fit)), sqrt(1 - 0.3^2), tolerance = 0.02)
})

test_that("a run gives power with a check run that recovers the inputs", {
  result <- run_quietly(mcx_spec())
  expect_identical(result$provenance$backend, "Spower")
  expect_true(result$curve$power > 0.3 && result$curve$power < 1)
  expect_true(all(result$check_run$ok))
  expect_true(any(grepl("M -> Y", result$check_run$parameter, fixed = TRUE)))
})

test_that("testing one group needs less than testing every group", {
  all <- run_quietly(mcx_spec(n = 90))$curve$power
  one <- run_quietly(mcx_spec(n = 90, group = "Loss framed"))$curve$power
  expect_true(one >= all)
})

test_that("problems are named in plain words", {
  spec <- mcx_spec()
  spec$population$m_differences <- list(0.4, 0.5, 0.6)
  expect_spec_problem(spec, "'population > m_differences' has 3 values")
  spec <- mcx_spec()
  spec$population$direct_differences <- list(0, 0, 0)
  expect_spec_problem(spec, "'population > direct_differences' has 3 values")
  spec <- mcx_spec(group = "No message")
  expect_spec_problem(spec, "'target_test > group' is \"No message\"")
  spec <- mcx_spec()
  spec$variables$M$reliability <- 0.8
  expect_spec_problem(spec, "Measurement error ('reliability') isn't modelled")
  spec <- mcx_spec()
  spec$population$b <- 0.99
  expect_s3_class(validate_quietly(spec), "powerkit_spec")
  spec$population$b <- 1
  expect_error(validate_quietly(spec))
})

test_that("a tested relative indirect effect of zero is refused for power", {
  spec <- mcx_spec(group = "Gain framed")
  spec$population$m_differences <- list(0, 0.6)
  expect_identical(mcx_tested_effect(validate_quietly(mcx_spec(group = "Gain framed"))), 0.4 * 0.3)
  expect_identical(mcx_tested_effect(spec), 0)
})

test_that("the simulated-data code draws the same model", {
  spec <- validate_quietly(mcx_spec())
  data <- simulated_data(spec, 30000, seed = 3)
  means <- tapply(data$Perceived_risk, data$Message, mean)
  expect_lt(max(abs(as.numeric(means[c("Gain framed", "Loss framed")] - means[["No message"]]) - c(0.4, 0.6))), 0.05)
})

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- mcx_spec(n = 60, group = "Loss framed")
  run <- expect_script_reproduces_power(spec, run_quietly(spec))
  expect_true(any(grepl("do_mc(", run$script, fixed = TRUE)))
})
