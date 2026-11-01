# Mediation with a yes/no X (E16): power4mome with x_fun = rbinary_rs().

binary_mediation_example <- function(goal = list(type = "power", n = 150), ...) {
  spec <- read_spec(system.file("specs", "mediation_simple.json", package = "powerkit"))
  spec$goal <- goal
  spec$options <- utils::modifyList(spec$options, list(...))
  spec
}

test_that("a yes/no X reaches power4mome through rbinary_rs() with the group split", {
  spec <- binary_mediation_example(nrep = 100, ci_draws = 200)
  spec$population$x_prob <- 0.3
  inputs <- power4mome_inputs(validate_spec(spec))
  expect_equal(inputs$x_prob, 0.3)
  result <- suppressWarnings(run_spec(spec))
  expect_true(all(result$check_run$ok))
  expect_true("proportion in X's second level" %in% result$check_run$parameter)
  expect_equal(power4mome_inputs(validate_spec(binary_mediation_example()))$x_prob, 0.5)
})

test_that("the path from X is shown as the group difference it implies, for any split", {
  spec <- validate_spec(binary_mediation_example())
  d <- implied_group_difference(spec)[[1]]
  expect_identical(c(d$outcome, d$kind), c("M", "path"))
  expect_equal(d$d, psych::r2d(-0.25))
  spec$population$x_prob <- 0.3
  d <- implied_group_difference(spec)[[1]]
  # The relation agrees with the group difference in a large simulated data set.
  data <- simulated_data(spec, 40000, seed = 2)
  groups <- split(data$Defensiveness, data$Condition)
  pooled <- sqrt(((length(groups[[1]]) - 1) * stats::var(groups[[1]]) + (length(groups[[2]]) - 1) * stats::var(groups[[2]])) /
    (length(data$Defensiveness) - 2))
  observed <- (mean(groups[["Self-affirmation"]]) - mean(groups[["Control"]])) / pooled
  expect_equal(d$d, observed, tolerance = 0.05)
  expect_equal(mean(data$Condition == "Self-affirmation"), 0.3, tolerance = 0.02)
})

test_that("x_prob needs a yes/no X, and a yes/no mediator is still refused", {
  spec <- read_spec(system.file("specs", "mediation_simple.json", package = "powerkit"))
  spec$variables$X <- list(type = "continuous", label = "Score")
  spec$population$x_prob <- 0.4
  expect_error(validate_spec(spec), "x_prob")
  spec <- sim_spec("process_7")
  spec$variables$W$reliability <- NULL
  spec$variables$M <- list(type = "binary", label = "Threatened")
  expect_error(validate_spec(spec), "must be 'continuous'", class = "powerkit_spec_error")
})

test_that("the exported script draws X with rbinary_rs()", {
  spec <- binary_mediation_example(nrep = 100, ci_draws = 100)
  spec$population$x_prob <- 0.4
  result <- suppressWarnings(run_spec(spec))
  script <- export_script(spec, result)
  expect_true(any(grepl("x_fun = list(X = list(rbinary_rs, p1 = 0.4))", script, fixed = TRUE)))
})
