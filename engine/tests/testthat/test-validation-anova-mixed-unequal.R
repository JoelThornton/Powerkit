# Validation: mixed ANOVA with unequal groups (one between-participants
# factor A, one within-participants factor B, options > group_ratio).
# Superpower takes equal groups only in a mixed design, so powerkit
# simulates with Spower, analysing each data set with afex::aov_car()
# (docs/decisions.md, 1 November 2026). Build guide section 6:
#   1. analytic agreement. In a 2 x 2 mixed design the F tests of the
#      between factor and of the interaction are exactly two-sample t-tests
#      (F = t^2, the same error df n - 2): the between factor on each
#      person's mean over B, the interaction on each person's difference
#      between B's levels. Their power with unequal groups is pwr's
#      pwr.t2n.test(), with d = the groups' difference in that score over
#      its SD (sd * sqrt((1 + r) / 2) for the mean, sd * sqrt(2 * (1 - r))
#      for the difference). The within factor has no such test with
#      unequal groups; it is covered by 3 and 4.
#   2. published examples: placeholder below, for the maintainer
#   3. agreement with Superpower::ANOVA_exact() when the ratio is 1 : 1
#      (the same simulation, at equal groups), beyond 2 x 2
#   4. Type I error with unequal groups
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

unequal_mixed_spec <- function(means, sd, r, effect, ratio, seed, n, alpha = 0.05) {
  validation_spec(
    design = "factorial_anova",
    template = if (all(dim(means) == 2)) "2x2_mixed" else "mixed",
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
    options = list(group_ratio = as.list(ratio))
  )
}

# pwr.t2n.test() for the between factor or the interaction of a 2 x 2
# mixed design: the t-test the F test equals.
t2n_mixed_power <- function(means, sd, r, effect, ratio, n, alpha = 0.05) {
  groups <- n * ratio / sum(ratio)
  d <- switch(effect,
    main_effect_A = (mean(means[1, ]) - mean(means[2, ])) / (sd * sqrt((1 + r) / 2)),
    interaction = ((means[1, 1] - means[1, 2]) - (means[2, 1] - means[2, 2])) / (sd * sqrt(2 * (1 - r)))
  )
  pwr::pwr.t2n.test(n1 = groups[1], n2 = groups[2], d = d, sig.level = alpha)$power
}

means_2x2 <- matrix(c(0, 0.3, 0.2, 0.9), nrow = 2, byrow = TRUE)

# 1. Analytic agreement ----------------------------------------------------------

for (effect in c("main_effect_A", "interaction")) {
  test_that(paste0("2 x 2 mixed, groups 1 : 2, ", effect, ": matches pwr.t2n.test() on the equivalent t-test (analytic)"), {
    skip_unless_full_validation()
    skip_if_not_installed("pwr")
    skip_if_not_installed("afex")
    spec <- unequal_mixed_spec(means_2x2, sd = 1, r = 0.5, effect = effect, ratio = c(1, 2), seed = 501, n = 90)
    reference <- t2n_mixed_power(means_2x2, sd = 1, r = 0.5, effect = effect, ratio = c(1, 2), n = 90)
    expect_power_near(engine_power(spec), reference)
  })
}

test_that("2 x 2 mixed, groups 3 : 1 and a high correlation, interaction: matches pwr.t2n.test() (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwr")
  skip_if_not_installed("afex")
  means <- matrix(c(10, 12, 10, 10.5), nrow = 2, byrow = TRUE)
  spec <- unequal_mixed_spec(means, sd = 4, r = 0.8, effect = "interaction", ratio = c(3, 1), seed = 502, n = 120)
  reference <- t2n_mixed_power(means, sd = 4, r = 0.8, effect = "interaction", ratio = c(3, 1), n = 120)
  expect_power_near(engine_power(spec), reference)
})

# 2. Published example -------------------------------------------------------------

test_that("mixed ANOVA with unequal groups: matches a published example (published)", {
  skip_unless_full_validation()
  published_power <- "TODO_PUBLISHED_VALUE"
  skip_if(identical(published_power, "TODO_PUBLISHED_VALUE"), "No published example transcribed yet.")
})

# 3. Equal groups through the same simulation --------------------------------------

for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
  test_that(paste0("mixed 2 x 3, ratio 1 : 1, ", effect, ": the simulation matches Superpower::ANOVA_exact (analytic)"), {
    skip_unless_full_validation()
    skip_if_not_installed("Superpower")
    skip_if_not_installed("afex")
    means <- matrix(c(0, 0.3, 0.5, 0, 0.1, 0.2), nrow = 2, byrow = TRUE)
    spec <- unequal_mixed_spec(means, sd = 1, r = 0.5, effect = effect, ratio = c(1, 1), seed = 503, n = 60)
    reference <- direct_superpower_exact("2b*3w", n = 30, means = means, sd = 1, r = 0.5, effect = effect, alpha = 0.05, seed = 503)
    expect_power_near(engine_power(spec), reference$power)
  })
}

# 4. Type I error ------------------------------------------------------------------

test_that("mixed 3 x 3, groups 1 : 1 : 2: Type I error for the interaction is near alpha (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("afex")
  # Parallel lines: both main effects, no interaction.
  means <- matrix(c(0, 0.3, 0.5, 0.4, 0.7, 0.9, 0.2, 0.5, 0.7), nrow = 3, byrow = TRUE)
  spec <- unequal_mixed_spec(means, sd = 1, r = 0.6, effect = "interaction", ratio = c(1, 1, 2), seed = 504, n = 80)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("2 x 2 mixed, groups 1 : 3: Type I error for the between factor is near alpha (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("afex")
  means <- matrix(c(0, 0.5, 0, 0.5), nrow = 2, byrow = TRUE)
  spec <- unequal_mixed_spec(means, sd = 1, r = 0.5, effect = "main_effect_A", ratio = c(1, 3), seed = 505, n = 80)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
