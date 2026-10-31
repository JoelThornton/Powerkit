# Participants and items with the condition between participants (E33,
# X a between factor): half the participants in
# each condition, each with a random intercept; items in both conditions
# (every participant responds to every item) or each condition with its
# own half of the items.

between_example <- function(item_design = "within", goal = list(type = "power", n = 40L), nrep = 100L) {
  spec <- read_spec(system.file("specs", "crossed_two_condition.json", package = "powerkit"))
  spec$variables$X$type <- "between_factor"
  spec$population$item_design <- item_design
  spec$population$sd_participant_slope <- NULL
  spec$population$r_participant <- NULL
  if (identical(item_design, "within")) spec$population$sd_item_slope <- 10
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 5L)
  spec
}

test_that("conditions between participants: the model and design simr receives, for items within and between", {
  inputs <- simr_inputs(validate_spec(between_example("within")))
  expect_identical(deparse1(inputs$formula), "y ~ cond + (1 | participant) + (1 + cond | item)")
  data <- simr_design(inputs, 10)
  # Every participant responds to every item, in their own condition.
  expect_equal(nrow(data), 10 * 40)
  expect_equal(as.vector(tapply(data$cond, data$participant, function(x) length(unique(x)))), rep(1, 10))
  expect_equal(sum(tapply(data$cond, data$participant, unique) < 0), 5)

  inputs <- simr_inputs(validate_spec(between_example("between")))
  expect_identical(deparse1(inputs$formula), "y ~ cond + (1 | participant) + (1 | item)")
  data <- simr_design(inputs, 10)
  # Each condition has its own 20 items and 5 participants.
  expect_equal(nrow(data), 10 * 20)
  expect_equal(as.vector(tapply(data$cond, data$item, function(x) length(unique(x)))), rep(1, 40))
})

test_that("conditions between participants run on simr, and the check run recovers the population", {
  for (items in c("within", "between")) {
    result <- suppressWarnings(run_spec(between_example(items)))
    expect_true(all(result$check_run$ok), label = items)
    expect_false("SD of participant condition slopes" %in% result$check_run$parameter, label = items)
    expect_identical("SD of item condition slopes" %in% result$check_run$parameter, items == "within", label = items)
  }
})

test_that("conditions between participants need an even n and no participant slope", {
  expect_spec_problem(between_example(goal = list(type = "power", n = 41L)), "2 equal groups")
  slope <- between_example()
  slope$population$sd_participant_slope <- 25
  expect_spec_problem(slope, "both conditions")
  within <- between_example()
  within$variables$X$type <- "within_factor"
  expect_spec_problem(within, "sd_participant_slope")
})

test_that("the exported script and the simulated data set follow the between-participants design", {
  spec <- between_example("between")
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
  code <- simulated_data_code(validate_spec(spec), 40, 1)
  expect_true(any(grepl("design$participant <= 20", code, fixed = TRUE)))
  expect_true(any(grepl("each condition's own half of the items", code, fixed = TRUE)))
})
