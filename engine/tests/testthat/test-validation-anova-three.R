# Validation: three-factor ANOVA (template factorial_three), each factor
# between or within participants (sphericity assumed with any within
# factor). Backend: Superpower. Build guide section 6:
#   1. analytic agreement with Superpower::ANOVA_exact()
#   2. published examples (placeholders for the maintainer)
#   3. direct-call agreement with Superpower::ANOVA_power()
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `mu` is the cell means in Superpower's order (A slowest, C fastest);
# `types` is "b" or "w" for each of A, B and C; `levels` the number of
# levels of each; `n` the total number of participants; `r` the
# correlation between any two cells a participant is in.
three_spec <- function(types, levels, mu, sd, effect, seed, r = NULL, n = NULL, alpha = 0.05,
                       target_power = NULL, method = NULL) {
  roles <- c("A", "B", "C")
  means <- aperm(array(mu, dim = rev(levels)), 3:1)
  population <- list(
    metric = "raw",
    means = lapply(seq_len(levels[1]), function(i) lapply(seq_len(levels[2]), function(j) as.list(means[i, j, ]))),
    sd = sd
  )
  if (any(types == "w")) population$r <- r
  variables <- lapply(seq_along(roles), function(k) {
    validation_variable(if (types[k] == "w") "within_factor" else "between_factor", roles[k],
                        levels = as.list(paste0(tolower(roles[k]), seq_len(levels[k]))))
  })
  names(variables) <- roles
  validation_spec(
    design = "factorial_anova",
    template = "factorial_three",
    variables = c(variables, list(Y = validation_variable("continuous", "Outcome"))),
    population = population,
    target_test = list(effect = effect, method = "anova_f", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = if (is.null(method)) list() else list(method = method)
  )
}

three_design <- function(types, levels) paste0(levels, types, collapse = "*")
three_groups <- function(types, levels) prod(levels[types == "b"])

# 1. Analytic agreement ----------------------------------------------------------

mixed_mu <- c(80, 70, 60, 81, 71, 61, 80, 70, 60, 84, 77, 70)
for (effect in c("main_effect_A", "interaction_AB", "interaction_BC", "interaction_ABC")) {
  test_that(paste0("2b x 2w x 3w, ", effect, ": power matches Superpower::ANOVA_exact (analytic)"), {
    skip_unless_full_validation()
    types <- c("b", "w", "w")
    levels <- c(2, 2, 3)
    spec <- three_spec(types, levels, mixed_mu, sd = 12, r = 0.5, n = 60, effect = effect, seed = 101)
    direct <- direct_superpower_exact(
      three_design(types, levels), n = 30, means = mixed_mu, sd = 12, r = 0.5,
      effect = effect, alpha = 0.05, seed = 101
    )
    expect_power_near(engine_power(spec), direct$power)
  })
}

test_that("2b x 2b x 2b, interaction_ABC: power matches Superpower::ANOVA_exact (analytic)", {
  skip_unless_full_validation()
  types <- c("b", "b", "b")
  levels <- c(2, 2, 2)
  mu <- c(0, 0, 0, 0, 0, 0, 0, 0.6)
  spec <- three_spec(types, levels, mu, sd = 1, n = 240, effect = "interaction_ABC", seed = 102)
  direct <- direct_superpower_exact(
    three_design(types, levels), n = 30, means = mu, sd = 1,
    effect = "interaction_ABC", alpha = 0.05, seed = 102
  )
  expect_power_near(engine_power(spec), direct$power)
})

# 2. Published examples ------------------------------------------------------------

test_that("three-factor design: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer, for example a three-factor
  #   example in the Superpower book (Caldwell, Lakens, DeBruine, Love &
  #   Aust) or G*Power's "ANOVA: Fixed effects, special, main effects and
  #   interactions" (between-participants factors only). Transcribe the
  #   design (b or w for each factor, and its number of levels), the cell
  #   means in Superpower's order (a1_b1_c1, a1_b1_c2, ...), the SD, the
  #   correlation r if any factor is within, the total number of
  #   participants, alpha, which effect, and the power reported (as a
  #   proportion). If the reported power comes from a simulation, also
  #   transcribe its nsims.
  types <- TODO_PUBLISHED_VALUE # for example c("b", "w", "w")
  levels <- TODO_PUBLISHED_VALUE
  mu <- TODO_PUBLISHED_VALUE
  sd <- TODO_PUBLISHED_VALUE
  r <- TODO_PUBLISHED_VALUE # NULL if every factor is between
  n <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  effect <- TODO_PUBLISHED_VALUE # "main_effect_A", ..., "interaction_ABC"
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # nsims behind the published power, or NULL if exact
  skip_if_todo(types, levels, mu, sd, r, n, alpha, effect, published_power, reference_nrep)

  spec <- three_spec(types, levels, mu, sd = sd, r = r, n = n, effect = effect, seed = 201, alpha = alpha)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct-call agreement -----------------------------------------------------------

test_that("2b x 2w x 3w, interaction_ABC: powerkit matches a direct Superpower::ANOVA_power call", {
  skip_unless_full_validation()
  skip_if_not_installed("Superpower")
  types <- c("b", "w", "w")
  levels <- c(2, 2, 3)
  spec <- three_spec(types, levels, mixed_mu, sd = 12, r = 0.5, n = 60, effect = "interaction_ABC",
                     seed = 301, method = "simulation")
  direct <- direct_superpower_simulation(
    three_design(types, levels), n = 30, means = mixed_mu, sd = 12, r = 0.5, effect = "interaction_ABC",
    alpha = 0.05, nrep = validation_nrep(), seed = 301
  )
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("2b x 2w x 2w: Type I error for the three-way interaction is near alpha (simulation)", {
  skip_unless_full_validation()
  # Every main effect and two-way interaction present, no three-way: the
  # A x B pattern is the same at both levels of C.
  mu <- c(0, 0.5, 0.2, 0.7, 0.3, 0.8, 0.9, 1.4)
  spec <- three_spec(c("b", "w", "w"), c(2, 2, 2), mu, sd = 1, r = 0.5, n = 40,
                     effect = "interaction_ABC", seed = 401, method = "simulation")
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
