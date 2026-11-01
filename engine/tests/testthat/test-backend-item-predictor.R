# A predictor measured on each item (mixed_model / item_predictor, E67):
# simr's powerSim() on y ~ x + (1 + x | participant) + (1 | item).

item_spec <- function(binary = FALSE, goal = list(type = "power", n = 30L), nrep = 100L) {
  spec <- example_spec("item_predictor")
  if (binary) {
    spec$variables$Y <- list(type = "binary", label = "Correct")
    spec$population <- list(metric = "probability", slope = 0.3, probability = 0.75, sd_participant = 0.6,
      sd_participant_slope = 0.2, sd_item = 0.5, items = 60L)
    spec$target_test$method <- "wald"
  }
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 6L)
  spec
}

test_that("the model and design: X standardised across the items, every participant responding to every item", {
  inputs <- item_predictor_inputs(validate_spec(item_spec()))
  expect_identical(deparse1(inputs$formula), "y ~ x + (1 + x | participant) + (1 | item)")
  data <- item_predictor_design(inputs, 5)
  expect_equal(nrow(data), 5 * 60)
  x <- tapply(data$x, data$item, unique)
  expect_equal(c(mean(x), mean(x^2)), c(0, 1), tolerance = 1e-12)
})

test_that("a score and a yes/no outcome run on simr, and the check run recovers the population", {
  for (binary in c(FALSE, TRUE)) {
    result <- suppressWarnings(run_spec(item_spec(binary)))
    expect_true(all(result$check_run$ok), label = binary)
    expect_match(result$provenance$backend_function, if (binary) "fixed(\"x\", \"z\")" else "fixed(\"x\", \"sa\")", fixed = TRUE)
  }
})

test_that("item-predictor specs refuse what doesn't fit the outcome, in plain words", {
  spec <- item_spec(binary = TRUE)
  spec$population$sd_residual <- 1
  expect_spec_problem(spec, "no residual SD")
  wrong <- item_spec()
  wrong$target_test$method <- "wald"
  expect_spec_problem(wrong, "\"satterthwaite_t\"")
  zero <- item_spec(goal = list(type = "sample_size", power = 0.8))
  zero$population$slope <- 0
  expect_error(validate_spec(zero), class = "powerkit_spec_error")
})

test_that("the exported script reproduces the result with simr alone, and the data set has a row per participant and item", {
  spec <- item_spec()
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
  data <- simulated_data(validate_spec(item_spec(nrep = 100L)), 4)
  expect_equal(nrow(data), 4 * 60)
  expect_true("Word_frequency" %in% names(data))
})

test_that("Satterthwaite's test is never more liberal than simr's z test (Departure 16)", {
  # The same t statistic referred to a t distribution: on the same data
  # sets every rejection by Satterthwaite's test is one by z too
  # (docs/conventions.md, 16, gives the size at 10 and 30 participants).
  inputs <- item_predictor_inputs(validate_spec(item_spec()))
  model <- simr_model(inputs, 10)
  power <- vapply(c("sa", "z"), function(m) {
    r <- suppressMessages(suppressWarnings(simr::powerSim(model, test = simr::fixed("x", m), nsim = 100, seed = 12, progress = FALSE)))
    r$x / r$n
  }, numeric(1))
  expect_lte(power[["sa"]], power[["z"]])
})
