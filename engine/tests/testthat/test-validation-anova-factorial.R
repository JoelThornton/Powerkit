# Validation: two-factor ANOVA with both factors between participants
# (beyond 2 x 2) or both within participants (2 x 2 or larger; sphericity
# assumed). Backend: Superpower. Build guide section 6:
#   1. analytic agreement with Superpower::ANOVA_exact()
#   2. published examples (placeholders for the maintainer)
#   3. direct-call agreement with Superpower::ANOVA_power()
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `means` is a matrix (rows = levels of A, columns = levels of B); `n` is
# the total number of participants (split equally across the cells when
# both factors are between participants); `r` is the correlation between
# any two cells when both are within participants.
factorial_spec <- function(within, means, sd, effect, seed, r = NULL, n = NULL, alpha = 0.05,
                           target_power = NULL, method = NULL) {
  type <- if (within) "within_factor" else "between_factor"
  population <- list(
    metric = "raw",
    means = lapply(seq_len(nrow(means)), function(i) as.list(means[i, ])),
    sd = sd
  )
  if (within) population$r <- r
  validation_spec(
    design = "factorial_anova",
    template = if (within) "factorial_within" else "factorial_between",
    variables = list(
      A = validation_variable(type, "A", levels = as.list(paste0("a", seq_len(nrow(means))))),
      B = validation_variable(type, "B", levels = as.list(paste0("b", seq_len(ncol(means))))),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = population,
    target_test = list(effect = effect, method = "anova_f", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = if (is.null(method)) list() else list(method = method)
  )
}

design_string <- function(means, within) {
  sprintf(if (within) "%dw*%dw" else "%db*%db", nrow(means), ncol(means))
}

# 1. Analytic agreement ----------------------------------------------------------

for (method in c("exact", "simulation")) {
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    test_that(paste0("within 2 x 3, ", effect, ", ", method, ": power matches Superpower::ANOVA_exact (analytic)"), {
      skip_unless_full_validation()
      skip_if_not_installed("Superpower")
      means <- matrix(c(0, 0.3, 0.5, 0, 0.1, 0.2), nrow = 2, byrow = TRUE)
      spec <- factorial_spec(TRUE, means, sd = 1, r = 0.5, n = 30, effect = effect, seed = 101, method = method)
      reference <- direct_superpower_exact(
        design_string(means, TRUE), n = 30, means = means, sd = 1, r = 0.5, effect = effect, alpha = 0.05, seed = 101
      )
      expect_power_near(engine_power(spec), reference$power)
    })
  }
}

test_that("within 2 x 2, interaction: power matches Superpower::ANOVA_exact (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("Superpower")
  means <- matrix(c(10, 12, 10, 10.5), nrow = 2, byrow = TRUE)
  spec <- factorial_spec(TRUE, means, sd = 4, r = 0.6, n = 40, effect = "interaction", seed = 102)
  reference <- direct_superpower_exact(
    design_string(means, TRUE), n = 40, means = means, sd = 4, r = 0.6, effect = "interaction", alpha = 0.05, seed = 102
  )
  expect_power_near(engine_power(spec), reference$power)
})

for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
  test_that(paste0("between 3 x 3, ", effect, ": power matches Superpower::ANOVA_exact (analytic)"), {
    skip_unless_full_validation()
    skip_if_not_installed("Superpower")
    means <- matrix(c(0, 0.2, 0.4, 0, 0.1, 0.2, 0, 0, 0), nrow = 3, byrow = TRUE)
    spec <- factorial_spec(FALSE, means, sd = 1, n = 270, effect = effect, seed = 103)
    reference <- direct_superpower_exact(
      design_string(means, FALSE), n = 30, means = means, sd = 1, effect = effect, alpha = 0.05, seed = 103
    )
    expect_power_near(engine_power(spec), reference$power)
  })
}

# 2. Published examples ------------------------------------------------------------

test_that("two-factor within design: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer, for example a two-factor
  #   within-participants design in the Superpower book (Caldwell, Lakens,
  #   DeBruine, Love & Aust), or G*Power's "ANOVA: Repeated measures,
  #   within factors" (its manual has no section on it). Transcribe the
  #   cell means (rows = levels of A, columns = levels of B), the SD, the
  #   correlation r, the number of participants, alpha, which effect, and
  #   the power reported (as a proportion). If the reported power comes
  #   from a simulation, also transcribe its nsims.
  mu <- TODO_PUBLISHED_VALUE # cell means, row by row
  levels_A <- TODO_PUBLISHED_VALUE
  sd <- TODO_PUBLISHED_VALUE
  r <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  effect <- TODO_PUBLISHED_VALUE # "main_effect_A", "main_effect_B" or "interaction"
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # nsims behind the published power, or NULL if exact
  skip_if_todo(mu, levels_A, sd, r, n, alpha, effect, published_power, reference_nrep)

  means <- matrix(mu, nrow = levels_A, byrow = TRUE)
  spec <- factorial_spec(TRUE, means, sd = sd, r = r, n = n, effect = effect, seed = 201, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

test_that("two-factor between design beyond 2 x 2: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer, for example G*Power's manual,
  #   "ANOVA: Fixed effects, special, main effects and interactions", or a
  #   2 x 3 example in the Superpower book. Transcribe the cell means (rows =
  #   levels of A, columns = levels of B), the SD, the participants per
  #   cell, alpha, which effect, and the power reported (as a proportion).
  mu <- TODO_PUBLISHED_VALUE # cell means, row by row
  levels_A <- TODO_PUBLISHED_VALUE
  sd <- TODO_PUBLISHED_VALUE
  n_per_cell <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  effect <- TODO_PUBLISHED_VALUE # "main_effect_A", "main_effect_B" or "interaction"
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # nsims behind the published power, or NULL if exact
  skip_if_todo(mu, levels_A, sd, n_per_cell, alpha, effect, published_power, reference_nrep)

  means <- matrix(mu, nrow = levels_A, byrow = TRUE)
  spec <- factorial_spec(FALSE, means, sd = sd, n = length(mu) * n_per_cell, effect = effect, seed = 202, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("within 2 x 3, interaction: powerkit matches a direct Superpower::ANOVA_power call", {
  skip_unless_full_validation()
  skip_if_not_installed("Superpower")
  means <- matrix(c(400, 410, 420, 430, 450, 470), nrow = 2, byrow = TRUE)
  spec <- factorial_spec(TRUE, means, sd = 80, r = 0.6, n = 40, effect = "interaction", seed = 301, method = "simulation")
  direct <- direct_superpower_simulation(
    design_string(means, TRUE), n = 40, means = means, sd = 80, r = 0.6, effect = "interaction",
    alpha = 0.05, nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("within 2 x 3: Type I error for the interaction is near alpha (simulation)", {
  skip_unless_full_validation()
  # Parallel lines: both main effects, no interaction.
  means <- matrix(c(0, 0.3, 0.5, 0.4, 0.7, 0.9), nrow = 2, byrow = TRUE)
  spec <- factorial_spec(TRUE, means, sd = 1, r = 0.5, n = 30, effect = "interaction", seed = 401, method = "simulation")
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
