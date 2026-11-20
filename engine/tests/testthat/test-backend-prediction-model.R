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

test_that("the precision of the mean or the risk is checked, as pmsampsize does not enforce it", {
  skip_if_not_installed("pmsampsize")
  # Continuous: 8 parameters, R-squared 0.25, mean 1, SD 5. pmsampsize asks
  # for 243 (its criterion 4 search stops a person after criterion 3's 242);
  # at 243 the interval's upper limit is about 1.55 times the mean, and the
  # margin 1.1 needs 7,206.
  spec <- prediction_spec("continuous", r2 = 0.25, parameters = 8L, mean = 1, sd = 5)
  result <- run_quietly(spec)
  pr <- result$prediction
  expect_identical(pr$n, 243)
  ratio <- function(n) 1 + stats::qt(0.975, n - 9) * sqrt(25 * 0.75 / n)
  expect_equal(pr$precision$achieved, ratio(243))
  expect_false(pr$precision$met)
  expect_identical(pr$precision$n_needed, 7206)
  expect_lte(ratio(7206), 1.1)
  expect_gt(ratio(7205), 1.1)
  expect_identical(pr$criteria$met, c(TRUE, TRUE, TRUE, FALSE))
  # The card's own example meets it.
  pr <- run_quietly(prediction_spec("continuous"))$prediction
  expect_true(pr$precision$met)
  expect_true(all(pr$criteria$met))
  # Survival: pmsampsize reports the margin at its n; it is checked against
  # 0.05 here.
  pr <- run_quietly(prediction_spec("time_to_event"))$prediction
  direct <- do.call(pmsampsize::pmsampsize, prediction_args(validate_quietly(prediction_spec("time_to_event"))))
  expect_equal(pr$precision$achieved, direct$int_uci - direct$int_cuminc)
  expect_identical(pr$precision$met, pr$precision$achieved <= 0.05)
  pr <- run_quietly(prediction_spec("time_to_event", rate = 0.4, cox_snell_r2 = 0.3, parameters = 5L))$prediction
  expect_false(pr$precision$met)
  expect_false(pr$criteria$met[3])
  # A binary outcome's criterion is enforced by pmsampsize.
  expect_null(run_quietly(prediction_spec())$prediction$precision)
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

# Validating an existing model (template "validation"): pmvalsampsize's
# pmvalsampsize().

validation_spec <- function(...) {
  spec <- example_spec("prediction_validation")
  spec$population <- utils::modifyList(spec$population, list(...))
  spec
}

test_that("a validation spec becomes pmvalsampsize()'s arguments", {
  args <- prediction_validation_args(validate_quietly(validation_spec()))
  expect_identical(args, list(type = "b", prevalence = 0.2, cstatistic = 0.75, oe = 1, cslope = 1, oeciwidth = 0.2,
    csciwidth = 0.2, cstatciwidth = 0.1, lpnormal = c(-1.6, 1.2), seed = 123456L, simobs = 1e6))
  spec <- validation_spec(lp_distribution = "beta", lp_mean = NULL, lp_sd = NULL, beta_a = 1, beta_b = 4, threshold = 0.1, oe = 0.9)
  spec$goal$nb_ci_width <- 0.3
  args <- prediction_validation_args(validate_quietly(spec))
  expect_equal(args[c("oe", "lpbeta", "threshold", "nbciwidth")], list(oe = 0.9, lpbeta = c(1, 4), threshold = 0.1, nbciwidth = 0.3))
  expect_null(args$lpnormal)
  expect_null(args$sensitivity)
})

test_that("the validation answer is pmvalsampsize()'s, with every criterion and the one that sets it", {
  skip_if_not_installed("pmvalsampsize")
  for (spec in list(validation_spec(), validation_spec(threshold = 0.1))) {
    result <- run_quietly(spec)
    direct <- suppressMessages(do.call(pmvalsampsize::pmvalsampsize, prediction_validation_args(validate_quietly(spec))))
    expect_identical(result$goal_type, "criteria")
    expect_true(result$prediction$validation)
    expect_identical(result$prediction$n, as.numeric(direct$sample_size))
    expect_identical(nrow(result$prediction$criteria), if (is.null(spec$population$threshold)) 3L else 4L)
    expect_identical(max(result$prediction$criteria$n), result$prediction$n)
    expect_identical(result$prediction$binding, "A precise estimate of the calibration slope")
    expect_true(all(result$check_run$ok))
    expect_identical(result$provenance$backend, "pmvalsampsize")
    expect_identical(result$provenance$seed, 123456L)
  }
})

test_that("validation problems are named in plain words", {
  expect_spec_problem(validation_spec(lp_sd = NULL), "A normal linear predictor needs 'population > lp_sd'")
  expect_spec_problem(validation_spec(beta_a = 2), "'population > beta_a' isn't used with a normal linear predictor")
  expect_spec_problem(validation_spec(sensitivity = 0.8, specificity = 0.7), "are for the net benefit at a risk threshold")
  expect_spec_problem(validation_spec(threshold = 0.1, sensitivity = 0.8), "Give both 'population > sensitivity' and 'population > specificity'")
  spec <- validation_spec()
  spec$goal$shrinkage <- 0.9
  expect_spec_problem(spec, "are for developing a model")
})

test_that("the validation R script reproduces the sample size with pmvalsampsize alone", {
  skip_unless_scripts_can_run()
  skip_if_not_installed("pmvalsampsize")
  spec <- validation_spec()
  run <- run_exported_script(spec, run_quietly(spec))
  expect_false(any(grepl("powerkit::|library\\(powerkit\\)", run$script)))
  expect_true(any(grepl("pmvalsampsize(", run$script, fixed = TRUE)))
  expect_equal(run$reproduced, run$powerkit)
})
