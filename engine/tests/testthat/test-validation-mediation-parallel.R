# Validation: parallel mediation (PROCESS model 4, two mediators).
# Backend: power4mome. Build guide section 6:
#   1. analytic agreement: none (no closed-form power for confidence-
#      interval tests of an indirect effect)
#   2. published examples: Schoemann, Boulton & Short (2017)
#   3. direct-call agreement with power4mome
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# 2. Published examples ------------------------------------------------------------

test_that("parallel mediation: matches Schoemann, Boulton & Short (2017) (published)", {
  skip_unless_full_validation()
  # Source: Schoemann, Boulton & Short (2017), Social Psychological and
  #   Personality Science, 8(4), 379-386: the worked example with two
  #   parallel mediators. Transcribe the standardised paths, the
  #   correlation between the mediators' residuals (0 if none), N, alpha,
  #   which specific indirect effect the reported power refers to, and that
  #   power with its number of replications. If the paper gives
  #   correlations rather than standardised paths, leave these as TODO and
  #   note it.
  a1 <- TODO_PUBLISHED_VALUE # X->M1
  a2 <- TODO_PUBLISHED_VALUE # X->M2
  b1 <- TODO_PUBLISHED_VALUE # M1->Y
  b2 <- TODO_PUBLISHED_VALUE # M2->Y
  c_prime <- TODO_PUBLISHED_VALUE # X->Y
  residual_r <- TODO_PUBLISHED_VALUE # M1<->M2 residual correlation
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  target_path <- TODO_PUBLISHED_VALUE # "X->M1->Y" or "X->M2->Y"
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(a1, a2, b1, b2, c_prime, residual_r, n, alpha, target_path, published_power, reference_nrep)

  spec <- mediation_spec(
    "process_4", c("M1", "M2"),
    paths = list("X->M1" = a1, "X->M2" = a2, "M1->Y" = b1, "M2->Y" = b2, "X->Y" = c_prime),
    residual_correlations = list("M1<->M2" = residual_r),
    path = target_path, n = n, seed = 201, alpha = alpha
  )
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("parallel mediation: powerkit matches a direct power4mome call", {
  skip_unless_full_validation()
  skip_if_not_installed("power4mome")
  spec <- mediation_spec(
    "process_4", c("M1", "M2"),
    paths = list("X->M1" = 0.3, "X->M2" = 0.2, "M1->Y" = 0.25, "M2->Y" = 0.3, "X->Y" = 0.05),
    path = "X->M2->Y", n = 200, seed = 301
  )
  direct <- direct_power4mome(
    model = "
      m1 ~ x
      m2 ~ x
      y ~ m1 + m2 + x
    ",
    pop_es = "
      m1 ~ x: 0.3
      m2 ~ x: 0.2
      y ~ m1: 0.25
      y ~ m2: 0.3
      y ~ x: 0.05
    ",
    n = 200, test = "indirect", x = "x", m = "m2", y = "y",
    ci_draws = validation_ci_draws(), nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

test_that("parallel mediation with correlated residuals: powerkit matches a direct power4mome call", {
  skip_unless_full_validation()
  skip_if_not_installed("power4mome")
  spec <- mediation_spec(
    "process_4", c("M1", "M2"),
    paths = list("X->M1" = 0.3, "X->M2" = 0.2, "M1->Y" = 0.25, "M2->Y" = 0.3, "X->Y" = 0.05),
    residual_correlations = list("M1<->M2" = 0.4),
    path = "X->M1->Y", n = 200, seed = 302
  )
  direct <- direct_power4mome(
    model = "
      m1 ~ x
      m2 ~ x
      m1 ~~ m2
      y ~ m1 + m2 + x
    ",
    pop_es = "
      m1 ~ x: 0.3
      m2 ~ x: 0.2
      m1 ~~ m2: 0.4
      y ~ m1: 0.25
      y ~ m2: 0.3
      y ~ x: 0.05
    ",
    n = 200, test = "indirect", x = "x", m = "m1", y = "y",
    ci_draws = validation_ci_draws(), nrep = validation_nrep(), seed = 302
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("parallel mediation: Type I error is near alpha for a null specific indirect effect", {
  skip_unless_full_validation()
  # X->M1 is 0 and M1->Y is large, so X->M1->Y is null; the other
  # mediator carries a real indirect effect.
  spec <- mediation_spec(
    "process_4", c("M1", "M2"),
    paths = list("X->M1" = 0, "X->M2" = 0.3, "M1->Y" = 0.5, "M2->Y" = 0.3, "X->Y" = 0),
    path = "X->M1->Y", n = 200, seed = 401
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
