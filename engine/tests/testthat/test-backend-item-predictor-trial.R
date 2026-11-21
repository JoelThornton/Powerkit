# A predictor measured on each trial (mixed_model / item_predictor, E67,
# population > x_level "trial"). The model, the design and the runs with a
# predictor measured on each item are in test-backend-item-predictor.R.

test_that("a predictor measured on each trial varies within items, takes an item slope, and runs with its check run and script", {
  spec <- item_spec()
  spec$population$x_level <- "trial"
  spec$population$sd_item_slope <- 5
  inputs <- item_predictor_inputs(validate_spec(spec))
  expect_identical(deparse1(inputs$formula), "y ~ x + (1 + x | participant) + (1 + x | item)")
  data <- item_predictor_design(inputs, 30)
  expect_gt(min(tapply(data$x, data$item, function(v) length(unique(v)))), 1)
  expect_equal(as.vector(tapply(data$x, data$participant, mean)), rep(0, 30), tolerance = 1e-12)
  result <- suppressWarnings(run_spec(spec))
  expect_true(all(result$check_run$ok))
  expect_true("SD of item slopes on X" %in% result$check_run$parameter)
  expect_script_reproduces_power(spec, result)
  expect_true(any(grepl("rotated across the items", simulated_data_code(validate_spec(spec), 30, 1), fixed = TRUE)))
  no_trial <- item_spec()
  no_trial$population$sd_item_slope <- 5
  expect_spec_problem(no_trial, "set 'population > x_level' to \"trial\"")
})
