# Validation: first-stage moderated mediation (PROCESS model 7):
# M ~ X + W + XW, Y ~ M + X; target = index of moderated mediation (a3 * b).
# Backend: power4mome. Build guide section 6:
#   1. analytic agreement: none (no closed-form power for confidence-
#      interval tests of the index)
#   2. published examples: power4mome's Quick Template for this model;
#      Donnelly, Jorgensen & Rudolph (2023), not usable yet (see below)
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
  # Source: power4mome article "Quick Template: Simple Moderated Mediation
  #   with Observed Variables: a-Path Moderated" (pkgdown "Articles" at
  #   https://sfcheung.r-universe.dev/power4mome). Transcribe the population
  #   values from its pop_es (convert the "s"/"m"/"l" labels using the
  #   values the article states), n, the test used (index of moderated
  #   mediation), alpha, nrep and R, and the reported rejection rate.
  # power4mome version that built the website: TODO (Joel).
  # Date read: TODO (Joel).
  #   The article's output is regenerated each time the website is rebuilt,
  #   so the reported numbers can change between versions; record both.
  # Test method: the templates leave test_method unset, so power4mome may
  #   have used the asymmetric p-value (Boos and Zhang) rather than the
  #   confidence-interval test powerkit uses (power4mome switches to it for
  #   some numbers of draws R: 39, 79, ..., 359; docs/conventions.md,
  #   Departure 8). Open question to Shu Fai Cheung (docs/decisions.md).
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

test_that("PROCESS model 7: matches Donnelly, Jorgensen & Rudolph (2023) (published)", {
  skip_unless_full_validation()
  # Source: Donnelly, Jorgensen & Rudolph (2023), Behavior Research
  #   Methods, 55(7), 3892-3909, doi:10.3758/s13428-022-01996-0 (the
  #   "simsem tutorial" in earlier versions of these tests).
  # Why this stays TODO: it can't be used yet.
  #   * Its X and W are binary, and powerkit doesn't offer a binary X or W
  #     yet (docs/build-guide.md, section 8, proposed next phase).
  #   * It reports no power for the index of moderated mediation, only for
  #     a conditional indirect effect, at a level of W it doesn't state.
  #   It becomes usable when binary X and W are supported (and then only
  #   for a conditional indirect effect, if powerkit offers that target).
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
  # Source: power4mome's search for the sample size for a target power
  #   (n_region_from_power() or n_from_power()), as shown in the Quick
  #   Template for this model ("Quick Template: Simple Moderated Mediation
  #   with Observed Variables: a-Path Moderated"). Joel: confirm the
  #   article. Transcribe the population values, alpha, target power and
  #   the sample size (or region) it reports.
  # power4mome version that built the website: TODO (Joel).
  # Date read: TODO (Joel).
  #   The article's output is regenerated each time the website is rebuilt,
  #   so the reported numbers can change between versions; record both.
  # Test method: the templates leave test_method unset, so power4mome may
  #   have used the asymmetric p-value (Boos and Zhang) rather than the
  #   confidence-interval test powerkit uses (power4mome switches to it for
  #   some numbers of draws R: 39, 79, ..., 359; docs/conventions.md,
  #   Departure 8). Open question to Shu Fai Cheung (docs/decisions.md).
  # Published N as a point or a range: give exactly one of published_n and
  #   published_n_range, and set the other to NULL. n_region_from_power()
  #   reports a region (e.g. 300 to 347), not a single n: give it as a
  #   range, c(lower, upper). A range passes if it overlaps powerkit's
  #   interval for the required n (a lenient criterion; docs/decisions.md),
  #   and a narrow overlap is reported with a warning.
  a1 <- TODO_PUBLISHED_VALUE
  a2 <- TODO_PUBLISHED_VALUE
  a3 <- TODO_PUBLISHED_VALUE
  b <- TODO_PUBLISHED_VALUE
  c_prime <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  target_power <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE # a single n, or NULL if a region is given
  published_n_range <- TODO_PUBLISHED_VALUE # c(lower, upper), or NULL if a single n is given
  skip_if_todo(a1, a2, a3, b, c_prime, alpha, target_power, published_n, published_n_range)

  spec <- moderated_mediation_spec(
    "process_7", process_7_paths(a1, a2, a3, b, c_prime),
    seed = 203, alpha = alpha, target_power = target_power
  )
  expect_n_near(engine_n_required(spec), published_n_value(published_n, published_n_range))
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
