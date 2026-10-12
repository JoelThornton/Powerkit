# Validation: simple mediation (PROCESS model 4, one mediator).
# Backend: power4mome. Build guide section 6:
#   1. analytic agreement: none (no closed-form power for confidence-
#      interval tests of an indirect effect)
#   2. published examples: Schoemann, Boulton & Short (2017)
#   3. direct-call agreement with power4mome
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# 2. Published examples ------------------------------------------------------------

test_that("simple mediation: matches Schoemann, Boulton & Short (2017) (published)", {
  skip_unless_full_validation()
  # Source: Schoemann, Boulton & Short (2017), "Determining power and sample
  #   size for simple and complex mediation models", Social Psychological
  #   and Personality Science, 8(4), 379-386: the worked simple-mediation
  #   example (Monte Carlo confidence interval method, as in their app).
  #   Transcribe standardised paths a (X->M), b (M->Y) and c' (X->Y), N,
  #   alpha (or CI level), the number of Monte Carlo draws, and the
  #   reported power for the indirect effect with its number of
  #   replications. If the paper gives correlations rather than
  #   standardised paths, leave these as TODO and note it: powerkit's spec
  #   takes standardised paths.
  a <- TODO_PUBLISHED_VALUE
  b <- TODO_PUBLISHED_VALUE
  c_prime <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # replications behind the published power
  skip_if_todo(a, b, c_prime, n, alpha, published_power, reference_nrep)

  spec <- mediation_spec(
    "process_4", "M",
    paths = list("X->M" = a, "M->Y" = b, "X->Y" = c_prime),
    path = "X->M->Y", n = n, seed = 201, alpha = alpha
  )
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("simple mediation: powerkit matches a direct power4mome call", {
  skip_unless_full_validation()
  skip_if_not_installed("power4mome")
  spec <- mediation_spec(
    "process_4", "M",
    paths = list("X->M" = 0.3, "M->Y" = 0.3, "X->Y" = 0.1),
    path = "X->M->Y", n = 120, seed = 301
  )
  direct <- direct_power4mome(
    model = "
      m ~ x
      y ~ m + x
    ",
    pop_es = "
      m ~ x: 0.3
      y ~ m: 0.3
      y ~ x: 0.1
    ",
    n = 120, test = "indirect", x = "x", m = "m", y = "y",
    ci_draws = validation_ci_draws(), nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("simple mediation: Type I error is near alpha when a = 0 and b is large", {
  skip_unless_full_validation()
  # With both a and b zero, tests of the indirect effect are known to be
  # far below alpha, so the check uses a = 0 with a large b, where the
  # rejection rate should approach alpha.
  spec <- mediation_spec(
    "process_4", "M",
    paths = list("X->M" = 0, "M->Y" = 0.5, "X->Y" = 0),
    path = "X->M->Y", n = 200, seed = 401
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
