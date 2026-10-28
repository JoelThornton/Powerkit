# Validation: mixed ANOVA beyond 2 x 2 (one between-participants factor by
# one within-participants factor, at least one with three or more levels;
# sphericity assumed). Backend: Superpower. Build guide section 6:
#   1. analytic agreement with Superpower::ANOVA_exact()
#   2. published examples (placeholders for the maintainer)
#   3. direct-call agreement with Superpower::ANOVA_power()
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `means` is a matrix (rows = levels of A, between; columns = levels of B,
# within); `n` is the total number of participants (equal groups); `r` is
# the correlation between any two levels of B.
larger_mixed_spec <- function(means, sd, r, effect, seed, n = NULL, alpha = 0.05,
                              target_power = NULL, method = NULL) {
  validation_spec(
    design = "factorial_anova",
    template = "mixed",
    variables = list(
      A = validation_variable("between_factor", "Group", levels = as.list(paste0("a", seq_len(nrow(means))))),
      B = validation_variable("within_factor", "Time", levels = as.list(paste0("b", seq_len(ncol(means))))),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = list(
      metric = "raw",
      means = lapply(seq_len(nrow(means)), function(i) as.list(means[i, ])),
      sd = sd, r = r
    ),
    target_test = list(effect = effect, method = "anova_f", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = if (is.null(method)) list() else list(method = method)
  )
}

design_string <- function(means) sprintf("%db*%dw", nrow(means), ncol(means))

# 1. Analytic agreement ----------------------------------------------------------

for (method in c("exact", "simulation")) {
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    test_that(paste0("mixed 2 x 3, ", effect, ", ", method, ": power matches Superpower::ANOVA_exact (analytic)"), {
      skip_unless_full_validation()
      skip_if_not_installed("Superpower")
      means <- matrix(c(0, 0.3, 0.5, 0, 0.1, 0.2), nrow = 2, byrow = TRUE)
      spec <- larger_mixed_spec(means, sd = 1, r = 0.5, n = 60, effect = effect, seed = 101, method = method)
      reference <- direct_superpower_exact(
        design_string(means), n = 30, means = means, sd = 1, r = 0.5, effect = effect, alpha = 0.05, seed = 101
      )
      expect_power_near(engine_power(spec), reference$power)
    })
  }
}

test_that("mixed 3 x 2, interaction: power matches Superpower::ANOVA_exact (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("Superpower")
  means <- matrix(c(10, 13, 10, 12, 10, 10.5), nrow = 3, byrow = TRUE)
  spec <- larger_mixed_spec(means, sd = 4, r = 0.6, n = 90, effect = "interaction", seed = 102)
  reference <- direct_superpower_exact(
    design_string(means), n = 30, means = means, sd = 4, r = 0.6, effect = "interaction", alpha = 0.05, seed = 102
  )
  expect_power_near(engine_power(spec), reference$power)
})

# 2. Published examples ------------------------------------------------------------

test_that("mixed beyond 2 x 2: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer, for example a group by time
  #   design with three or more timepoints in the Superpower book's chapter
  #   on mixed designs, or G*Power's "ANOVA: Repeated measures,
  #   within-between interaction" (its manual has no section on it).
  #   Transcribe the cell means (rows = groups, between; columns = levels
  #   of the within factor), the SD, the correlation r, the participants
  #   per group, alpha, which effect, and the power reported (as a
  #   proportion). If the reported power comes from a simulation, also
  #   transcribe its nsims.
  mu <- TODO_PUBLISHED_VALUE # cell means, row by row
  n_groups <- TODO_PUBLISHED_VALUE # levels of the between factor
  sd <- TODO_PUBLISHED_VALUE
  r <- TODO_PUBLISHED_VALUE
  n_per_group <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  effect <- TODO_PUBLISHED_VALUE # "main_effect_A", "main_effect_B" or "interaction"
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # nsims behind the published power, or NULL if exact
  skip_if_todo(mu, n_groups, sd, r, n_per_group, alpha, effect, published_power, reference_nrep)

  means <- matrix(mu, nrow = n_groups, byrow = TRUE)
  spec <- larger_mixed_spec(means, sd = sd, r = r, n = n_groups * n_per_group, effect = effect, seed = 201, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("mixed 2 x 4, interaction: powerkit matches a direct Superpower::ANOVA_power call", {
  skip_unless_full_validation()
  skip_if_not_installed("Superpower")
  means <- matrix(c(20, 18, 17, 16, 20, 19.5, 19, 19), nrow = 2, byrow = TRUE)
  spec <- larger_mixed_spec(means, sd = 6, r = 0.6, n = 80, effect = "interaction", seed = 301, method = "simulation")
  direct <- direct_superpower_simulation(
    design_string(means), n = 40, means = means, sd = 6, r = 0.6, effect = "interaction",
    alpha = 0.05, nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("mixed 2 x 3: Type I error for the interaction is near alpha (simulation)", {
  skip_unless_full_validation()
  # Parallel lines: both main effects, no interaction.
  means <- matrix(c(0, 0.3, 0.5, 0.4, 0.7, 0.9), nrow = 2, byrow = TRUE)
  spec <- larger_mixed_spec(means, sd = 1, r = 0.8, n = 60, effect = "interaction", seed = 401, method = "simulation")
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
