# Validation: one-way repeated-measures ANOVA (one within-participants factor
# with three or more levels; omnibus F test, sphericity assumed).
# Backend: Superpower. Build guide section 6:
#   1. analytic agreement with Superpower::ANOVA_exact()
#   2. published examples (placeholders for the maintainer)
#   3. direct-call agreement with Superpower::ANOVA_power()
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `means` has one value per condition; `n` is the number of participants
# (everyone is in every condition); `r` is the correlation between any two
# conditions within a participant.
within_spec <- function(means, sd, r, seed, n = NULL, alpha = 0.05,
                        target_power = NULL, method = NULL) {
  validation_spec(
    design = "factorial_anova",
    template = "oneway_within",
    variables = list(
      A = validation_variable("within_factor", "Condition", levels = as.list(paste0("a", seq_along(means)))),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = list(metric = "raw", means = as.list(means), sd = sd, r = r),
    target_test = list(effect = "main_effect_A", method = "anova_f", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = if (is.null(method)) list() else list(method = method)
  )
}

# 1. Analytic agreement ----------------------------------------------------------
#
# Each test runs with the default exact method (powerkit equals a direct
# ANOVA_exact() call) and with method = "simulation" (simulated power
# matches the exact answer within the 99.9% Monte Carlo interval).

for (method in c("exact", "simulation")) {
  test_that(paste0("one-way within, three conditions, ", method, ": power matches Superpower::ANOVA_exact (analytic)"), {
    skip_unless_full_validation()
    skip_if_not_installed("Superpower")
    means <- c(0, 0.2, 0.4)
    spec <- within_spec(means, sd = 1, r = 0.5, n = 30, seed = 101, method = method)
    reference <- direct_superpower_exact(
      "3w", n = 30, means = means, sd = 1, r = 0.5, effect = "main_effect_A", alpha = 0.05, seed = 101
    )
    expect_power_near(engine_power(spec), reference$power)
  })

  test_that(paste0("one-way within, four conditions and a low correlation, ", method, ": matches ANOVA_exact (analytic)"), {
    skip_unless_full_validation()
    skip_if_not_installed("Superpower")
    means <- c(10, 11, 11, 13)
    spec <- within_spec(means, sd = 5, r = 0.2, n = 40, seed = 102, method = method)
    reference <- direct_superpower_exact(
      "4w", n = 40, means = means, sd = 5, r = 0.2, effect = "main_effect_A", alpha = 0.05, seed = 102
    )
    expect_power_near(engine_power(spec), reference$power)
  })
}

# 2. Published examples ------------------------------------------------------------

test_that("one-way within: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer. Candidates: the Superpower
  #   package's introductory vignette, its one-factor within-participants
  #   example (which it also enters into G*Power's "ANOVA: Repeated
  #   measures, within factors"), or the Superpower book's chapter on
  #   within-participants designs. Transcribe the means, the SD, the
  #   correlation r, the number of participants, alpha and the power
  #   reported for the factor (as a proportion). If the reported power comes
  #   from a simulation, also transcribe its nsims. G*Power's effect-size
  #   setting ("As in SPSS" or not) matters only if f is entered; record it
  #   if the source gives it.
  mu <- TODO_PUBLISHED_VALUE # one mean per condition
  sd <- TODO_PUBLISHED_VALUE
  r <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE # participants (each in every condition)
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # nsims behind the published power, or NULL if exact
  skip_if_todo(mu, sd, r, n, alpha, published_power, reference_nrep)

  spec <- within_spec(mu, sd = sd, r = r, n = n, seed = 201, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("one-way within: powerkit matches a direct Superpower::ANOVA_power call", {
  skip_unless_full_validation()
  skip_if_not_installed("Superpower")
  means <- c(20, 21, 23)
  spec <- within_spec(means, sd = 6, r = 0.6, n = 40, seed = 301, method = "simulation")
  direct <- direct_superpower_simulation(
    "3w", n = 40, means = means, sd = 6, r = 0.6, effect = "main_effect_A",
    alpha = 0.05, nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("one-way within: Type I error is near alpha at a high correlation (simulation)", {
  skip_unless_full_validation()
  # Equal means: no effect. The high correlation stresses the
  # within-participant error term.
  spec <- within_spec(c(5, 5, 5, 5), sd = 2, r = 0.9, n = 30, seed = 401, method = "simulation")
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
