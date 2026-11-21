# A predictor measured on each item (mixed_model / item_predictor, E67):
# the exported script, and Satterthwaite's test against simr's z test.
# The model, the design and the runs are in test-backend-item-predictor.R.

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
