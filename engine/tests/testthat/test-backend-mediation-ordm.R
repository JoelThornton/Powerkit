# Mediation with a mediator in ordered categories (E39): the latent-response
# model fitted by lavaan, simulated by Spower.

ordm_spec <- function(n = 200, nrep = 100, x = "binary", y = "continuous") {
  spec <- read_spec(system.file("specs", "mediation_ordinal_mediator.json", package = "powerkit"))
  spec$goal <- list(type = "power", n = n)
  spec$options$nrep <- nrep
  if (identical(x, "continuous")) spec$variables$X <- list(type = "continuous", label = "Motivation")
  if (identical(y, "binary")) {
    spec$variables$Y <- list(type = "binary", label = "Screened", levels = list("No", "Yes"))
    spec$population$y_baseline <- 0.3
  }
  spec
}

test_that("the inputs and thresholds follow the category proportions", {
  inputs <- ordm_inputs(validate_quietly(ordm_spec()))
  expect_true(inputs$x_binary)
  expect_false(inputs$y_binary)
  expect_identical(inputs$m_probabilities, c(0.3, 0.3, 0.25, 0.15))
  expect_identical(c(inputs$a, inputs$b, inputs$direct), c(0.4, 0.3, 0.1))
  expect_equal(stats::pnorm(ordm_thresholds(inputs$m_probabilities)), c(0.3, 0.6, 0.85))
  expect_identical(ordm_inputs(validate_quietly(ordm_spec(y = "binary")))$y_baseline, 0.3)
})

test_that("the simulated data have the categories' shares and the model's paths", {
  set.seed(2)
  data <- ordm_data(40000, TRUE, FALSE, c(0.3, 0.3, 0.25, 0.15), 0.4, 0.3, 0.1, 0.5)
  expect_identical(sum(data$X), 20000)
  expect_equal(as.numeric(table(data$M[data$X == 0])) / 20000, c(0.3, 0.3, 0.25, 0.15), tolerance = 0.03)
  # The second group's shares follow from the shift of the underlying score.
  expected <- diff(c(0, stats::pnorm(ordm_thresholds(c(0.3, 0.3, 0.25, 0.15)) - 0.4), 1))
  expect_equal(as.numeric(table(data$M[data$X == 1])) / 20000, expected, tolerance = 0.03)
  # An ordered probit regression of M on X gives back a.
  probit <- MASS::polr(factor(M) ~ X, data = data, method = "probit")
  expect_lt(abs(stats::coef(probit)[["X"]] - 0.4), 0.04)
  binary <- ordm_data(40000, FALSE, TRUE, c(0.2, 0.5, 0.3), 0, 0, 0, 0.3)
  expect_equal(mean(binary$Y), 0.3, tolerance = 0.02)
})

test_that("lavaan gives back the paths and the indirect effect on the inputs' scale, for each kind of Y", {
  for (y_binary in c(FALSE, TRUE)) {
    set.seed(3)
    data <- ordm_data(20000, TRUE, y_binary, c(0.3, 0.3, 0.25, 0.15), 0.4, 0.3, 0.1, 0.3)
    est <- ordm_fit(data, y_binary)
    truth <- c(a = 0.4, b = 0.3, direct = 0.1, indirect = 0.12)
    expect_true(all(abs(est$est - truth) < 4 * est$se), info = paste("binary Y:", y_binary))
  }
})

test_that("a model that can't be fitted counts as not significant", {
  data <- data.frame(X = rep(0:1, 5), M = 1L, Y = stats::rnorm(10))
  expect_null(ordm_fit(data, FALSE))
})

test_that("a run gives power with a check run that recovers the inputs, for each kind of X and Y", {
  for (args in list(list(), list(x = "continuous"), list(y = "binary"))) {
    result <- run_quietly(do.call(ordm_spec, args))
    expect_identical(result$provenance$backend, "Spower")
    expect_true(result$curve$power > 0.2 && result$curve$power <= 1)
    expect_true(all(result$check_run$ok), info = paste(names(args), args))
  }
})

test_that("a sample size search uses equal groups for a two-group X", {
  spec <- ordm_spec()
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_identical(ordm_backend(validate_quietly(spec))$n_step, 2L)
  spec$variables$X <- list(type = "continuous", label = "Motivation")
  expect_identical(ordm_backend(validate_quietly(spec))$n_step, 1L)
})

test_that("problems are named in plain words", {
  spec <- ordm_spec()
  spec$population$b <- NULL
  expect_spec_problem(spec, "'population' is missing 'b'")
  spec <- ordm_spec()
  spec$population$m_probabilities <- list(0.3, 0.3, 0.3)
  expect_spec_problem(spec, "must add up to 1")
  spec <- ordm_spec()
  spec$population$m_probabilities <- list(0.3, 0.7)
  expect_error(validate_quietly(spec))
  spec <- ordm_spec()
  spec$variables$M$levels <- list("Low", "Middle", "High")
  expect_spec_problem(spec, "4 proportions")
  spec <- ordm_spec()
  spec$population$y_baseline <- 0.3
  expect_spec_problem(spec, "for a yes/no outcome, not a score")
  spec <- ordm_spec()
  spec$variables$M$reliability <- 0.8
  expect_spec_problem(spec, "Measurement error ('reliability') isn't modelled")
})

test_that("a zero path is refused for a sample size", {
  spec <- ordm_spec()
  spec$population$a <- 0
  expect_identical(ordm_tested_effect(spec), 0)
  expect_gt(ordm_tested_effect(validate_quietly(ordm_spec())), 0)
})

test_that("the simulated-data code draws the same model, with the categories' names", {
  spec <- validate_quietly(ordm_spec())
  data <- simulated_data(spec, 40000, seed = 3)
  expect_identical(levels(data$Intention_to_book), c("Unlikely", "Unsure", "Likely", "Certain"))
  first <- data$Intention_to_book[data$Condition == "Usual information"]
  expect_equal(as.numeric(table(first)) / length(first), c(0.3, 0.3, 0.25, 0.15), tolerance = 0.03)
})

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- ordm_spec(n = 120, y = "binary")
  run <- expect_script_reproduces_power(spec, run_quietly(spec))
  expect_true(any(grepl("parameterization = \"theta\"", run$script, fixed = TRUE)))
})
