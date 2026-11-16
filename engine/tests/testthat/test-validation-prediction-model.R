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
# Validating an existing model (template "validation"), backend
# pmvalsampsize (pmvalsampsize()):
#   4. the published example (a placeholder for the maintainer): the worked
#      example of Riley et al. (2021, Statistics in Medicine 40, 4230-4251;
#      refs.bib pmvalsampsize_method)
#   5. powerkit agrees with pmvalsampsize called directly
#   6. criteria 1 and 3 from their closed forms in Riley et al. (2021),
#      without pmvalsampsize: criterion 1, n = (1 - phi) / (phi SE^2), where
#      SE is the standard error of log(O/E) whose 95% interval for O/E has
#      the target width; criterion 3, the smallest n whose interval for the
#      C-statistic, 2 x 1.96 SE(C), is no wider than the target, with
#      Newcombe's SE(C)^2 = C (1 - C) (1 + (n/2 - 1)(1 - C)/(2 - C) +
#      (n/2 - 1) C / (1 + C)) / (n^2 phi (1 - phi)). pmvalsampsize finds
#      criterion 1's SE by stepping up in increments of 0.0001 until the
#      width is reached, so its n can be a little below the exact one
#      (1,538 against 1,542 at phi = 0.2 and a width of 0.2): criterion 1
#      is checked to within 1%, criterion 3 exactly.
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

# 4. Validation: the published example -------------------------------------------------

validation_case_spec <- function(population, goal = list()) {
  spec <- unclass(read_spec(system.file("specs", "prediction_validation.json", package = "powerkit"), validate = FALSE))
  spec$population <- population
  spec$goal <- utils::modifyList(list(type = "criteria"), goal)
  spec$effect_justification <- list(type = "meta_analysis", source = "Validation case: the values are set by the test.")
  spec
}

test_that("validating a model: matches the published example (published)", {
  skip_unless_full_validation()
  # Source: Riley et al. (2021), Statistics in Medicine 40, 4230-4251: the
  #   applied example of validating a model of a binary outcome. Transcribe
  #   the outcome proportion, the anticipated C-statistic, the mean and SD
  #   of the linear predictor (normal), the target width of the O/E
  #   interval, the risk threshold and the minimum sample size, from the
  #   paper, not from pmvalsampsize. The other targets are pmvalsampsize's
  #   defaults unless the paper says otherwise.
  prevalence <- TODO_PUBLISHED_VALUE
  c_statistic <- TODO_PUBLISHED_VALUE
  lp_mean <- TODO_PUBLISHED_VALUE
  lp_sd <- TODO_PUBLISHED_VALUE
  oe_ci_width <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE
  skip_if_todo(prevalence, c_statistic, lp_mean, lp_sd, oe_ci_width, threshold, published_n)
  spec <- validation_case_spec(list(prevalence = prevalence, c_statistic = c_statistic, lp_distribution = "normal",
    lp_mean = lp_mean, lp_sd = lp_sd, threshold = threshold), list(oe_ci_width = oe_ci_width))
  expect_identical(run_spec(spec)$prediction$n, as.numeric(published_n))
})

# 5. Validation: agreement with pmvalsampsize called directly ----------------------------

test_that("validating a model: agrees with pmvalsampsize called directly (formula)", {
  skip_unless_full_validation()
  skip_if_not_installed("pmvalsampsize")
  cases <- list(
    list(spec = validation_case_spec(list(prevalence = 0.018, c_statistic = 0.8, lp_distribution = "normal", lp_mean = -5, lp_sd = 2.5),
      list(oe_ci_width = 1)),
      direct = function() pmvalsampsize::pmvalsampsize(type = "b", prevalence = 0.018, cstatistic = 0.8, lpnormal = c(-5, 2.5), oeciwidth = 1)),
    list(spec = validation_case_spec(list(prevalence = 0.3, c_statistic = 0.7, lp_distribution = "beta", beta_a = 2, beta_b = 5,
      oe = 0.9, calibration_slope = 0.95, threshold = 0.2)),
      direct = function() pmvalsampsize::pmvalsampsize(type = "b", prevalence = 0.3, cstatistic = 0.7, lpbeta = c(2, 5), oe = 0.9,
        cslope = 0.95, threshold = 0.2)),
    list(spec = validation_case_spec(list(prevalence = 0.1, c_statistic = 0.85, lp_distribution = "normal", lp_mean = -2.8, lp_sd = 1.5,
      threshold = 0.1, sensitivity = 0.8, specificity = 0.75), list(cstat_ci_width = 0.08, nb_ci_width = 0.3)),
      direct = function() pmvalsampsize::pmvalsampsize(type = "b", prevalence = 0.1, cstatistic = 0.85, lpnormal = c(-2.8, 1.5),
        cstatciwidth = 0.08, threshold = 0.1, sensitivity = 0.8, specificity = 0.75, nbciwidth = 0.3))
  )
  for (case in cases) {
    ours <- run_spec(case$spec)$prediction
    direct <- suppressMessages(utils::capture.output(out <- case$direct()))
    expect_identical(ours$n, as.numeric(out$sample_size))
    expect_equal(ours$criteria$n, as.numeric(out$results_table[grep("^Criteria", rownames(out$results_table)), "Samp_size"]))
  }
})

# 6. Validation: criteria 1 and 3 from their closed forms --------------------------------

test_that("validating a model: the O/E and C-statistic criteria match Riley et al.'s closed forms (formula)", {
  skip_unless_full_validation()
  skip_if_not_installed("pmvalsampsize")
  oe_n <- function(phi, width, oe = 1) {
    se <- stats::uniroot(function(s) exp(log(oe) + 1.96 * s) - exp(log(oe) - 1.96 * s) - width, c(1e-6, 5), tol = 1e-12)$root
    (1 - phi) / (phi * se^2)
  }
  cstat_n <- function(phi, cstat, width) {
    n <- 1:200000
    se2 <- cstat * (1 - cstat) * (1 + (n / 2 - 1) * (1 - cstat) / (2 - cstat) + (n / 2 - 1) * cstat / (1 + cstat)) / (n^2 * phi * (1 - phi))
    n[which(2 * 1.96 * sqrt(se2) <= width)[1]]
  }
  for (case in list(c(phi = 0.2, cstat = 0.75, oew = 0.2, cw = 0.1), c(phi = 0.05, cstat = 0.8, oew = 0.5, cw = 0.1),
    c(phi = 0.4, cstat = 0.65, oew = 0.15, cw = 0.08))) {
    spec <- validation_case_spec(list(prevalence = case[["phi"]], c_statistic = case[["cstat"]], lp_distribution = "normal",
      lp_mean = stats::qlogis(case[["phi"]]), lp_sd = 1), list(oe_ci_width = case[["oew"]], cstat_ci_width = case[["cw"]]))
    criteria <- run_spec(spec)$prediction$criteria
    expect_equal(criteria$n[1], oe_n(case[["phi"]], case[["oew"]]), tolerance = 0.01)
    expect_identical(criteria$n[3], as.numeric(cstat_n(case[["phi"]], case[["cstat"]], case[["cw"]])))
  }
})
