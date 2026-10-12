# Validation: two-way interaction in regression (Y ~ X + W + XW), with and
# without measurement error. Backend: InteractionPoweR. Build guide
# section 6:
#   1. analytic agreement with InteractionPoweR::power_interaction_r2()
#   2. published examples: the InteractionPoweR tutorial (AMPPS)
#   3. direct-call agreement with InteractionPoweR::power_interaction()
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# Correlations follow InteractionPoweR's parametrisation. Reliabilities of
# 1 (perfect measurement) are left out of the spec.
interaction_spec <- function(r_x_y, r_w_y, r_xw_y, r_x_w, seed, n = NULL,
                             rel_x = 1, rel_w = 1, rel_y = 1, alpha = 0.05,
                             target_power = NULL) {
  variable <- function(label, reliability) {
    v <- validation_variable("continuous", label)
    if (reliability < 1) v$reliability <- reliability
    v
  }
  validation_spec(
    design = "regression_interaction",
    template = "two_way",
    variables = list(
      X = variable("Predictor", rel_x),
      W = variable("Moderator", rel_w),
      Y = variable("Outcome", rel_y)
    ),
    population = list(
      metric = "correlation",
      r_X_Y = r_x_y, r_W_Y = r_w_y, r_XW_Y = r_xw_y, r_X_W = r_x_w
    ),
    target_test = list(effect = "interaction", method = "ols_t", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 1. Analytic agreement ----------------------------------------------------------

test_that("interaction, perfectly measured: power matches power_interaction_r2 (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("InteractionPoweR")
  spec <- interaction_spec(0.2, 0.2, 0.1, 0.2, n = 500, seed = 101)
  reference <- direct_interactionpower_analytic(500, 0.2, 0.2, 0.1, 0.2, alpha = 0.05)
  expect_power_near(engine_power(spec), reference$power)
})

test_that("interaction with unreliable measures: power matches power_interaction_r2 (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("InteractionPoweR")
  spec <- interaction_spec(
    0.2, 0.2, 0.1, 0.2, n = 800, seed = 102,
    rel_x = 0.8, rel_w = 0.7, rel_y = 0.9
  )
  reference <- direct_interactionpower_analytic(
    800, 0.2, 0.2, 0.1, 0.2,
    rel_x = 0.8, rel_w = 0.7, rel_y = 0.9, alpha = 0.05
  )
  expect_power_near(engine_power(spec), reference$power)
})

# 2. Published examples ------------------------------------------------------------

test_that("interaction: matches the InteractionPoweR tutorial example (published)", {
  skip_unless_full_validation()
  # Source: Baranger, Finsaas, Goldstein, Vize, Lynam & Olino (2023),
  #   "Tutorial: Power analyses for interaction effects in cross-sectional
  #   regressions", Advances in Methods and Practices in Psychological
  #   Science, 6(3), doi:10.1177/25152459231187531. Use the tutorial's main
  #   worked example with perfectly reliable measures: transcribe the
  #   correlations (r.x1.y, r.x2.y, r.x1x2.y, r.x1.x2), N, alpha and the
  #   reported power for the interaction. If the reported power is from a
  #   simulation, also transcribe its number of iterations.
  r_x_y <- TODO_PUBLISHED_VALUE # r.x1.y
  r_w_y <- TODO_PUBLISHED_VALUE # r.x2.y
  r_xw_y <- TODO_PUBLISHED_VALUE # r.x1x2.y
  r_x_w <- TODO_PUBLISHED_VALUE # r.x1.x2
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # n.iter behind the published power, or NULL if analytic
  skip_if_todo(r_x_y, r_w_y, r_xw_y, r_x_w, n, alpha, published_power, reference_nrep)

  spec <- interaction_spec(r_x_y, r_w_y, r_xw_y, r_x_w, n = n, seed = 201, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

test_that("interaction with measurement error: matches the InteractionPoweR tutorial (published)", {
  skip_unless_full_validation()
  # Source: Baranger et al. (2023), as above: the tutorial's example that
  #   adds reliability (rel.x1, rel.x2, rel.y < 1). Transcribe as above,
  #   plus the three reliabilities.
  r_x_y <- TODO_PUBLISHED_VALUE
  r_w_y <- TODO_PUBLISHED_VALUE
  r_xw_y <- TODO_PUBLISHED_VALUE
  r_x_w <- TODO_PUBLISHED_VALUE
  rel_x <- TODO_PUBLISHED_VALUE # rel.x1
  rel_w <- TODO_PUBLISHED_VALUE # rel.x2
  rel_y <- TODO_PUBLISHED_VALUE # rel.y
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # n.iter behind the published power, or NULL if analytic
  skip_if_todo(r_x_y, r_w_y, r_xw_y, r_x_w, rel_x, rel_w, rel_y, n, alpha, published_power, reference_nrep)

  spec <- interaction_spec(
    r_x_y, r_w_y, r_xw_y, r_x_w, n = n, seed = 202, alpha = alpha,
    rel_x = rel_x, rel_w = rel_w, rel_y = rel_y
  )
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

test_that("interaction: required N matches the InteractionPoweR tutorial (published)", {
  skip_unless_full_validation()
  # Source: Baranger et al. (2023), as above: the sample size the tutorial
  #   reports as needed for its target power (e.g. read from its power
  #   curve or sample-size search). Transcribe the correlations, alpha,
  #   target power and that N.
  r_x_y <- TODO_PUBLISHED_VALUE
  r_w_y <- TODO_PUBLISHED_VALUE
  r_xw_y <- TODO_PUBLISHED_VALUE
  r_x_w <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  target_power <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE
  skip_if_todo(r_x_y, r_w_y, r_xw_y, r_x_w, alpha, target_power, published_n)

  spec <- interaction_spec(
    r_x_y, r_w_y, r_xw_y, r_x_w, seed = 203, alpha = alpha,
    target_power = target_power
  )
  expect_n_near(engine_n_required(spec), published_n)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("interaction: powerkit matches a direct InteractionPoweR::power_interaction call", {
  skip_unless_full_validation()
  skip_if_not_installed("InteractionPoweR")
  spec <- interaction_spec(
    0.3, -0.1, 0.12, 0.25, n = 400, seed = 301,
    rel_x = 0.85, rel_w = 0.75
  )
  direct <- direct_interactionpower_simulation(
    400, 0.3, -0.1, 0.12, 0.25,
    rel_x = 0.85, rel_w = 0.75, alpha = 0.05,
    nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("interaction: Type I error is near alpha when main effects exist", {
  skip_unless_full_validation()
  spec <- interaction_spec(0.3, 0.2, 0, 0.3, n = 300, seed = 401)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("interaction with unreliable measures: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- interaction_spec(0.3, 0.2, 0, 0.3, n = 300, seed = 402, rel_x = 0.7, rel_w = 0.7)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
