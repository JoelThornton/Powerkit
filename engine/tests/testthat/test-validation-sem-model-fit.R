# Validation: structural equation model fit, the chi-square test of exact
# fit with misfit given as an RMSEA. Backend: semPower's semPower.postHoc()
# by formula (noncentrality (N - 1) * RMSEA^2 * df). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-sempower.R) check
#      powerkit against semPower called directly, against the noncentral
#      chi-square written out in base R, and a CFA's degrees of freedom
#      against lavaan's own count
#   2. published examples: below, to be transcribed by the maintainer
#   3. direct-call agreement with a simulation: not yet (no simulation
#      option)
#   4. Type I error: power falls to alpha as the RMSEA shrinks towards 0
#      (unit tests; semPower refuses an RMSEA of 0)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

sem_fit_validation_spec <- function(rmsea, df, alpha, seed, n = NULL, target_power = NULL) {
  validation_spec(
    design = "sem",
    template = "model_fit",
    variables = stats::setNames(list(), character(0)), # an empty set of named fields
    population = list(metric = "rmsea", rmsea = rmsea, df = df),
    target_test = list(effect = "model_fit", method = "chi_square_exact_fit", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 2. Published examples -------------------------------------------------------
#
# Source: to be chosen by the maintainer. Candidates: the worked examples
#   in semPower's method paper (Moshagen & Bader, 2024, Behavior Research
#   Methods, doi 10.3758/s13428-023-02254-7) and its tutorial (Jobst,
#   Bader & Moshagen, 2023, Psychological Methods, doi 10.1037/met0000423;
#   both named in semPower 2.2.0's README), or a published table of power
#   for the test of exact fit by RMSEA and df. Record the source, section
#   and page here when transcribing.
# Conventions to check against the source before transcribing:
#   * The test is of EXACT fit (the null hypothesis is RMSEA = 0), not of
#     close fit (RMSEA no more than 0.05): a table for the test of close
#     fit gives different numbers and is not a check of this design.
#   * The noncentrality uses N - 1 (semPower's getNCP()); a source using N
#     gives a slightly different answer.
#   * powerkit's n is the total number of participants analysed.

test_that("SEM model fit: power matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page).
  rmsea <- TODO_PUBLISHED_VALUE # population RMSEA of the misfit
  df <- TODO_PUBLISHED_VALUE # the model's degrees of freedom
  n <- TODO_PUBLISHED_VALUE # sample size
  alpha <- TODO_PUBLISHED_VALUE # significance level
  published_power <- TODO_PUBLISHED_VALUE # power as printed
  skip_if_todo(rmsea, df, n, alpha, published_power)

  spec <- sem_fit_validation_spec(rmsea, df, alpha, seed = 321, n = n)
  expect_power_exact(engine_power(spec), published_power)
})

test_that("SEM model fit: required N matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page).
  rmsea <- TODO_PUBLISHED_VALUE # population RMSEA of the misfit
  df <- TODO_PUBLISHED_VALUE # the model's degrees of freedom
  alpha <- TODO_PUBLISHED_VALUE # significance level
  target_power <- TODO_PUBLISHED_VALUE # target power
  published_n <- TODO_PUBLISHED_VALUE # required sample size as printed
  skip_if_todo(rmsea, df, alpha, target_power, published_n)

  spec <- sem_fit_validation_spec(rmsea, df, alpha, seed = 322, target_power = target_power)
  expect_equal(engine_n_required(spec)$n, published_n)
})

# 1. Direct-call agreement ----------------------------------------------------

test_that("SEM model fit: power and N match semPower called directly (direct call)", {
  skip_unless_full_validation()
  spec <- sem_fit_validation_spec(0.05, 200, 0.05, seed = 323, n = 150)
  direct <- semPower::semPower.postHoc(
    effect = 0.05, effect.measure = "RMSEA", alpha = 0.05, N = 150, df = 200
  )$power
  expect_equal(engine_power(spec), direct, tolerance = 1e-10)
  spec <- sem_fit_validation_spec(0.05, 200, 0.05, seed = 324, target_power = 0.95)
  direct_n <- semPower::semPower.aPriori(
    effect = 0.05, effect.measure = "RMSEA", alpha = 0.05, power = 0.95, df = 200
  )$requiredN
  expect_equal(engine_n_required(spec)$n, direct_n)
})
