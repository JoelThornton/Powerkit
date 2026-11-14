# Validation: repeated measures with an SD per condition (or cell), a
# correlation per pair and a sphericity correction. Backend: Superpower's
# ANOVA_power(correction =) by default once sphericity can fail (Departure
# 28); ANOVA_exact(correction =), an approximation, on request. Build guide
# section 6:
#   1. published-example agreement (to choose: a published power analysis
#      with unequal variances or correlations and a Greenhouse-Geisser or
#      Huynh-Feldt correction)
#   2. agreement with an independent reference: the corrected test's power
#      in 400,000 studies drawn from their sufficient statistics, in base R
#      (docs/upstream/superpower-gg-grid.R, whose p-values agree with afex on
#      identical data; docs/validation-log.md, 14 November 2026). Each test
#      also bounds the exact data set's approximation at 4 points.
#   3. Type I error under unequal correlations: near alpha with the
#      Greenhouse-Geisser correction
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

within_covariance_spec <- function(means, sd, r, correction, seed, n, method = NULL, alpha = 0.05) {
  v <- validation_variable
  spec <- validation_spec(
    design = "factorial_anova",
    template = "oneway_within",
    variables = list(A = v("within_factor", "Condition", levels = paste("Condition", seq_along(means))), Y = v("continuous", "Score")),
    population = list(metric = "raw", means = as.list(means), sd = sd, r = r),
    target_test = list(effect = "main_effect_A", method = "anova_f", correction = correction, alpha = alpha),
    seed = seed,
    n = n
  )
  if (!is.null(method)) spec$options$method <- method
  spec
}

# 1. Published example -----------------------------------------------------------

test_that("repeated measures without sphericity: matches a published example (published)", {
  skip_unless_full_validation()
  # Source to choose and transcribe: a published power analysis for a
  #   one-way repeated-measures ANOVA with unequal variances or
  #   correlations and a sphericity correction, giving the means, the SDs,
  #   the correlations, the correction, the number of participants, alpha
  #   and the power.
  means <- TODO_PUBLISHED_VALUE # condition means
  sd <- TODO_PUBLISHED_VALUE # SD of each condition
  r <- TODO_PUBLISHED_VALUE # correlation of each pair, (1, 2), (1, 3), (2, 3), ...
  correction <- TODO_PUBLISHED_VALUE # "GG" or "HF"
  n <- TODO_PUBLISHED_VALUE # number of participants
  alpha <- TODO_PUBLISHED_VALUE # alpha
  published_power <- TODO_PUBLISHED_VALUE # power (0 to 1)
  skip_if_todo(means, sd, r, correction, n, alpha, published_power)

  spec <- within_covariance_spec(means, sd, r, correction, seed = 701, n = n, alpha = alpha)
  expect_power_near(engine_power(spec), published_power)
})

# 2. Agreement between Superpower's two routes -------------------------------------

# The independent references (docs/upstream/superpower-gg-grid.R): the
# corrected test's power in 400,000 studies each.
reference_nrep <- 4e5
# How far the exact data set's epsilon scaling may stray from the corrected
# test's power: it ranged from -3.2 to +3.3 points across fifteen designs.
exact_approximation_bound <- 0.04

test_that("repeated measures, Greenhouse-Geisser: simulated power agrees with an independent reference", {
  skip_unless_full_validation()
  args <- list(c(600, 630, 650), c(100, 120, 150), c(0.8, 0.5, 0.6), "GG")
  reference <- 0.4658
  simulated <- engine_power(do.call(within_covariance_spec, c(args, list(seed = 703, n = 30))))
  expect_power_near(simulated, reference, reference_nrep = reference_nrep)
  exact <- engine_power(do.call(within_covariance_spec, c(args, list(seed = 702, n = 30, method = "exact"))))
  expect_lt(abs(exact$power - reference), exact_approximation_bound)
})

# 3. Type I error ------------------------------------------------------------------

test_that("repeated measures, unequal correlations: Type I error is near alpha with Greenhouse-Geisser", {
  skip_unless_full_validation()
  spec <- within_covariance_spec(c(600, 600, 600), c(100, 120, 150), c(0.8, 0.3, 0.5), "GG", seed = 704, n = 30, method = "simulation")
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

# Mixed and two-factor within designs (templates mixed, factorial_within)
# with an SD per cell and a correlation per pair: the same two checks.

mixed_covariance_spec <- function(means, sd, r, correction, seed, n, method = NULL) {
  v <- validation_variable
  spec <- validation_spec(
    design = "factorial_anova",
    template = "mixed",
    variables = list(A = v("between_factor", "Group", levels = c("Group 1", "Group 2")),
                     B = v("within_factor", "Time", levels = paste("Time", seq_len(length(means[[1]])))),
                     Y = v("continuous", "Score")),
    population = list(metric = "raw", means = means, sd = sd, r = r),
    target_test = list(effect = "interaction", method = "anova_f", correction = correction, alpha = 0.05),
    seed = seed,
    n = n
  )
  if (!is.null(method)) spec$options$method <- method
  spec
}

within_factorial_spec <- function(correction, seed, n, method = NULL, means = list(list(400, 410, 420), list(430, 450, 470))) {
  v <- validation_variable
  rr <- 0.7 - 0.08 * abs(outer(1:6, 1:6, "-"))
  spec <- validation_spec(
    design = "factorial_anova",
    template = "factorial_within",
    variables = list(A = v("within_factor", "Cue", levels = c("Valid", "Invalid")),
                     B = v("within_factor", "Delay", levels = c("Short", "Medium", "Long")),
                     Y = v("continuous", "Reaction time")),
    population = list(metric = "raw", means = means, sd = list(list(70, 85, 100), list(70, 85, 100)),
                      r = as.list(t(rr)[lower.tri(rr)])),
    target_test = list(effect = "interaction", method = "anova_f", correction = correction, alpha = 0.05),
    seed = seed,
    n = n
  )
  if (!is.null(method)) spec$options$method <- method
  spec
}

mixed_cov_means <- list(list(20, 16, 15), list(20, 19, 18.5))
mixed_cov_sd <- list(list(6, 7, 8), list(6, 8, 10))
mixed_cov_r <- list(0.7, 0.3, 0.6)

test_that("mixed design, Greenhouse-Geisser: simulated power agrees with an independent reference", {
  skip_unless_full_validation()
  reference <- 0.2169
  simulated <- engine_power(mixed_covariance_spec(mixed_cov_means, mixed_cov_sd, mixed_cov_r, "GG", seed = 706, n = 40))
  expect_power_near(simulated, reference, reference_nrep = reference_nrep)
  exact <- engine_power(mixed_covariance_spec(mixed_cov_means, mixed_cov_sd, mixed_cov_r, "GG", seed = 705, n = 40, method = "exact"))
  expect_lt(abs(exact$power - reference), exact_approximation_bound)
})

test_that("mixed design, unequal correlations: Type I error is near alpha with Greenhouse-Geisser", {
  skip_unless_full_validation()
  flat <- list(list(20, 20, 20), list(20, 20, 20))
  spec <- mixed_covariance_spec(flat, mixed_cov_sd, list(0.8, 0.2, 0.5), "GG", seed = 707, n = 40, method = "simulation")
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("two-factor within design, Huynh-Feldt: simulated power agrees with an independent reference", {
  skip_unless_full_validation()
  reference <- 0.0971
  simulated <- engine_power(within_factorial_spec("HF", seed = 709, n = 20))
  expect_power_near(simulated, reference, reference_nrep = reference_nrep)
  exact <- engine_power(within_factorial_spec("HF", seed = 708, n = 20, method = "exact"))
  expect_lt(abs(exact$power - reference), exact_approximation_bound)
})

test_that("two-factor within design, unequal correlations: Type I error is near alpha with Greenhouse-Geisser", {
  skip_unless_full_validation()
  flat <- list(list(400, 400, 400), list(400, 400, 400))
  spec <- within_factorial_spec("GG", seed = 710, n = 20, method = "simulation", means = flat)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
