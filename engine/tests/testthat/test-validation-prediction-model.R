# Validation: prediction model development (design "prediction_model").
# Backend: pmsampsize (pmsampsize()). There is no power and no test, so no
# Type I error check; instead:
#   1. published examples (placeholders for the maintainer): the worked
#      examples of Riley et al. (2019, Statistics in Medicine 38, 1276-1296;
#      refs.bib pmsampsize_method)
#   2. powerkit agrees with pmsampsize called directly, with the arguments
#      written out by hand, for each kind of outcome and each way of giving
#      the model's performance
#   3. for a binary outcome given a Cox-Snell R-squared, the three criteria
#      worked out here from the closed forms in Riley et al. (2019), without
#      pmsampsize: criterion (i), n = p / ((S - 1) log(1 - R2cs / S));
#      criterion (ii), the same with S = R2cs / (R2cs + 0.05 max(R2cs)),
#      where max(R2cs) = 1 - exp(2 (phi log(phi) + (1 - phi) log(1 - phi)));
#      criterion (iii), n = (1.96 / 0.05)^2 phi (1 - phi); each rounded up
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

prediction_validation_spec <- function(outcome, population, goal = list()) {
  spec <- unclass(read_spec(system.file("specs", "prediction_development.json", package = "powerkit"), validate = FALSE))
  spec$variables$Y$type <- outcome
  spec$population <- population
  spec$goal <- utils::modifyList(list(type = "criteria"), goal)
  spec$effect_justification <- list(type = "meta_analysis", source = "Validation case: the values are set by the test.")
  spec
}

# 1. Published examples ------------------------------------------------------------

test_that("binary outcome: matches the published example (published)", {
  skip_unless_full_validation()
  # Source: Riley et al. (2019), Statistics in Medicine 38, 1276-1296: the
  #   worked example of a new diagnostic model (section on applied
  #   examples). Transcribe the number of candidate predictor parameters,
  #   the outcome proportion, the anticipated Cox-Snell R-squared and the
  #   minimum sample size from the paper, not from pmsampsize.
  parameters <- TODO_PUBLISHED_VALUE
  prevalence <- TODO_PUBLISHED_VALUE
  cox_snell_r2 <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE
  skip_if_todo(parameters, prevalence, cox_snell_r2, published_n)
  spec <- prediction_validation_spec("binary", list(metric = "cox_snell_r2", cox_snell_r2 = cox_snell_r2,
    parameters = as.integer(parameters), prevalence = prevalence))
  expect_identical(run_spec(spec)$prediction$n, as.numeric(published_n))
})

test_that("time-to-event outcome: matches the published example (published)", {
  skip_unless_full_validation()
  # Source: Riley et al. (2019), Statistics in Medicine 38, 1276-1296: the
  #   worked example of a new prognostic model with a time-to-event
  #   outcome. Transcribe the number of candidate predictor parameters,
  #   the anticipated Cox-Snell R-squared, the overall event rate, the
  #   time point, the mean follow-up and the minimum sample size.
  parameters <- TODO_PUBLISHED_VALUE
  cox_snell_r2 <- TODO_PUBLISHED_VALUE
  rate <- TODO_PUBLISHED_VALUE
  timepoint <- TODO_PUBLISHED_VALUE
  mean_follow_up <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE
  skip_if_todo(parameters, cox_snell_r2, rate, timepoint, mean_follow_up, published_n)
  spec <- prediction_validation_spec("time_to_event", list(metric = "cox_snell_r2", cox_snell_r2 = cox_snell_r2,
    parameters = as.integer(parameters), rate = rate, timepoint = timepoint, mean_follow_up = mean_follow_up))
  expect_identical(run_spec(spec)$prediction$n, as.numeric(published_n))
})

# 2. Agreement with pmsampsize called directly ----------------------------------------

test_that("every outcome and measure of performance: agrees with pmsampsize called directly (formula)", {
  skip_unless_full_validation()
  skip_if_not_installed("pmsampsize")
  cases <- list(
    list(spec = prediction_validation_spec("binary", list(metric = "c_statistic", c_statistic = 0.75, parameters = 15L, prevalence = 0.1)),
      direct = function() pmsampsize::pmsampsize(type = "b", cstatistic = 0.75, parameters = 15, prevalence = 0.1, seed = 123456)),
    list(spec = prediction_validation_spec("binary", list(metric = "nagelkerke_r2", nagelkerke_r2 = 0.25, parameters = 10L, prevalence = 0.3),
      list(shrinkage = 0.95)),
      direct = function() pmsampsize::pmsampsize(type = "b", nagrsquared = 0.25, parameters = 10, prevalence = 0.3, shrinkage = 0.95)),
    list(spec = prediction_validation_spec("continuous", list(metric = "r2", r2 = 0.3, parameters = 12L, mean = 50, sd = 10),
      list(intercept_margin = 1.05)),
      direct = function() pmsampsize::pmsampsize(type = "c", rsquared = 0.3, parameters = 12, intercept = 50, sd = 10, mmoe = 1.05)),
    list(spec = prediction_validation_spec("time_to_event", list(metric = "nagelkerke_r2", nagelkerke_r2 = 0.15, parameters = 8L,
      rate = 0.1, timepoint = 5, mean_follow_up = 4)),
      direct = function() pmsampsize::pmsampsize(type = "s", nagrsquared = 0.15, parameters = 8, rate = 0.1, timepoint = 5, meanfup = 4))
  )
  for (case in cases) {
    ours <- run_spec(case$spec)$prediction
    direct <- suppressMessages(utils::capture.output(out <- case$direct()))
    expect_identical(ours$n, as.numeric(out$sample_size))
    expect_equal(ours$criteria$n, as.numeric(out$results_table[grep("^Criteria", rownames(out$results_table)), "Samp_size"]))
  }
})

# 3. The criteria from their closed forms -------------------------------------------

test_that("binary outcome: each criterion matches Riley et al.'s closed form (formula)", {
  skip_unless_full_validation()
  skip_if_not_installed("pmsampsize")
  by_hand <- function(p, r2, phi, shrinkage = 0.9) {
    max_r2 <- 1 - exp(2 * (phi * log(phi) + (1 - phi) * log(1 - phi)))
    s2 <- r2 / (r2 + 0.05 * max_r2)
    c(ceiling(p / ((shrinkage - 1) * log(1 - r2 / shrinkage))), ceiling(p / ((s2 - 1) * log(1 - r2 / s2))),
      ceiling((1.96 / 0.05)^2 * phi * (1 - phi)))
  }
  for (case in list(c(p = 24, r2 = 0.288, phi = 0.174), c(p = 10, r2 = 0.1, phi = 0.5), c(p = 40, r2 = 0.05, phi = 0.05))) {
    spec <- prediction_validation_spec("binary", list(metric = "cox_snell_r2", cox_snell_r2 = case[["r2"]],
      parameters = as.integer(case[["p"]]), prevalence = case[["phi"]]))
    ours <- run_spec(spec)$prediction
    expected <- by_hand(case[["p"]], case[["r2"]], case[["phi"]])
    expect_equal(ours$criteria$n, expected)
    expect_identical(ours$n, max(expected))
  }
})
