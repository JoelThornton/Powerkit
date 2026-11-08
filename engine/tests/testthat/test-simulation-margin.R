test_that("simulation_margin() is 1.96 binomial standard errors, widest at 50% power", {
  expect_equal(simulation_margin(1000), 1.96 * sqrt(0.25 / 1000))
  expect_equal(simulation_margin(400, power = 0.8), 1.96 * sqrt(0.16 / 400))
  expect_gt(simulation_margin(500), simulation_margin(500, power = 0.9))
  expect_equal(simulation_margin(c(100, 10000)), 1.96 * sqrt(0.25 / c(100, 10000)))
  expect_error(simulation_margin(0))
  expect_error(simulation_margin(100, power = 1.2))
})

test_that("the advice on few replications states the margin at 80% power", {
  spec <- example_spec("process_7")
  spec$options$nrep <- 500
  advice <- paste(spec_advice(spec), collapse = " ")
  expect_match(advice, format_number(round(simulation_margin(500, power = 0.8), 3)), fixed = TRUE)
})
