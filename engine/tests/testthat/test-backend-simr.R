
# The number of items as the sample size (1 November 2026): the
# participants fixed, the items varied.
items_goal_spec <- function(goal = list(type = "power", n = 40L, unit = "items"), participants = 30L) {
  spec <- example_spec("crossed_two_condition")
  spec$population$items <- NULL
  spec$population$participants <- participants
  spec$goal <- goal
  spec$options <- list(nrep = 100L, seed = 21L)
  spec
}

test_that("with the number of items as the sample size, power is simr's at those items and the fixed participants", {
  spec <- items_goal_spec()
  result <- suppressWarnings(run_spec(spec))
  usual <- example_spec("crossed_two_condition")
  usual$population$items <- 40L
  usual$goal <- list(type = "power", n = 30L)
  usual$options <- list(nrep = 100L, seed = 21L)
  same <- suppressWarnings(run_spec(usual))
  # The same design and seeds, counted the other way round.
  expect_equal(result$curve$power, same$curve$power)
  expect_true(all(result$check_run$ok))
})

test_that("the items goal needs the participants, an even number of items between conditions, and no attrition", {
  missing <- items_goal_spec()
  missing$population$participants <- NULL
  expect_spec_problem(missing, "give 'population > participants'")
  expect_spec_problem(items_goal_spec(goal = list(type = "power", n = 41L, unit = "items")), "an even number of items")
  attrition <- items_goal_spec()
  attrition$options$attrition <- 0.1
  expect_spec_problem(attrition, "participants who drop out")
  both <- items_goal_spec()
  both$population$items <- 40L
  expect_spec_problem(both, "remove 'population > items'")
})

test_that("the exported script reproduces the items goal with simr alone", {
  spec <- items_goal_spec()
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
})
