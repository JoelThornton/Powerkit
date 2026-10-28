# Validation: two-way ANCOVA (two between-participants factors, adjusting
# for covariates; template factorial_ancova). Backend: pwrss's
# power.f.ancova.shieh() by formula (Shieh's method). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-factorial-ancova.R)
#      check powerkit against pwrss called directly; below, against
#      Superpower's ANCOVA_analytic(), which also uses Shieh's method
#   2. published examples (placeholders for the maintainer)
#   3. direct-call agreement with a simulation: not yet (no simulation
#      option)
#   4. Type I error: an effect of 0 gives alpha by construction (unit
#      tests)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `means` is a matrix of adjusted cell means (rows = levels of A, columns =
# levels of B); `n` is the total number of participants (equal cells).
ancova_spec <- function(means, sd, r2, covariates, effect, alpha, seed, n = NULL, target_power = NULL) {
  v <- validation_variable
  validation_spec(
    design = "factorial_anova",
    template = "factorial_ancova",
    variables = list(
      A = v("between_factor", "A", levels = as.list(paste0("a", seq_len(nrow(means))))),
      B = v("between_factor", "B", levels = as.list(paste0("b", seq_len(ncol(means))))),
      Y = v("continuous", "Outcome")
    ),
    population = list(
      metric = "raw",
      means = lapply(seq_len(nrow(means)), function(i) as.list(means[i, ])),
      sd = sd, r2_covariates = r2, covariates = covariates
    ),
    target_test = list(effect = effect, method = "ancova_f", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 1. Analytic agreement ----------------------------------------------------------

for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
  test_that(paste0("ANCOVA 3 x 2, ", effect, ": power matches Superpower::ANCOVA_analytic (analytic)"), {
    skip_unless_full_validation()
    skip_if_not_installed("Superpower")
    means <- matrix(c(0, 0.2, 0.1, 0.4, 0.2, 0.7), nrow = 3, byrow = TRUE)
    spec <- ancova_spec(means, sd = 1, r2 = 0.25, covariates = 2, effect = effect, alpha = 0.05, seed = 101, n = 150)
    reference <- Superpower::ANCOVA_analytic(
      design = "3b*2b", mu = as.vector(t(means)), n = 25, sd = 1, r2 = 0.25, n_cov = 2, alpha_level = 0.05
    )$main_results
    row <- c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")[[effect]]
    expect_power_exact(engine_power(spec), reference$power[reference$factor == row] / 100)
  })
}

# 2. Published examples ------------------------------------------------------------

test_that("two-way ANCOVA: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer, for example a two-factor example
  #   in Shieh (2020, Psychometrika 85, 101-120, doi:10.1007/s11336-019-09692-3),
  #   whose examples and tables pwrss's help says it reproduces. Transcribe
  #   the adjusted cell means (rows = levels of A, columns = levels of B),
  #   the SD, the covariates' R-squared and their number, the participants
  #   per cell, alpha, which effect, and the power reported (as a
  #   proportion).
  mu <- TODO_PUBLISHED_VALUE # adjusted cell means, row by row
  levels_A <- TODO_PUBLISHED_VALUE
  sd <- TODO_PUBLISHED_VALUE
  r2 <- TODO_PUBLISHED_VALUE
  covariates <- TODO_PUBLISHED_VALUE
  n_per_cell <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  effect <- TODO_PUBLISHED_VALUE # "main_effect_A", "main_effect_B" or "interaction"
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(mu, levels_A, sd, r2, covariates, n_per_cell, alpha, effect, published_power)

  means <- matrix(mu, nrow = levels_A, byrow = TRUE)
  spec <- ancova_spec(means, sd = sd, r2 = r2, covariates = covariates, effect = effect, alpha = alpha,
                      seed = 201, n = length(mu) * n_per_cell)
  expect_power_exact(engine_power(spec), published_power)
})
