# The t-tests accept the effect in the outcome's own units (population >
# metric "raw"): validate_spec() works out d or d_z by its definition, and
# the result is the same as giving that standardised effect directly.

units_spec <- function(name, raw, goal = list(type = "power", n = 60)) {
  spec <- example_spec(name)
  spec$options <- list(seed = 7)
  if (name == "independent_t") {
    spec$target_test$method <- "student_t"
  }
  spec$population <- list(metric = "raw", raw = raw)
  spec$goal <- goal
  spec
}

standardised_spec <- function(spec, field, value) {
  spec$population <- stats::setNames(list("standardised", value), c("metric", field))
  spec
}

test_that("two groups: d is the difference in means divided by the SD", {
  spec <- units_spec("independent_t", list(mean_1 = 3.8, mean_2 = 4.5, sd = 1.2))
  valid <- validate_spec(spec)
  expect_equal(valid$population$d, 0.7 / 1.2)
  result <- run_spec(spec)
  direct <- run_spec(standardised_spec(spec, "d", 0.7 / 1.2))
  expect_equal(result$curve$power, direct$curve$power)
  expect_equal(result$effect_from_units$name, "Cohen's d")
  expect_equal(result$effect_from_units$value, 0.7 / 1.2)
  expect_equal(result$effect_from_units$difference, 0.7)
  expect_null(direct$effect_from_units)
})

test_that("one sample: d is the mean minus the test value, divided by the SD", {
  spec <- units_spec("one_sample_t", list(mean = 4.5, test_value = 4, sd = 1.25))
  expect_equal(validate_spec(spec)$population$d, 0.4)
  expect_equal(
    run_spec(spec)$curve$power,
    run_spec(standardised_spec(spec, "d", 0.4))$curve$power
  )
})

test_that("paired: d_z uses the SD of the differences, given or from one SD and r", {
  given <- units_spec("paired_t", list(mean_1 = 10, mean_2 = 12, sd_difference = 5))
  expect_equal(validate_spec(given)$population$dz, 0.4)
  # SD 5 and r = 0.5: the SD of the differences is 5 * sqrt(2 * 0.5) = 5.
  from_r <- units_spec("paired_t", list(mean_1 = 10, mean_2 = 12, sd = 5, r = 0.5))
  expect_equal(validate_spec(from_r)$population$dz, 0.4)
  expect_equal(run_spec(from_r)$effect_from_units$sd, 5)
  expect_equal(
    run_spec(from_r)$curve$power,
    run_spec(standardised_spec(from_r, "dz", 0.4))$curve$power
  )
})

test_that("a spec read back from its own validated form gives the same effect", {
  spec <- units_spec("independent_t", list(mean_1 = 3.8, mean_2 = 4.5, sd = 1.2))
  once <- validate_spec(spec)
  twice <- validate_spec(unclass(once))
  expect_equal(twice$population$d, once$population$d)
  expect_equal(spec_hash(twice), spec_hash(once))
})

test_that("a spec in the outcome's units needs its values, and only one SD route", {
  spec <- units_spec("independent_t", list(mean_1 = 3.8, mean_2 = 4.5))
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  no_raw <- units_spec("independent_t", NULL)
  no_raw$population <- list(metric = "raw")
  expect_error(validate_spec(no_raw), class = "powerkit_spec_error")
  standardised_with_raw <- example_spec("independent_t")
  standardised_with_raw$population$raw <- list(mean_1 = 1, mean_2 = 2, sd = 1)
  expect_error(validate_spec(standardised_with_raw), class = "powerkit_spec_error")
  both <- units_spec("paired_t", list(mean_1 = 10, mean_2 = 12, sd_difference = 5, sd = 5, r = 0.5))
  expect_error(validate_spec(both), class = "powerkit_spec_error")
  zero_sd <- units_spec("one_sample_t", list(mean = 1, test_value = 0, sd = 0))
  expect_error(validate_spec(zero_sd), class = "powerkit_spec_error")
})

test_that("the smallest detectable effect still works with the units given", {
  spec <- units_spec("independent_t", list(mean_1 = 0, mean_2 = 0, sd = 1.2),
    goal = list(type = "sensitivity", n = 100, power = 0.8))
  result <- run_spec(spec)
  expect_gt(result$sensitivity$effect, 0)
  expect_equal(result$effect_from_units$sd, 1.2)
})

test_that("the smallest detectable effect is also given in the outcome's units", {
  spec <- units_spec("independent_t", list(mean_1 = 0, mean_2 = 0, sd = 1.2),
    goal = list(type = "sensitivity", n = 100, power = 0.8))
  result <- run_spec(spec)
  expect_equal(result$effect_from_units$smallest_difference, result$sensitivity$effect * 1.2)
})
