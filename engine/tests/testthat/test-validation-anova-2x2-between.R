# Validation: 2x2 between-participants ANOVA, including interaction shapes.
# Backend: Superpower. Build guide section 6:
#   1. analytic agreement with Superpower::ANOVA_exact()
#   2. published examples: Superpower vignette and paper; interaction-shape
#      examples (Sommet et al.)
#   3. direct-call agreement with Superpower::ANOVA_power()
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `means` is a 2x2 matrix (rows = levels of A, columns = levels of B);
# `n` is the total number of participants (4 equal cells).
between_spec <- function(means, sd, effect, seed, n = NULL, alpha = 0.05,
                         target_power = NULL,
                         method = NULL) {
  validation_spec(
    design = "factorial_anova",
    template = "2x2_between",
    variables = list(
      A = validation_variable("between_factor", "Factor A", levels = list("a1", "a2")),
      B = validation_variable("between_factor", "Factor B", levels = list("b1", "b2")),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = list(metric = "raw", means = means, sd = sd),
    target_test = list(effect = effect, method = "anova_f", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = if (is.null(method)) list() else list(method = method)
  )
}

# 1. Analytic agreement ----------------------------------------------------------

for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
  test_that(paste0("2x2 between, ", effect, ": power matches Superpower::ANOVA_exact (analytic)"), {
    skip_unless_full_validation()
    skip_if_not_installed("Superpower")
    means <- matrix(c(0, 0.2, 0.3, 0.8), nrow = 2, byrow = TRUE)
    spec <- between_spec(means, sd = 1, n = 160, effect = effect, seed = 101)
    reference <- direct_superpower_exact("2b*2b", n = 40, means = means, sd = 1, effect = effect, alpha = 0.05, seed = 101)
    expect_power_near(engine_power(spec), reference$power)
  })
}

test_that("2x2 between with unequal cell SDs: power matches Superpower::ANOVA_exact (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("Superpower")
  means <- matrix(c(10, 10, 10, 13), nrow = 2, byrow = TRUE)
  sds <- matrix(c(5, 6, 6, 7), nrow = 2, byrow = TRUE)
  spec <- between_spec(means, sd = sds, n = 200, effect = "interaction", seed = 102)
  reference <- direct_superpower_exact(
    "2b*2b", n = 50, means = means, sd = as.vector(t(sds)),
    effect = "interaction", alpha = 0.05, seed = 102
  )
  expect_power_near(engine_power(spec), reference$power)
})

# 2. Published examples ------------------------------------------------------------

test_that("2x2 between: matches the Superpower vignette example (published)", {
  skip_unless_full_validation()
  # Source: Superpower package vignette "More ANOVA designs"
  #   (vignettes/more_anova_designs.Rmd), section "Two-way ANOVA, between
  #   participants Design". Transcribe the cell means in the vignette's mu
  #   order (a1_b1, a1_b2, a2_b1, a2_b2), the SD, n per cell, alpha, and the
  #   power reported for the interaction (as a proportion: 0.85, not 85).
  #   If the reported power comes from a simulation, also transcribe its
  #   nsims as reference_nrep so its own Monte Carlo error is allowed for.
  mu <- c(1, 0, 0, 1) # c(a1_b1, a1_b2, a2_b1, a2_b2)
  sd <- 2
  n_per_cell <- 40
  alpha <- 0.05
  published_power <- 0.881553371 # interaction (a:b); printed as 88.1553371%
  reference_nrep <- NULL # nsims behind the published power, or NULL if exact
  skip_if_todo(mu, sd, n_per_cell, alpha, published_power, reference_nrep)

  means <- matrix(mu, nrow = 2, byrow = TRUE)
  spec <- between_spec(means, sd = sd, n = 4 * n_per_cell, effect = "interaction", seed = 201, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

test_that("2x2 between: matches the Superpower paper example (published)", {
  skip_unless_full_validation()
  # Source: Lakens & Caldwell (2021), "Simulation-based power analysis for
  #   factorial analysis of variance designs", Advances in Methods and
  #   Practices in Psychological Science, 4(1). Use the paper's 2x2
  #   between-participants example (locate the section/figure; if the paper
  #   has none, use an example from the Superpower book by Caldwell et al.
  #   and update this comment). Transcribe as for the vignette test above.
  mu <- c(1, 0, 0, 0) # c(a1_b1, a1_b2, a2_b1, a2_b2)
  sd <- 2
  n_per_cell <- 80
  alpha <- 0.05
  effect <- "interaction" # "main_effect_A", "main_effect_B" or "interaction"
  published_power <- 0.6062
  reference_nrep <- NULL # nsims behind the published power, or NULL if exact
  skip_if_todo(mu, sd, n_per_cell, alpha, effect, published_power, reference_nrep)

  means <- matrix(mu, nrow = 2, byrow = TRUE)
  spec <- between_spec(means, sd = sd, n = 4 * n_per_cell, effect = effect, seed = 202, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# Sommet et al.'s (2023) required N for a 2x2 between-participants
# interaction: N = 4 * (z_alpha + z_beta)^2 / d^2, rounded up, with the z
# values rounded to two decimals as they print them (1.96 and 0.84 at alpha
# .05 and power .80) and d = |interaction contrast| / (2 * SD), i.e. half
# the difference between the two simple effects in SD units. This
# reproduces their Table 2 Ns exactly (256 and 1024 at power .80; 343 and
# 424 for the reversed interaction at .90 and .95). The 8-decimal rounding
# only stops floating-point noise from pushing an exact integer up by one.
sommet_n <- function(means, sd, alpha, power) {
  z <- round(stats::qnorm(1 - alpha / 2), 2) + round(stats::qnorm(power), 2)
  d <- abs((means[1, 1] - means[1, 2]) - (means[2, 1] - means[2, 2])) / (2 * sd)
  ceiling(round(4 * z^2 / d^2, 8))
}

test_that("2x2 crossover interaction: matches Sommet et al. (published)", {
  skip_unless_full_validation()
  # Source: Sommet, Weissman, Cheutin & Elliot (2023), "How many
  #   participants do I need to test an interaction? Conducting an
  #   appropriate power analysis and achieving sufficient power to detect
  #   an interaction", Advances in Methods and Practices in Psychological
  #   Science, 6(3), Table 2, "Reversed" interaction, median slopes: the
  #   required total N for a 2x2 between-participants crossover (fully
  #   reversed) interaction. Their N uses a normal (z) approximation, so it
  #   is below the exact F-test N; see sommet_n().
  mu <- c(-0.175, 0.175, 0.175, -0.175) # c(a1_b1, a1_b2, a2_b1, a2_b2), SD = 1
  alpha <- 0.05
  target_power <- 0.80
  published_n <- 256 # required total N
  exact_n <- 260 # exact F-test N for the same design (maintainer-checked)
  skip_if_todo(mu, alpha, target_power, published_n)

  means <- matrix(mu, nrow = 2, byrow = TRUE)
  spec <- between_spec(
    means, sd = 1, effect = "interaction", seed = 203, alpha = alpha,
    target_power = target_power
  )
  # (a) Their formula, applied to this spec's effect, gives their N: the
  #     spec matches their design.
  expect_equal(sommet_n(means, sd = 1, alpha = alpha, power = target_power), published_n)
  # (b) powerkit's exact required n is the exact F-test N, which is at least
  #     their normal-approximation N.
  n_required <- engine_n_required(spec)
  expect_equal(n_required$n, exact_n)
  expect_gte(n_required$n, published_n)
})

test_that("2x2 attenuated interaction: matches Sommet et al. (published)", {
  skip_unless_full_validation()
  # Source: Sommet et al. (2023), as above, Table 2, "Fully attenuated"
  #   (knock-out) interaction. Normal-approximation N; see sommet_n().
  mu <- c(0, 0, 0, 0.35) # c(a1_b1, a1_b2, a2_b1, a2_b2), SD = 1
  alpha <- 0.05
  target_power <- 0.80
  published_n <- 1024 # required total N
  exact_n <- 1028 # exact F-test N for the same design (maintainer-checked)
  skip_if_todo(mu, alpha, target_power, published_n)

  means <- matrix(mu, nrow = 2, byrow = TRUE)
  spec <- between_spec(
    means, sd = 1, effect = "interaction", seed = 204, alpha = alpha,
    target_power = target_power
  )
  # (a) Their formula, applied to this spec's effect, gives their N: the
  #     spec matches their design.
  expect_equal(sommet_n(means, sd = 1, alpha = alpha, power = target_power), published_n)
  # (b) powerkit's exact required n is the exact F-test N, which is at least
  #     their normal-approximation N.
  n_required <- engine_n_required(spec)
  expect_equal(n_required$n, exact_n)
  expect_gte(n_required$n, published_n)
})

# 3. Direct-call agreement -----------------------------------------------------------

for (effect in c("main_effect_A", "interaction")) {
  test_that(paste0("2x2 between, ", effect, ": powerkit matches a direct Superpower::ANOVA_power call"), {
    skip_unless_full_validation()
    skip_if_not_installed("Superpower")
    means <- matrix(c(10, 10, 10, 13), nrow = 2, byrow = TRUE)
    spec <- between_spec(means, sd = 6, n = 160, effect = effect, seed = 301, method = "simulation")
    direct <- direct_superpower_simulation(
      "2b*2b", n = 40, means = means, sd = 6, effect = effect,
      alpha = 0.05, nrep = validation_nrep(), seed = 301
    )
    expect_power_agrees(engine_power(spec), direct)
  })
}

# 4. Type I error ------------------------------------------------------------------

test_that("2x2 between: Type I error for the interaction is near alpha when main effects exist", {
  skip_unless_full_validation()
  # Interaction contrast 0 - 0.5 - 0.3 + 0.8 = 0; both main effects non-zero.
  means <- matrix(c(0, 0.5, 0.3, 0.8), nrow = 2, byrow = TRUE)
  spec <- between_spec(means, sd = 1, n = 120, effect = "interaction", seed = 401)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("2x2 between: Type I error for a main effect is near alpha under a crossover", {
  skip_unless_full_validation()
  # Pure crossover: both main effects are 0, the interaction is not.
  means <- matrix(c(0, 0.4, 0.4, 0), nrow = 2, byrow = TRUE)
  spec <- between_spec(means, sd = 1, n = 120, effect = "main_effect_A", seed = 402)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
