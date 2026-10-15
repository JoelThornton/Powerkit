# Validation: simple mediation (PROCESS model 4, one mediator).
# Backend: power4mome. Build guide section 6:
#   1. analytic agreement: none (no closed-form power for confidence-
#      interval tests of an indirect effect)
#   2. published examples: power4mome's Quick Template for simple
#      mediation. (Schoemann, Boulton & Short's (2017) example is a sanity
#      check recorded in docs/decisions.md, not a test.)
#   3. direct-call agreement with power4mome
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# 2. Published examples ------------------------------------------------------------

test_that("simple mediation: matches the power4mome Quick Template (published)", {
  skip_unless_full_validation()
  # Source: power4mome article "Quick Template: Simple Mediation with
  #   Observed Variables" (pkgdown "Articles" at
  #   https://sfcheung.r-universe.dev/power4mome). Transcribe the population
  #   values from its pop_es (convert the "s"/"m"/"l" labels using the
  #   values the article states): a (X->M), b (M->Y) and c' (X->Y); n,
  #   alpha (or CI level), nrep and R, and the reported rejection rate for
  #   the indirect effect.
  # power4mome version that built the website: TODO (maintainer).
  # Date read: TODO (maintainer).
  #   The article's output is regenerated each time the website is rebuilt,
  #   so the reported numbers can change between versions; record both.
  # Test method: the templates leave test_method unset but use R = 1000
  #   draws. Boos and Zhang's p-value rule only switches on for R in 39,
  #   79, ..., 359 (docs/conventions.md, Departure 8), so the templates used
  #   the confidence-interval test, the same test powerkit uses.
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
