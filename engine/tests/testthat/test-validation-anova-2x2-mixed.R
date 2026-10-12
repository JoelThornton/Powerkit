# Validation: 2x2 mixed ANOVA (A between participants, B within).
# Backend: Superpower. Build guide section 6:
#   1. analytic agreement with Superpower::ANOVA_exact()
#   2. published examples: Superpower vignette and paper
#   3. direct-call agreement with Superpower::ANOVA_power()
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `means` is a 2x2 matrix (rows = levels of A, between; columns = levels of
# B, within); `n` is the total number of participants (2 equal groups);
# `r` is the correlation between the two repeated measures.
mixed_spec <- function(means, sd, r, effect, seed, n = NULL, alpha = 0.05,
                       target_power = NULL,
                       method = NULL) {
  validation_spec(
    design = "factorial_anova",
    template = "2x2_mixed",
    variables = list(
      A = validation_variable("between_factor", "Group", levels = list("a1", "a2")),
      B = validation_variable("within_factor", "Time", levels = list("b1", "b2")),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = list(metric = "raw", means = means, sd = sd, r = r),
    target_test = list(effect = effect, method = "anova_f", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = if (is.null(method)) list() else list(method = method)
  )
}

# 1. Analytic agreement ----------------------------------------------------------
#
# Each test runs twice: with the default exact method (checks the
# translation: powerkit equals a direct ANOVA_exact() call), and with
# method = "simulation" (checks that simulated power matches the exact
# answer within the 99.9% Monte Carlo interval).

for (method in c("exact", "simulation")) {
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    test_that(paste0("2x2 mixed, ", effect, ", ", method, ": power matches Superpower::ANOVA_exact (analytic)"), {
      skip_unless_full_validation()
      skip_if_not_installed("Superpower")
      means <- matrix(c(0, 0.2, 0.1, 0.6), nrow = 2, byrow = TRUE)
      spec <- mixed_spec(means, sd = 1, r = 0.5, n = 80, effect = effect, seed = 101, method = method)
      reference <- direct_superpower_exact(
        "2b*2w", n = 40, means = means, sd = 1, r = 0.5, effect = effect, alpha = 0.05, seed = 101
      )
      expect_power_near(engine_power(spec), reference$power)
    })
  }

  test_that(paste0("2x2 mixed with a negative repeated-measures correlation, ", method, ": matches ANOVA_exact (analytic)"), {
    skip_unless_full_validation()
    skip_if_not_installed("Superpower")
    means <- matrix(c(0, 0.2, 0.1, 0.6), nrow = 2, byrow = TRUE)
    spec <- mixed_spec(means, sd = 1, r = -0.3, n = 120, effect = "interaction", seed = 102, method = method)
    reference <- direct_superpower_exact(
      "2b*2w", n = 60, means = means, sd = 1, r = -0.3, effect = "interaction", alpha = 0.05,
      seed = 102
    )
    expect_power_near(engine_power(spec), reference$power)
  })
}

# 2. Published examples ------------------------------------------------------------

test_that("2x2 mixed: matches the Superpower vignette example (published)", {
  skip_unless_full_validation()
  # Source: Superpower package vignette "More ANOVA designs"
  #   (vignettes/more_anova_designs.Rmd), section "2x2 ANOVA, within-between
  #   design". Transcribe the cell means in the vignette's mu order (a1_b1,
  #   a1_b2, a2_b1, a2_b2; check which factor is within: powerkit's B is the
  #   within factor), the SD, the correlation r, n per between group, alpha,
  #   and the power reported for the interaction (as a proportion). If the
  #   reported power comes from a simulation, also transcribe its nsims.
  mu <- c(-0.25, 0.25, 0.25, -0.25) # c(a1_b1, a1_b2, a2_b1, a2_b2)
  sd <- 1
  r <- 0.5
  n_per_group <- 23
  alpha <- 0.05
  published_power <- 0.9125 # interaction (a:b)
  reference_nrep <- NULL # nsims behind the published power, or NULL if exact
  skip_if_todo(mu, sd, r, n_per_group, alpha, published_power, reference_nrep)

  means <- matrix(mu, nrow = 2, byrow = TRUE)
  spec <- mixed_spec(means, sd = sd, r = r, n = 2 * n_per_group, effect = "interaction", seed = 201, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

test_that("2x2 mixed: matches the Superpower paper example (published)", {
  skip_unless_full_validation()
  # Source: Caldwell, Lakens, Parlett-Pelleriti, Prochilo & Aust, "Power
  #   Analysis with Superpower" (book), chapter "Mixed ANOVA", section 5.1,
  #   Table 5.4. (Lakens & Caldwell (2021) has no 2x2 mixed example.)
  mu <- c(-0.25, 0.25, 0.25, -0.25) # c(a1_b1, a1_b2, a2_b1, a2_b2)
  sd <- 1
  r <- 0.7
  n_per_group <- 23
  alpha <- 0.05
  effect <- "interaction" # "main_effect_A", "main_effect_B" or "interaction"
  published_power <- 0.9898467 # printed as 98.98467%
  reference_nrep <- NULL # nsims behind the published power, or NULL if exact
  skip_if_todo(mu, sd, r, n_per_group, alpha, effect, published_power, reference_nrep)

  means <- matrix(mu, nrow = 2, byrow = TRUE)
  spec <- mixed_spec(means, sd = sd, r = r, n = 2 * n_per_group, effect = effect, seed = 202, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct-call agreement -----------------------------------------------------------

for (effect in c("main_effect_B", "interaction")) {
  test_that(paste0("2x2 mixed, ", effect, ": powerkit matches a direct Superpower::ANOVA_power call"), {
    skip_unless_full_validation()
    skip_if_not_installed("Superpower")
    means <- matrix(c(20, 20, 20, 23), nrow = 2, byrow = TRUE)
    spec <- mixed_spec(means, sd = 6, r = 0.6, n = 80, effect = effect, seed = 301, method = "simulation")
    direct <- direct_superpower_simulation(
      "2b*2w", n = 40, means = means, sd = 6, r = 0.6, effect = effect,
      alpha = 0.05, nrep = validation_nrep(), seed = 301
    )
    expect_power_agrees(engine_power(spec), direct)
  })
}

# 4. Type I error ------------------------------------------------------------------

test_that("2x2 mixed: Type I error for the interaction is near alpha", {
  skip_unless_full_validation()
  # Interaction contrast 0 - 0.4 - 0.2 + 0.6 = 0; both main effects non-zero.
  means <- matrix(c(0, 0.4, 0.2, 0.6), nrow = 2, byrow = TRUE)
  spec <- mixed_spec(means, sd = 1, r = 0.5, n = 60, effect = "interaction", seed = 401)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("2x2 mixed: Type I error for the within factor is near alpha at high r", {
  skip_unless_full_validation()
  # B (within) has no main effect; the high correlation stresses the
  # within-participant error term.
  means <- matrix(c(0, 0.3, 0.3, 0), nrow = 2, byrow = TRUE)
  spec <- mixed_spec(means, sd = 1, r = 0.9, n = 60, effect = "main_effect_B", seed = 402)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
