# Validation: a 2 x 2 between-participants ANOVA with unequal cells
# (options > cell_ratio). Backend: Superpower's ANOVA_power(), simulated
# (ANOVA_exact() takes equal cells only). Build guide section 6:
#   1. analytic agreement: pwrss's power.f.ancova.shieh() with one
#      covariate that explains nothing (r.squared = 0), the independent
#      reference chosen for unequal cells (docs/decisions.md, 29 October
#      2026). It differs from the ANOVA by one error degree of freedom,
#      which changes power by well under 0.1 percentage point at these n.
#   2. published examples: placeholders below, for the maintainer
#   3. direct-call agreement with Superpower
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

unequal_validation_spec <- function(means, cell_ratio, effect, seed, n = NULL, sd = 1, target_power = NULL, alpha = 0.05) {
  v <- validation_variable
  validation_spec(
    design = "factorial_anova",
    template = "2x2_between",
    variables = list(
      A = v("between_factor", "First factor", levels = list("a1", "a2")),
      B = v("between_factor", "Second factor", levels = list("b1", "b2")),
      Y = v("continuous", "Outcome")
    ),
    population = list(metric = "standardised", means = means, sd = sd),
    target_test = list(effect = effect, method = "anova_f", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power,
    options = list(cell_ratio = cell_ratio)
  )
}

means_unequal <- list(list(0, 0.25), list(0.5, 0.3))
ratio_unequal <- list(list(3, 3), list(1, 1))

# pwrss's Shieh formula for the same cells, with one null covariate.
shieh_power <- function(means, cell_ratio, effect, n, alpha = 0.05) {
  w <- unlist(cell_ratio)
  contrasts <- pwrss::factorial.contrasts(factor.levels = c(2, 2), verbose = 0)$contrast.matrix
  row <- c(main_effect_A = 1, main_effect_B = 2, interaction = 3)[[effect]]
  suppressMessages(pwrss::power.f.ancova.shieh(
    mu.vector = unlist(means), sd.vector = rep(1, 4), n.vector = n * w / sum(w),
    factor.levels = c(2, 2), r.squared = 0, k.covariates = 1,
    contrast.matrix = contrasts[row, , drop = FALSE], alpha = alpha, verbose = 0
  ))$power
}

# 1. Analytic agreement --------------------------------------------------------------

test_that("2 x 2 unequal cells: each effect agrees with pwrss's Shieh formula (analytic)", {
  skip_unless_full_validation()
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    spec <- unequal_validation_spec(means_unequal, ratio_unequal, effect, seed = 2201, n = 240)
    expect_power_near(engine_power(spec), shieh_power(means_unequal, ratio_unequal, effect, 240))
  }
})

# 2. Published example ------------------------------------------------------------

test_that("2 x 2 unequal cells: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for a 2 x 2 ANOVA with unequal cells and records it here).
  means <- TODO_PUBLISHED_VALUE # cell means, one row per level of A
  cell_ratio <- TODO_PUBLISHED_VALUE # relative cell sizes, one row per level of A
  effect <- TODO_PUBLISHED_VALUE # "main_effect_A", "main_effect_B" or "interaction"
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(means, cell_ratio, effect, n, published_power, reference_nrep)
  spec <- unequal_validation_spec(means, cell_ratio, effect, seed = 2202, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct call -------------------------------------------------------------------

test_that("2 x 2 unequal cells: powerkit matches Superpower called directly", {
  skip_unless_full_validation()
  spec <- unequal_validation_spec(means_unequal, ratio_unequal, "interaction", seed = 2203, n = 240)
  design <- suppressMessages(Superpower::ANOVA_design(
    "2b*2b", n = c(90, 90, 30, 30), mu = unlist(means_unequal), sd = 1, plot = FALSE
  ))
  direct <- suppressMessages(Superpower::ANOVA_power(design, nsims = validation_nrep(), seed = 2204, verbose = FALSE))
  reference <- direct$main_results["anova_a:b", "power"] / 100
  expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
})

# 4. Type I error ------------------------------------------------------------------

test_that("2 x 2 unequal cells: Type I error is alpha when the interaction is zero", {
  skip_unless_full_validation()
  spec <- unequal_validation_spec(list(list(0, 0.4), list(0.3, 0.7)), ratio_unequal, "interaction", seed = 2205, n = 240)
  expect_power_near(engine_power(spec), 0.05)
})
