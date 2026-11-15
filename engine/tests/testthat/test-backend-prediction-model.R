# Prediction model development (design "prediction_model"): the minimum
# sample size by the criteria of Riley and colleagues, from pmsampsize's
# pmsampsize().

prediction_spec <- function(outcome = "binary", ...) {
  spec <- example_spec("prediction_development")
  spec$variables$Y$type <- outcome
  spec$population <- switch(outcome,
    binary = list(metric = "c_statistic", c_statistic = 0.8, parameters = 20L, prevalence = 0.2),
    continuous = list(metric = "r2", r2 = 0.2, parameters = 25L, mean = 1.9, sd = 0.6),
    time_to_event = list(metric = "cox_snell_r2", cox_snell_r2 = 0.051, parameters = 30L, rate = 0.065, timepoint = 2, mean_follow_up = 2.07))
  spec$population <- utils::modifyList(spec$population, list(...))
  spec
}

test_that("the spec becomes pmsampsize()'s arguments", {
  args <- prediction_args(validate_quietly(prediction_spec()))
  expect_identical(args, list(type = "b", parameters = 20L, shrinkage = 0.9, cstatistic = 0.8, prevalence = 0.2, seed = 123456L))
  args <- prediction_args(validate_quietly(prediction_spec("continuous")))
  expect_identical(args, list(type = "c", parameters = 25L, shrinkage = 0.9, rsquared = 0.2, intercept = 1.9, sd = 0.6, mmoe = 1.1))
  args <- prediction_args(validate_quietly(prediction_spec("time_to_event")))
  expect_equal(args, list(type = "s", parameters = 30L, shrinkage = 0.9, csrsquared = 0.051, rate = 0.065, timepoint = 2, meanfup = 2.07))
  spec <- prediction_spec(metric = "nagelkerke_r2", c_statistic = NULL, nagelkerke_r2 = 0.3)
  spec$goal$shrinkage <- 0.95
  args <- prediction_args(validate_quietly(spec))
  expect_identical(args[c("nagrsquared", "shrinkage")], list(nagrsquared = 0.3, shrinkage = 0.95))
  expect_null(args$seed)
})

test_that("the answer is pmsampsize()'s, with every criterion and the one that sets it", {
  skip_if_not_installed("pmsampsize")
  for (outcome in c("binary", "continuous", "time_to_event")) {
    spec <- prediction_spec(outcome)
    result <- run_quietly(spec)
    direct <- do.call(pmsampsize::pmsampsize, prediction_args(validate_quietly(spec)))
    expect_identical(result$goal_type, "criteria")
    expect_identical(result$prediction$n, as.numeric(direct$sample_size), label = outcome)
    expect_identical(result$n_required$n, result$prediction$n)
    expect_identical(nrow(result$prediction$criteria), if (outcome == "continuous") 4L else 3L)
    expect_identical(max(result$prediction$criteria$n), result$prediction$n)
    expect_true(result$prediction$binding %in% result$prediction$criteria$criterion)
    expect_true(all(result$check_run$ok))
    expect_identical(result$provenance$backend, "pmsampsize")
  }
})

test_that("the C-statistic's conversion always uses pmsampsize's default seed", {
  skip_if_not_installed("pmsampsize")
  spec <- prediction_spec()
  spec$options$seed <- 1L
  one <- run_quietly(spec)
  spec$options$seed <- 2L
  two <- run_quietly(spec)
  expect_identical(one$prediction$n, two$prediction$n)
  expect_identical(one$provenance$seed, 123456L)
  direct <- pmsampsize::pmsampsize(type = "b", cstatistic = 0.8, parameters = 20, prevalence = 0.2)
  expect_identical(one$prediction$n, as.numeric(direct$sample_size))
})

test_that("problems are named in plain words", {
  expect_spec_problem(prediction_spec(metric = "r2", c_statistic = NULL, r2 = 0.2), "For a yes/no outcome, give the model's anticipated performance as")
  expect_spec_problem(prediction_spec(prevalence = NULL), "A yes/no outcome needs 'population > prevalence'")
  expect_spec_problem(prediction_spec(mean = 2), "'population > mean' isn't used for a yes/no outcome")
  expect_spec_problem(prediction_spec(nagelkerke_r2 = 0.3), "Give one measure of the model's performance")
  spec <- prediction_spec()
  spec$goal$intercept_margin <- 1.2
  expect_spec_problem(spec, "'goal > intercept_margin' is for a continuous outcome only")
  expect_spec_problem(prediction_spec("time_to_event", timepoint = 200), "far beyond the mean follow-up")
  skip_if_not_installed("pmsampsize")
  expect_spec_problem(prediction_spec(metric = "cox_snell_r2", c_statistic = NULL, cox_snell_r2 = 0.65), "at or above the largest any model can reach")
  power <- example_spec("independent_t")
  power$goal$shrinkage <- 0.9
  expect_spec_problem(power, "only for prediction model development")
})

test_that("the R script reproduces the sample size with pmsampsize alone", {
  skip_unless_scripts_can_run()
  skip_if_not_installed("pmsampsize")
  spec <- prediction_spec("continuous")
  run <- run_exported_script(spec, run_quietly(spec))
  expect_false(any(grepl("powerkit::|library\\(powerkit\\)", run$script)))
  expect_true(any(grepl("pmsampsize(", run$script, fixed = TRUE)))
  expect_equal(run$reproduced, run$powerkit)
})
