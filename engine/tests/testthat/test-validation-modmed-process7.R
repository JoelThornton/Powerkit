# Validation: first-stage moderated mediation (PROCESS model 7):
# M ~ X + W + XW, Y ~ M + X; target = index of moderated mediation (a3 * b).
# Backend: power4mome. Build guide section 6:
#   1. analytic agreement: none (no closed-form power for confidence-
#      interval tests of the index)
#   2. published examples: power4mome vignettes; simsem tutorial (BRM, 2023)
#   3. direct-call agreement with power4mome
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

process_7_paths <- function(a1, a2, a3, b, c_prime) {
  list("X->M" = a1, "W->M" = a2, "XW->M" = a3, "M->Y" = b, "X->Y" = c_prime)
}

# 2. Published examples ------------------------------------------------------------

test_that("PROCESS model 7: matches the power4mome vignette example (published)", {
  skip_unless_full_validation()
  # Source: power4mome vignette "Get started"
  #   (https://sfcheung.r-universe.dev/power4mome/doc/power4mome.html), its
  #   moderated-mediation example with the moderator on the X->M path, if
  #   it has one; otherwise the power4mome article (pkgdown "Articles")
  #   that covers this model. Update this comment with the exact vignette.
  #   Transcribe the population values from its pop_es (convert the
  #   "s"/"m"/"l" labels using the values the vignette states), n, the
  #   test used (index of moderated mediation), alpha, nrep and R, and the
  #   reported rejection rate.
  a1 <- TODO_PUBLISHED_VALUE # m ~ x
  a2 <- TODO_PUBLISHED_VALUE # m ~ w
  a3 <- TODO_PUBLISHED_VALUE # m ~ x:w
  b <- TODO_PUBLISHED_VALUE # y ~ m
  c_prime <- TODO_PUBLISHED_VALUE # y ~ x
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE # reported rejection rate
  reference_nrep <- TODO_PUBLISHED_VALUE # nrep behind the reported rate
  skip_if_todo(a1, a2, a3, b, c_prime, n, alpha, published_power, reference_nrep)

  spec <- moderated_mediation_spec(
    "process_7", process_7_paths(a1, a2, a3, b, c_prime),
    n = n, seed = 201, alpha = alpha
  )
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

test_that("PROCESS model 7: matches the simsem tutorial example (published)", {
  skip_unless_full_validation()
  # Source: the build guide cites a "simsem tutorial (Behavior Research
  #   Methods, 2023)" for moderated mediation but gives no authors or
  #   title. Joel: identify the paper, then transcribe its first-stage
  #   moderated mediation example: the standardised paths, n, alpha and the
  #   reported power for the index of moderated mediation, with its number
  #   of replications. If its example is a different model, move this test
  #   to the matching file.
  a1 <- TODO_PUBLISHED_VALUE
  a2 <- TODO_PUBLISHED_VALUE
  a3 <- TODO_PUBLISHED_VALUE
  b <- TODO_PUBLISHED_VALUE
  c_prime <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(a1, a2, a3, b, c_prime, n, alpha, published_power, reference_nrep)

  spec <- moderated_mediation_spec(
    "process_7", process_7_paths(a1, a2, a3, b, c_prime),
    n = n, seed = 202, alpha = alpha
  )
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

test_that("PROCESS model 7: required n matches the power4mome vignette (published)", {
  skip_unless_full_validation()
  # Source: the power4mome vignette on finding the sample size for a target
  #   power (n_from_power / n_region_from_power), using its moderated
  #   mediation example if it has one. Joel: name the exact vignette here.
  #   Transcribe the population values, alpha, target power and the
  #   sample size (or region) it reports.
  a1 <- TODO_PUBLISHED_VALUE
  a2 <- TODO_PUBLISHED_VALUE
  a3 <- TODO_PUBLISHED_VALUE
  b <- TODO_PUBLISHED_VALUE
  c_prime <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  target_power <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE
  skip_if_todo(a1, a2, a3, b, c_prime, alpha, target_power, published_n)

  spec <- moderated_mediation_spec(
    "process_7", process_7_paths(a1, a2, a3, b, c_prime),
    seed = 203, alpha = alpha, target_power = target_power
  )
  expect_n_near(engine_n_required(spec), published_n)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("PROCESS model 7: powerkit matches a direct power4mome call", {
  skip_unless_full_validation()
  skip_if_not_installed("power4mome")
  spec <- moderated_mediation_spec(
    "process_7", process_7_paths(0.3, 0.1, 0.2, 0.4, 0.05),
    n = 250, seed = 301
  )
  direct <- direct_power4mome(
    model = "
      m ~ x + w + x:w
      y ~ m + x
    ",
    pop_es = "
      m ~ x: 0.3
      m ~ w: 0.1
      m ~ x:w: 0.2
      y ~ m: 0.4
      y ~ x: 0.05
    ",
    n = 250, test = "index", x = "x", m = "m", y = "y", w = "w",
    ci_draws = validation_ci_draws(), nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("PROCESS model 7: Type I error is near alpha when the XW->M path is 0", {
  skip_unless_full_validation()
  # The index is a3 * b. With a3 = 0 and a large b, the test of the index
  # should approach alpha (with both zero it is far below alpha).
  spec <- moderated_mediation_spec(
    "process_7", process_7_paths(0.3, 0.2, 0, 0.5, 0),
    n = 300, seed = 401
  )
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
