# Validation: one-way repeated measures with an SD per condition, a
# correlation per pair and a sphericity correction. Backend: Superpower's
# ANOVA_exact(correction =) by default; ANOVA_power(correction =) on
# request. Build guide section 6:
#   1. published-example agreement (to choose: a published power analysis
#      with unequal variances or correlations and a Greenhouse-Geisser or
#      Huynh-Feldt correction)
#   2. agreement between Superpower's two routes, which compute it
#      differently: the exact data set, and simulated data sets each fitted
#      with afex and corrected
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

test_that("repeated measures, Greenhouse-Geisser: the exact data set agrees with simulation", {
  skip_unless_full_validation()
  args <- list(c(600, 630, 650), c(100, 120, 150), c(0.8, 0.5, 0.6), "GG")
  exact <- engine_power(do.call(within_covariance_spec, c(args, list(seed = 702, n = 30))))
  simulated <- engine_power(do.call(within_covariance_spec, c(args, list(seed = 703, n = 30, method = "simulation"))))
  expect_power_near(simulated, exact$power)
})

# 3. Type I error ------------------------------------------------------------------

test_that("repeated measures, unequal correlations: Type I error is near alpha with Greenhouse-Geisser", {
  skip_unless_full_validation()
  spec <- within_covariance_spec(c(600, 600, 600), c(100, 120, 150), c(0.8, 0.3, 0.5), "GG", seed = 704, n = 30, method = "simulation")
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
