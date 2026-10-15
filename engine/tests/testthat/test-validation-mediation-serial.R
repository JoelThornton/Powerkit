# Validation: serial mediation (PROCESS model 6, two mediators).
# Backend: power4mome. Build guide section 6:
#   1. analytic agreement: none (no closed-form power for confidence-
#      interval tests of an indirect effect)
#   2. published examples: none found yet for two serial mediators
#   3. direct-call agreement with power4mome
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

serial_paths <- function(a1, a2, d21, b1, b2, c_prime) {
  list(
    "X->M1" = a1, "X->M2" = a2, "M1->M2" = d21,
    "M1->Y" = b1, "M2->Y" = b2, "X->Y" = c_prime
  )
}

# 2. Published examples ------------------------------------------------------------

test_that("serial mediation: matches a published serial example (published)", {
  skip_unless_full_validation()
  # No published two-mediator example found yet. power4mome's Quick
  #   Templates for parallel and serial mediation use three mediators (and
  #   the parallel one tests whether all the specific indirect effects are
  #   significant, not one of them), and Schoemann, Boulton & Short (2017),
  #   Social Psychological and Personality Science, 8(4), 379-386, has no
  #   parallel or serial example (its only worked example is simple
  #   mediation). Maintainer: if you find a published two-mediator serial example,
  #   update this comment and transcribe it.
  # To transcribe: the six standardised paths, N, alpha, and the reported
  #   power for the full serial indirect effect X->M1->M2->Y with its
  #   number of replications.
  a1 <- TODO_PUBLISHED_VALUE # X->M1
  a2 <- TODO_PUBLISHED_VALUE # X->M2
  d21 <- TODO_PUBLISHED_VALUE # M1->M2
  b1 <- TODO_PUBLISHED_VALUE # M1->Y
  b2 <- TODO_PUBLISHED_VALUE # M2->Y
  c_prime <- TODO_PUBLISHED_VALUE # X->Y
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(a1, a2, d21, b1, b2, c_prime, n, alpha, published_power, reference_nrep)

  spec <- mediation_spec(
    "process_6", c("M1", "M2"),
    paths = serial_paths(a1, a2, d21, b1, b2, c_prime),
    path = "X->M1->M2->Y", n = n, seed = 201, alpha = alpha
  )
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("serial mediation: powerkit matches a direct power4mome call", {
  skip_unless_full_validation()
  skip_if_not_installed("power4mome")
  spec <- mediation_spec(
    "process_6", c("M1", "M2"),
    paths = serial_paths(0.4, 0.1, 0.4, 0.1, 0.4, 0.05),
    path = "X->M1->M2->Y", n = 150, seed = 301
  )
  direct <- direct_power4mome(
    model = "
      m1 ~ x
      m2 ~ m1 + x
      y ~ m2 + m1 + x
    ",
    pop_es = "
      m1 ~ x: 0.4
      m2 ~ x: 0.1
      m2 ~ m1: 0.4
      y ~ m1: 0.1
      y ~ m2: 0.4
      y ~ x: 0.05
    ",
    n = 150, test = "indirect", x = "x", m = c("m1", "m2"), y = "y",
    ci_draws = validation_ci_draws(), nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("serial mediation: Type I error is near alpha when the M1->M2 link is 0", {
  skip_unless_full_validation()
  # The middle link is 0 and the outer links are large, so the serial
  # indirect effect X->M1->M2->Y is null and its test should approach alpha.
  spec <- mediation_spec(
    "process_6", c("M1", "M2"),
    paths = serial_paths(0.5, 0, 0, 0, 0.5, 0),
    path = "X->M1->M2->Y", n = 300, seed = 401
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
