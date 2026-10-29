# Validation: moderated mediation with two parallel mediators (PROCESS
# models 7 and 14): the index of moderated mediation through one chosen
# mediator. Backend: power4mome. Build guide section 6:
#   1. analytic agreement: none (no closed-form power for confidence-
#      interval tests of the index)
#   2. published examples: placeholders below, for the maintainer to choose
#      a source and transcribe
#   3. direct-call agreement with power4mome
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

parallel_modmed_spec <- function(template, paths, path, seed, n = NULL, residual = 0.3,
                                 alpha = 0.05, target_power = NULL) {
  v <- validation_variable
  validation_spec(
    design = "moderated_mediation",
    template = template,
    variables = list(
      X = v("continuous", "Predictor"), W = v("continuous", "Moderator"),
      M1 = v("continuous", "First mediator"), M2 = v("continuous", "Second mediator"),
      Y = v("continuous", "Outcome")
    ),
    population = list(metric = "standardised", paths = paths, residual_correlations = list("M1<->M2" = residual)),
    target_test = list(effect = "index_of_moderated_mediation", path = path, method = "monte_carlo_ci", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = list(ci_draws = validation_ci_draws())
  )
}

first_stage_paths <- function(a3_m1 = -0.15) {
  list(
    "X->M1" = 0.3, "W->M1" = -0.1, "XW->M1" = a3_m1, "X->M2" = 0.2, "W->M2" = -0.1, "XW->M2" = -0.1,
    "M1->Y" = 0.4, "M2->Y" = 0.2, "X->Y" = 0.05
  )
}

# 2. Published example -----------------------------------------------------------

test_that("moderated mediation, two mediators: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for a PROCESS model 7 or 14 with two parallel mediators and
  #   records its section and page here).
  template <- TODO_PUBLISHED_VALUE # "process_7" or "process_14"
  paths <- TODO_PUBLISHED_VALUE # every standardised path, as a list
  residual <- TODO_PUBLISHED_VALUE # the mediators' residual correlation
  path <- TODO_PUBLISHED_VALUE # the mediator whose index is tested, "X->Mk->Y"
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # replications behind the published power
  skip_if_todo(template, paths, residual, path, n, published_power, reference_nrep)
  spec <- parallel_modmed_spec(template, paths, path, seed = 501, n = n, residual = residual)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct call -------------------------------------------------------------------

test_that("moderated mediation, two mediators: powerkit matches a direct power4mome call", {
  skip_unless_full_validation()
  skip_if_not_installed("power4mome")
  spec <- parallel_modmed_spec("process_7", first_stage_paths(), "X->M1->Y", seed = 601, n = 250)
  direct <- direct_power4mome(
    model = "
      m1 ~ x + w + x:w
      m2 ~ x + w + x:w
      y ~ m1 + m2 + x
      m1 ~~ m2
    ",
    # In a model with a product term, power4mome reads the residual
    # covariance as a correlation (engine/R/backend-power4mome.R).
    pop_es = "
      m1 ~ x: 0.3
      m1 ~ w: -0.1
      m1 ~ x:w: -0.15
      m2 ~ x: 0.2
      m2 ~ w: -0.1
      m2 ~ x:w: -0.1
      y ~ m1: 0.4
      y ~ m2: 0.2
      y ~ x: 0.05
      m1 ~~ m2: 0.3
    ",
    n = 250, test = "index", x = "x", m = "m1", y = "y", w = "w",
    ci_draws = validation_ci_draws(), nrep = validation_nrep(), seed = 601
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("moderated mediation, two mediators: Type I error is near alpha when XW->M1 is 0", {
  skip_unless_full_validation()
  # The index through M1 is a3 * b1. With a3 = 0 and a large b1, the test
  # should approach alpha; M2's own interaction doesn't enter it.
  spec <- parallel_modmed_spec("process_7", first_stage_paths(a3_m1 = 0), "X->M1->Y", seed = 701, n = 300)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
