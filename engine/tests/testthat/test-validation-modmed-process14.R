# Validation: second-stage moderated mediation (PROCESS model 14):
# M ~ X, Y ~ M + W + MW + X; target = index of moderated mediation (a * b3).
# Backend: power4mome. Build guide section 6:
#   1. analytic agreement: none (no closed-form power for confidence-
#      interval tests of the index)
#   2. published examples: power4mome vignettes; simsem tutorial (BRM, 2023)
#   3. direct-call agreement with power4mome
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

process_14_paths <- function(a, b1, b2, b3, c_prime) {
  list("X->M" = a, "M->Y" = b1, "W->Y" = b2, "MW->Y" = b3, "X->Y" = c_prime)
}

# 2. Published examples ------------------------------------------------------------

test_that("PROCESS model 14: matches a power4mome vignette example (published)", {
  skip_unless_full_validation()
  # Source: a power4mome vignette (pkgdown "Articles" at
  #   https://sfcheung.r-universe.dev/power4mome) with the moderator on the
  #   M->Y path, if one exists. Joel: name the exact vignette here, or
  #   replace with another published second-stage example. Transcribe the
  #   population values from its pop_es, n, alpha, nrep and the reported
  #   rejection rate for the index of moderated mediation.
  a <- TODO_PUBLISHED_VALUE # m ~ x
  b1 <- TODO_PUBLISHED_VALUE # y ~ m
  b2 <- TODO_PUBLISHED_VALUE # y ~ w
  b3 <- TODO_PUBLISHED_VALUE # y ~ m:w
  c_prime <- TODO_PUBLISHED_VALUE # y ~ x
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(a, b1, b2, b3, c_prime, n, alpha, published_power, reference_nrep)

  spec <- moderated_mediation_spec(
    "process_14", process_14_paths(a, b1, b2, b3, c_prime),
    n = n, seed = 201, alpha = alpha
  )
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

test_that("PROCESS model 14: matches the simsem tutorial example (published)", {
  skip_unless_full_validation()
  # Source: the "simsem tutorial (Behavior Research Methods, 2023)" cited
  #   in the build guide (authors and title not given; Joel to identify).
  #   Use its second-stage moderated mediation example if it has one;
  #   otherwise leave this test as TODO and say so here.
  a <- TODO_PUBLISHED_VALUE
  b1 <- TODO_PUBLISHED_VALUE
  b2 <- TODO_PUBLISHED_VALUE
  b3 <- TODO_PUBLISHED_VALUE
  c_prime <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(a, b1, b2, b3, c_prime, n, alpha, published_power, reference_nrep)

  spec <- moderated_mediation_spec(
    "process_14", process_14_paths(a, b1, b2, b3, c_prime),
    n = n, seed = 202, alpha = alpha
  )
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("PROCESS model 14: powerkit matches a direct power4mome call", {
  skip_unless_full_validation()
  skip_if_not_installed("power4mome")
  spec <- moderated_mediation_spec(
    "process_14", process_14_paths(0.4, 0.3, 0.1, 0.2, 0.05),
    n = 250, seed = 301
  )
  direct <- direct_power4mome(
    model = "
      m ~ x
      y ~ m + w + m:w + x
    ",
    pop_es = "
      m ~ x: 0.4
      y ~ m: 0.3
      y ~ w: 0.1
      y ~ m:w: 0.2
      y ~ x: 0.05
    ",
    n = 250, test = "index", x = "x", m = "m", y = "y", w = "w",
    ci_draws = validation_ci_draws(), nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("PROCESS model 14: Type I error is near alpha when the MW->Y path is 0", {
  skip_unless_full_validation()
  # The index is a * b3. With b3 = 0 and a large a, the test of the index
  # should approach alpha.
  spec <- moderated_mediation_spec(
    "process_14", process_14_paths(0.5, 0.3, 0.2, 0, 0),
    n = 300, seed = 401
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
